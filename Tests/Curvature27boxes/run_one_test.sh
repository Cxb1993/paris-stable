#!/bin/bash
#set -x


if [ $# -lt 12 ]; then
    echo "missing arguments"
    echo usage $0 ismono UNUSED normup[unused for d=3] cyldir[unused for d=3] UNUSED precision initialisation-over-refinement-level[unused for Vofi] nx UNUSED UNUSED UNUSED d
    exit
fi

ismono=$1
# type=$2

normup=$3
cyldir=$4

radius=0.2
precision=$6
refinement=$7

nx=$8

xc=0.5
yc=0.5
zc=0.5
d=${12}

if [ $ismono == T ]; then
    setmono=mono
    echo "mono"
else
    setmono=parallel
fi

ny=$nx; nz=$ny
npx=3; npy=3; npz=1

if [ $d == 2 ]; then
    type="Curvature2D"
    if [ $cyldir == 1 ];  then
	nx=2
	npx=1
    fi
    if [ $cyldir == 2 ];  then
	ny=2
	npy=1
    fi
    if [ $cyldir == 3 ];  then
	nz=2
	npz=1
	if [ -f grid_template.gp ]; then
	    sed s/XC1/$xc/g grid_template.gp | sed s/XC2/$yc/g  | sed s/RADIUS/$radius/g  > grid.gp
	fi
    fi
    if [ $cyldir -gt 3 ]; then
	echo "incorrect cyldir"
	exit
    fi
else
    type="Curvature_test"
    cyldir=0
fi

if [ $setmono == mono ]; then
    npy=1; npz=1; npx=1
fi

/bin/rm -fr out input

ndepth=`head -60  ../../surface_tension.f90 |  awk -F '=' ' /NDEPTH/ {print $2}' | tr -d ' '`
dim=$d'D'

let npstart=$npx*$npy*$npz

sed s/NXTEMP/$nx/g testinput.template | sed s/NPXTEMP/$npx/g | sed s/NZTEMP/$nz/g  | sed s/NPZTEMP/$npz/g  | sed s/NYTEMP/$ny/g | sed s/NPYTEMP/$npy/g > testinput
sed s/RADIUSTEMP/$radius/g testinput | sed s/XCTEMP/$xc/g  | sed s/YCTEMP/$yc/g  | sed s/ZCTEMP/$zc/g > testinput-$dim-$nx-$radius 
ln -s testinput-$dim-$nx-$radius input

sed s/REFINEMENTTEMP/$refinement/g inputvof.template | sed s/TYPETEMP/$type/g  | sed s/CYLDIRTEMP/$cyldir/g | sed s/NORMUPTEMP/$normup/g > inputvof 

mpirun -np $npstart paris > tmpout 2>&1

success=`tail -1 tmpout | grep -c "Paris exits succesfully"`
if [ $success -ne 1 ]; then
    exit 1
fi
if [ -d out ]; then
    cd out
    cat curvature-*.txt >> curvature.txt
    cat reference-*.txt >> reference.txt
    echo `awk -v nx=$nx -v radius=$radius 'BEGIN {print nx * radius }'`  `pariscompare curvature.txt reference.txt 0.1 1 2 `  >> ../paris-$nx-$ndepth.tmp
    cd ..
    awk -v nx=$nx  -v radius=$radius '{print nx * radius, $1, $2, $3 }' mcount.tmp >> mcount_one_test-$nx-$ndepth.tmp
else
    RED="\\033[1;31m"
    NORMAL="\\033[0m"
    echo -e "$RED" "FAIL: directory 'out' not found."  "$NORMAL"
fi

if [ $setmono == mono ] && [ $cyldir == 3 ] && [ $nx -le 16 ] && [ d==2 ]; then
	gnuplot <<EOF
call "../grid.gp"
EOF
fi
exit 0

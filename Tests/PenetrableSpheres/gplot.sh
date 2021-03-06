#! /bin/bash
#set -x

if [ $# -lt 1 ] 
then
tail=`ls out/UV-* | awk 'BEGIN {FS="-"} {print $3}' | tail -1`
else
tail=$1.txt
fi

if  [ $# -lt 2 ] 
then
  rm -f 2plot.txt
  cat  out/UV-00000-$tail >> 2plot.txt   
  cat  out/UV-00001-$tail >> 2plot.txt   
  cat  out/UV-00002-$tail >> 2plot.txt   
  cat  out/UV-00003-$tail >> 2plot.txt   
  cat  out/UV-00004-$tail >> 2plot.txt   
  cat  out/UV-00005-$tail >> 2plot.txt   
  cat  out/UV-00006-$tail >> 2plot.txt   
  cat  out/UV-00007-$tail >> 2plot.txt   
else
    cp out/UV-0000$2-$tail 2plot.txt
fi
gnuplot <<EOF
set size square
set nolabel
set xrange[0:1]
set yrange[0:1]
plot "2plot.txt" w vec notitle
EOF

rm -f 2plot.txt

!=================================================================================================
!=================================================================================================
! Paris-0.1
! Extended from Code: FTC3D2011 (Front Tracking Code for 3D simulations)
! and Surfer. 
!
! Authors:
! 
!   Sadegh Dabiri (sdabiri@gmail.com), Gretar Tryggvason
!   Stephane Zaleski (zaleski@dalembert.upmc.fr) and Yue Ling (ling.stanley@gmail.com)
! 
! This program is free software; you can redistribute it and/or
! modify it under the terms of the GNU General Public License as
! published by the Free Software Foundation; either version 2 of the
! License, or (at your option) any later version.
!
! This program is distributed in the hope that it will be useful,
! but WITHOUT ANY WARRANTY; without even the implied warranty of
! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	See the GNU
! General Public License for more details.
!
! You should have received a copy of the GNU General Public License
! along with this program; if not, write to the Free Software
! Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
! 02111-1307, USA.  
!=================================================================================================
! module_surface_tension: Contains definition of variables for surface tension from
!  Volume of Fluid interface tracking.
!-------------------------------------------------------------------------------------------------
module module_st_testing
  use module_grid
  use module_BC
  use module_IO
  use module_tmpvar
  use module_2phase
  use module_VOF
  use module_surface_tension
  implicit none
  integer :: testint
  integer :: levarnames, lemeshnames, padd
contains
  subroutine test_VOF_HF()
    implicit none
    integer :: calc_imax
    if(calc_imax(vof_flag)/=2) then
       write(*,*) calc_imax(vof_flag), "expecting maximum flag = 2"
       call pariserror("bad flags")
    endif
    call get_all_heights(0)
    if(test_heights) then
       call output_heights()
    else if(test_curvature .or. test_curvature_2D) then
       method_count=0
       call output_curvature()
    end if
    if(test_curvature_2D.and.nx<=16.and.ny<=16.and.nz<=2) then
       call plot_curvature()
    end if
  end subroutine test_VOF_HF

  subroutine output_heights()
    implicit none
    integer i,j,k,d,index, direction
    real(8) h, th, ka, kb
    integer :: normalsign

    if(normal_up) then
       normalsign=1
    else
       normalsign=-1
    endif

    ! kb in processor below in theory
    kb = nz/2 + 2  ! +2 because of ghost layers
    ! ka in processor above
    ka = nz/2 + 3 
    j = ny/2 + 2  ! +2 because of ghost layers

    ! First pass: search for height in processor below

    k = kb
    if(j<js.or.j>je) return
    if(.not.(k<ks.or.k>ke)) then

       OPEN(UNIT=89,FILE=TRIM(out_path)//'/heightb-'//TRIM(int2text(rank,padding))//'.txt')
       OPEN(UNIT=90,FILE=TRIM(out_path)//'/reference-'//TRIM(int2text(rank,padding))//'.txt')

       if(cylinder_dir==2) then
          ! search in z direction
          direction = 3
          index = 2*(direction-1) + 1 + (-normalsign+1)/2
          do i=is,ie
             th = normalsign*wave2ls(x(i),y(j),z(k),cylinder_dir)/dx(nx/2+2)
             write(90,100) x(i),th
             if (height(i,j,k,index).lt.1d6) then
                h = height(i,j,k,index)
             else
                ! search for height
                d=0
                h = 2d6
                do while(h.gt.1d6.and.k+d<ke.and.k-d>ks)
                   d = d + 1
                   if (height(i,j,k+d,index).lt.1d6) then
                      h = height(i,j,k+d,index) + d
                      height(i,j,k,index) = h 
                   else if (height(i,j,k-d,index).lt.1d6) then
                      h = height(i,j,k-d,index) - d
                      height(i,j,k,index) = h 
                   endif
                enddo
             endif
             if(height(i,j,k,index).gt.1d6) then
                write(89,101) x(i),' -'
             else
                write(89,100) x(i), h  
             endif
          enddo
       else if(cylinder_dir==3) then
          ! search in y direction
          direction=2
          index = 2*(direction-1) + 1 + (-normalsign+1)/2
          do i=is,ie
             th = normalsign*wave2ls(x(i),y(j),z(k),cylinder_dir)/dx(nx/2+2)
             write(90,100) x(i),th
             if (height(i,j,k,index).lt.1d6) then
                h = height(i,j,k,index)
             else
                ! search for height
                d=0
                h = 2d6
                do while(h.gt.1d6.and.j+d<je.and.j-d>js)
                   d = d + 1
                   if (height(i,j+d,k,index).lt.1d6) then
                      h = height(i,j+d,k,index) + d
                      height(i,j,k,index) = h 
                   else if (height(i,j-d,k,index).lt.1d6) then
                      h = height(i,j-d,k,index) - d
                      height(i,j,k,index) = h 
                   endif
                enddo
             endif
             if(height(i,j,k,index).gt.1d6) then
                write(89,101) x(i),' -'
             else
                write(89,100) x(i), h 
             endif
          enddo
       endif
    endif
    close(unit=89)
    ! second pass

    k = ka

    if(.not.(k<ks.or.k>ke)) then

       OPEN(UNIT=89,FILE=TRIM(out_path)//'/heighta-'//TRIM(int2text(rank,padding))//'.txt')
       !     OPEN(UNIT=90,FILE=TRIM(out_path)//'/reference-'//TRIM(int2text(rank,padding))//'.txt')

       if(cylinder_dir==2) then
          ! search in z direction
          direction = 3
          index = 2*(direction-1) + 1 + (-normalsign+1)/2
          do i=is,ie
             th = normalsign*wave2ls(x(i),y(j),z(k),cylinder_dir)/dx(nx/2+2)
             !           write(90,100) x(i),th
             if (height(i,j,k,index).lt.1d6) then
                h = height(i,j,k,index)
             else
                ! search for height
                d=0
                h = 2d6
                do while(h.gt.1d6.and.k+d<ke.and.k-d>ks)
                   d = d + 1
                   if (height(i,j,k+d,index).lt.1d6) then
                      h = height(i,j,k+d,index) + d
                      height(i,j,k,index) = h 
                   else if (height(i,j,k-d,index).lt.1d6) then
                      h = height(i,j,k-d,index) - d
                      height(i,j,k,index) = h 
                   endif
                enddo
             endif
             if(height(i,j,k,index).gt.1d6) then
                write(89,101) x(i),' -'
             else
                write(89,100) x(i), h + ka - kb
             endif
          enddo
       else if(cylinder_dir==3) then
          ! search in y direction
          direction=2
          index = 2*(direction-1) + 1 + (-normalsign+1)/2
          do i=is,ie
             th = normalsign*wave2ls(x(i),y(j),z(k),cylinder_dir)/dx(nx/2+2)
             !           write(90,100) x(i),th
             if (height(i,j,k,index).lt.1d6) then
                h = height(i,j,k,index)
             else
                ! search for height
                d=0
                h = 2d6
                do while(h.gt.1d6.and.j+d<je.and.j-d>js)
                   d = d + 1
                   if (height(i,j+d,k,index).lt.1d6) then
                      h = height(i,j+d,k,index) + d
                      height(i,j,k,index) = h 
                   else if (height(i,j-d,k,index).lt.1d6) then
                      h = height(i,j-d,k,index) - d
                      height(i,j,k,index) = h 
                   endif
                enddo
             endif
             if(height(i,j,k,index).gt.1d6) then
                write(89,101) x(i),' -'
             else
                write(89,100) x(i), h + ka - kb
             endif
          enddo
       endif
    endif

100 format(2(f24.16))
101 format(f24.16,A2)
    close(89)
    close(90)
  end subroutine output_heights
  !==================================================================================================
  subroutine output_curvature()
    implicit none      
    include "mpif.h"
    integer :: i,j,k! ,l,m,n
    integer :: ib 
    real(8) :: kappa,a(6)
    real(8) :: angle 
    real(8) :: kappamin
    real(8) :: kappamax
    real(8) :: kappa_exact
    real(8) :: L2_err_K, err_K
    real(8) :: S2_err_K
    real(8) :: Lm_err_K
    integer :: sumCount,nfound,nindepend
    integer :: nposit, ntests

    OPEN(UNIT=89,FILE=TRIM(out_path)//'/curvature-'//TRIM(int2text(rank,padding))//'.txt')
    OPEN(UNIT=90,FILE=TRIM(out_path)//'/reference-'//TRIM(int2text(rank,padding))//'.txt')
    OPEN(UNIT=91,FILE=TRIM(out_path)//'/bigerror-'//TRIM(int2text(rank,padding))//'.txt')
    OPEN(UNIT=92,FILE=TRIM(out_path)//'/debug-'//TRIM(int2text(rank,padding))//'.txt')
    ib = 1
    kappamin = 1d20
    kappamax = -1d20
    sumCount = 0
    S2_err_K=0.d0
    Lm_err_K=0.d0
    method_count=0
    ntests=0
    if ( test_curvature ) then 
       kappa_exact = - 2.d0/rad(ib)
       do i=is,ie; do j=js,je; do k=ks,ke
          ! find curvature only for cut cells
          if (vof_flag(i,j,k) == 2 ) then 
             ntests=ntests+1
             call get_curvature(i,j,k,kappa,nfound,nposit,a,.false.)
             !               if(kappa > 0.5e20.and.rank==0) then
             !                  print *, i,j,k,kappa,nfound,nposit,a
             !                  stop
             !               endif
             if(nfound > 0) then
                method_count(1) = method_count(1) + 1  ! nine heights
             else if( -nfound < 50) then 
                method_count(2) = method_count(2) + 1  ! mixed heights
             else if (-nfound > 50) then
                method_count(3) = method_count(3) + 1  ! centroids
             else
                call pariserror("OC: unknown method_count") 
             endif
             kappa = kappa*dble(Nx) ! Nx = L/deltax
             kappamax = max(ABS(kappa),kappamax)
             kappamin = min(ABS(kappa),kappamin)
             angle = atan2(y(j)-yc(ib),x(i)-xc(ib))/PI*180.d0
             write(89,'(2(E15.8,1X))') angle,kappa
             write(92,'(2(E15.8,1X),I4)') angle,kappa,nfound
             write(90,*) angle,kappa_exact
             err_K = ABS(kappa-kappa_exact)/kappa_exact
             if ( err_K > 0.1d0 ) &
                  write(91,'(3(I3,1X),2(E15.8,1X),I4)') i,j,k,kappa,kappa_exact,nfound
          end if ! cvof(i,j,k)
       end do; end do; end do
    else if ( test_curvature_2D) then 
       k = (Nz+4)/2
       kappa_exact = - 1.d0/rad(ib)
       do i=is,ie; do j=js,je
          if (vof_flag(i,j,k) == 2) then 
             call get_curvature(i,j,k,kappa,nfound,nposit,a,.false.)
             if(nfound > 0) then
                method_count(1) = method_count(1) + 1  ! nine heights
             else if( -nfound < 50) then 
                method_count(2) = method_count(2) + 1  ! mixed heights
             else if (-nfound > 50) then
                method_count(3) = method_count(3) + 1  ! centroids
             endif
             ! This stops the code in case kappa becomes NaN.
             if(kappa.ne.kappa) call pariserror("OC: Invalid Curvature")  
             if(nfound==-1.or.abs(kappa)<EPS_GEOM) then
                write(6,*) "i,j,k,nfound,nindepend,kappa ",i,j,k,nfound,nindepend,kappa
                call pariserror("OC: curvature not found")
             else
                kappa = kappa*dble(Nx)  ! Nx = L/deltax
                kappamax = max(ABS(kappa),kappamax)
                kappamin = min(ABS(kappa),kappamin)
                angle = atan2(y(j)-yc(ib),x(i)-xc(ib))/PI*180.d0
                write(89,*) angle,kappa
                write(90,*) angle,kappa_exact
                err_K    = ABS(kappa-kappa_exact)/kappa_exact
                S2_err_K    = S2_err_K  + err_K**2
                Lm_err_K    = MAX(Lm_err_K,   err_K) 
                sumCount = sumCount + 1
             endif ! valid curvature
          end if ! cvof(i,j,k)
       end do; end do

       L2_err_K    = sqrt(S2_err_K/dble(sumCount))
       write(*,*) 'L2 Norm:'
       write(*,'(I5,I5,1X,(E15.8,1X))') Nx,rank,L2_err_K
       write(*,*) 'Linfty Norm:'
       write(*,'(I5,I5,1X,(E15.8,1X))') Nx,rank,Lm_err_K
    end if ! test_curvature
    if(ntests>0) then
       write(*,*) 'rank,max, min, and exact ABS(kappa)', rank, kappamax, kappamin,kappa_exact
       write(*,*) '     max relative error', MAX(ABS(kappamax-kappa_exact), ABS(kappamin-kappa_exact))/kappa_exact
    else
       print *, 'rank = ', rank, 'ntests =', ntests
    endif
    CLOSE(89)
    CLOSE(90)
    CLOSE(91)
    CLOSE(92)
    call print_method() 
  contains
    subroutine print_method()
      integer :: total=0
      integer :: n
      real(8) :: fraction(3)
      do n=1,3
         total = method_count(n) + total
      enddo
      do n=1,3
         fraction(n) = float(method_count(n)) / float(total)   
      enddo

      OPEN(UNIT=89,FILE='mcount.tmp')
      write(89,*) fraction
      close(89)
    end subroutine print_method
  end subroutine output_curvature
  !=========================================================================================================
  !
  !  Testing section
  ! 
  !=========================================================================================================
  subroutine plot_curvature()
    implicit none
    integer :: i,j,k,iem,jem,n
    real(8) :: centroid(3),x1,y1
    real(8), allocatable :: pc(:,:,:)
    real(8) :: centroid_scaled(2), deltax
    k = (Nz+4)/2
    deltax=dx(nx/2)

    allocate(pc(imin:imax,jmin:jmax,3))
    if(rank==0.and.cylinder_dir==3) then
       OPEN(UNIT=79,FILE=TRIM(out_path)//'/grid.txt')
       OPEN(UNIT=80,FILE=TRIM(out_path)//'/segments.txt')
       OPEN(UNIT=81,FILE=TRIM(out_path)//'/points.txt')
       OPEN(UNIT=82,FILE=TRIM(out_path)//'/parabola.txt')
       jem = je - 2
       iem = ie - 2
       do i=js,jem
          write(79,'(4(E15.8,1X))') xh(is),yh(i),xh(iem)-xh(is),0.d0
       enddo
       do i=is,iem
          write(79,'(4(E15.8,1X))') xh(i),yh(js),0.,yh(jem)-yh(js)
       enddo
       do i=is,ie; do j=js,je
          if(vof_flag(i,j,k).eq.2) then
             call PlotCutAreaCentroid(i,j,k,centroid,x1,y1)
             do n=1,2
                pc(i,j,n) = centroid(n)
             enddo
             write(80,'(2(E15.8,1X))') x1,y1
             do n=1,2 
                centroid_scaled(n) = deltax*centroid(n) 
             enddo
             centroid_scaled(1) = centroid_scaled(1) + x(i)
             centroid_scaled(2) = centroid_scaled(2) + y(j)
             write(81,'(2(E15.8,1X))') centroid_scaled(1),centroid_scaled(2) 
          endif
       enddo; enddo
       CLOSE(79)
       CLOSE(80)
       CLOSE(81)
       CLOSE(82)
    endif
  end subroutine plot_curvature

  subroutine PlotCutAreaCentroid(i,j,k,centroid,x1,y1)
    implicit none
    integer, intent(in)  :: i,j,k
    real(8), intent(out) :: centroid(3),x1,y1
    integer :: l,m,n
    real(8) :: nr(3),dmx,dmy, al3dnew
    real(8) :: stencil3x3(-1:1,-1:1,-1:1)

    if(recomputenormals) then
       do l=-1,1; do m=-1,1; do n=-1,1
          stencil3x3(l,m,n) = cvof(i+l,j+m,k+n)
       enddo;enddo;enddo
       call youngs(stencil3x3,nr)
    else
       nr(1) = n1(i,j,k)      
       nr(2) = n2(i,j,k)      
       nr(3) = n3(i,j,k)
    endif
    dmx = nr(1)
    dmy = nr(2)
    if(abs(nr(3)).gt.EPS_GEOM) call pariserror("PCAC: invalid dmz.")
    call cent3D(nr,cvof(i,j,k),centroid)
    centroid = centroid - 0.5d0
    x1 = - al3dnew(nr,cvof(i,j,k))/dmx
    y1 = - al3dnew(nr,cvof(i,j,k))/dmy
    ! shift to cell center coordinates
    x1 = x1 - 0.5d0; y1 = y1 - 0.5d0
    ! shift
    x1 = x1 + x(i)
    y1 = y1 + y(j)
    ! some stuff is missing here
  end subroutine PlotCutAreaCentroid

  subroutine h_of_KHI2D(timestep,output_time)
    use module_surface_tension
    use module_flow
    implicit none
    include 'mpif.h'
    integer :: i,j,k,timestep
    real(8) :: h, a1_coef, b1_coef, output_time, local_KE, global_KE, diff_vol
    real(8), dimension(:), allocatable :: local_h, global_h
    integer :: ierr
    character*128 :: file_name, file_name1, file_name2, file_name3
    LOGICAL :: Found
    LOGICAL, SAVE :: first_access = .true.
    LOGICAL, SAVE :: first_open = .true.
    logical :: letsdebug = .false.

    IF(first_access) then 
       allocate(local_h(nx), global_h(nx))
    ENDIF
    local_KE=0d0
    global_KE=0d0
    local_h=0d0
    global_h=0d0
    file_name = '/h_file_'
    file_name1 = '/test_file_vof'
    file_name2 = '/ab_coef_file_'
    file_name3 = '/KE_file'


    DO i=is,ie
       !Debug section*******************************************************************************
       IF((rank==1.or.rank==2.or.rank==5.or.rank==6).and.letsdebug) THEN
          OPEN(UNIT=86,FILE=TRIM(out_path)//'/'//TRIM(file_name1)// &
               TRIM(int2text(rank,padding))//'-'//TRIM(int2text(timestep,padding))//'.txt', POSITION='append')
          write(86,19) cvof(i,65,3), cvof(i,66,3), cvof(i,67,3), cvof(i,68,3) 
19        format(E14.6,E14.6,E14.6,E14.6)       
          CLOSE(86)
       ENDIF
       !**********************************************************************************************
       h=0d0
       DO k=ks,ke

          IF(height(i,js-1,k,4)<1d6) THEN
             found = .true.
          ELSE
             found = .false.
          ENDIF

          DO j=js,je
             diff_vol = dx(i)*dy(j)*dz(k)
             local_KE = local_KE + diff_vol*(0.5d0*(v(i,j,k)+v(i,j+1,k)))**2
             IF((found.eqv..false.).and.(height(i,j,k,4)<1d6)) THEN 
                !h = h + Y(j)*(Ny/yLength) + height(i,j,k,4) 
                h = h + Y(j) + height(i,j,k,4)*(yLength/Ny) 
                found = .true.
             ENDIF
          ENDDO
       ENDDO
       local_h(i-Ng) = h 
    ENDDO

    call MPI_ALLREDUCE(local_h, global_h, nx, MPI_DOUBLE_PRECISION, MPI_MAX, MPI_Comm_Cart, ierr)
    call MPI_ALLREDUCE(local_KE, global_KE,1, MPI_DOUBLE_PRECISION, MPI_MAX, MPI_Comm_Cart, ierr)

    global_h = global_h / REAL(Nz) - yLength/2
    global_KE = global_KE / (xLength*yLength*zLength)
    if (rank==0) then

       a1_coef=0d0
       b1_coef=0d0
       DO i=1,nx
          a1_coef = a1_coef + global_h(i)*COS(2*PI*(X(i))/xLength)*xLength/REAL(nx)
          b1_coef = b1_coef + global_h(i)*SIN(2*PI*(X(i))/xLength)*xLength/REAL(nx)
       ENDDO
       a1_coef = 2*a1_coef/xLength
       b1_coef = 2*b1_coef/xLength

       OPEN(UNIT=87,FILE=TRIM(out_path)//TRIM(file_name)//TRIM(int2text(timestep,padding))//'.txt')
       !write(*,*) 'entering print succesfull ', rank
       DO i=1,nx
          write(87,17) (REAL(i)-0.5)/REAL(nx), global_h(i)
17        format(E14.6,E14.6)
       ENDDO
       CLOSE(87)

       if(first_open) then
          ! Write ab coefficients file
          OPEN(UNIT=88,FILE=TRIM(out_path)//TRIM(file_name2)//'.txt')
          write(88,18) output_time, a1_coef, b1_coef, SQRT(a1_coef**2 + b1_coef**2)
          CLOSE(88)
          ! Write v**2 file
          OPEN(UNIT=89,FILE=TRIM(out_path)//TRIM(file_name3)//'.txt')
          write(89,17) output_time, global_KE
          CLOSE(89)
          first_open = .false.
       else
          ! Write ab coefficients file
          OPEN(UNIT=88,FILE=TRIM(out_path)//TRIM(file_name2)//'.txt',POSITION='append')
          write(88,18) output_time, a1_coef, b1_coef, SQRT(a1_coef**2 + b1_coef**2)
          CLOSE(88)
          ! Write v**2 file
          OPEN(UNIT=89,FILE=TRIM(out_path)//TRIM(file_name3)//'.txt',POSITION='append')
          write(89,17) output_time, global_KE
          CLOSE(89)
       endif
18     format(E14.6,E14.6,E14.6,E14.6)
       !write(*,*) 'exiting print succesfull ', rank
    endif
  end subroutine h_of_KHI2D
  ! Output zone=======================================================================================
  ! General subroutine
  subroutine output_ALL(nf,i1,i2,j1,j2,k1,k2,timestep)
    implicit none
    integer :: nf,i1,i2,j1,j2,k1,k2,timestep
    if(output_format==4) call output4(nf,i1,i2,j1,j2,k1,k2)
    if(output_format==5) call output5(timestep)
  end subroutine output_ALL
  ! Visit file generation subroutine
  subroutine append_General_visit_file(rootname)
    implicit none
    character(*) :: rootname
    character(len=30), save :: file_name
    integer prank
    logical, save :: opened=.false.

    file_name='fields.visit'

    if(rank.ne.0) call pariserror('rank.ne.0 in append_VOF')
    if(opened .eqv. .false.) then
       OPEN(UNIT=88,FILE=TRIM(file_name))
       write(88,10) nPdomain
10     format('!NBLOCKS ',I4)
       opened=.true.
    else
       OPEN(UNIT=88,FILE=TRIM(file_name),position='append')
    endif
    do prank=0,NpDomain-1
       write(88,11) rootname//TRIM(int2text(prank,padding))//'.vtk'
11     format(A)
    enddo
    close(88)
  end subroutine  append_General_visit_file
  !Output subroutine
  subroutine output4(nf,i1,i2,j1,j2,k1,k2)
    use module_flow
    use module_grid
    use module_surface_tension
    use module_IO
    implicit none
    integer ::nf,i1,i2,j1,j2,k1,k2,i,j,k, itype=5
    !  logical, save :: first_time=.true.
    character(len=30) :: rootname,filename
    rootname=TRIM(out_path)//'/VTK/fields'//TRIM(int2text(nf,padding))//'-'


    if(rank==0) call append_General_visit_file(TRIM(rootname))

    OPEN(UNIT=8,FILE=TRIM(rootname)//TRIM(int2text(rank,padding))//'.vtk')
    write(8,10)
    write(8,11)time
    write(8,12)
    write(8,13)
    write(8,14)i2-i1+1,j2-j1+1,k2-k1+1
    write(8,15) x(i1),y(j1),z(k1)
    write(8,16) x(i1+1)-x(i1),y(j1+1)-y(j1),z(k1+1)-z(k1)
10  format('# vtk DataFile Version 3.0')
11  format('grid, time ',F16.8)
12  format('ASCII')
13  format('DATASET STRUCTURED_POINTS')
14  format('DIMENSIONS ',I5,I5,I5)
15  format('ORIGIN ',F16.8,F16.8,F16.8)
16  format('SPACING ',F16.8,F16.8,F16.8)

    write(8,19)(i2-i1+1)*(j2-j1+1)*(k2-k1+1)

19  format('POINT_DATA',I17)
17  format('SCALARS ',A20,' float 1')
20  format('VECTORS velocity double')
18  format('LOOKUP_TABLE default')

    if(output_fields(1)) then
       write(8,20)
       do k=k1,k2; do j=j1,j2; do i=i1,i2;
          if (itype .eq. 1)write(8,210)rho(i,j,k)
          if (itype .eq. 5)write(8,310)0.5*(u(i,j,k)+u(i-1,j,k)), &
               0.5*(v(i,j,k)+v(i,j-1,k)),0.5*(w(i,j,k)+w(i,j,k-1))
       enddo; enddo; enddo
    endif

    !write(8,19)(i2-i1+1)*(j2-j1+1)*(k2-k1+1)

    ! Writing CVOF values
    if(output_fields(2)) then
       write(8,17) 'VOF'
       write(8,18)
       do k=k1,k2; do j=j1,j2; do i=i1,i2;
          write(8,210) cvof(i,j,k)
       enddo; enddo; enddo
    endif

    ! Writing Height function values
    if(output_fields(3)) then
       write(8,17) 'Heightx+'
       write(8,18)

       do k=k1,k2; do j=j1,j2; do i=i1,i2;
          write(8,210) height(i,j,k,1) 
       enddo; enddo; enddo

       write(8,17) 'Heightx-'
       write(8,18)

       do k=k1,k2; do j=j1,j2; do i=i1,i2;
          write(8,210) height(i,j,k,2) 
       enddo; enddo; enddo

       write(8,17) 'Heighty+'
       write(8,18)

       do k=k1,k2; do j=j1,j2; do i=i1,i2;
          write(8,210) height(i,j,k,3) 
       enddo; enddo; enddo

       write(8,17) 'Heighty-'
       write(8,18)

       do k=k1,k2; do j=j1,j2; do i=i1,i2;
          write(8,210) height(i,j,k,4) 
       enddo; enddo; enddo

       write(8,17) 'Heightz+'
       write(8,18)

       do k=k1,k2; do j=j1,j2; do i=i1,i2;
          write(8,210) height(i,j,k,5) 
       enddo; enddo; enddo

       write(8,17) 'Heightz-'
       write(8,18)

       do k=k1,k2; do j=j1,j2; do i=i1,i2;
          write(8,210) height(i,j,k,6) 
       enddo; enddo; enddo
    endif
    
    ! Writing pressure values
    if(output_fields(4)) then
       write(8,17) 'P'
       write(8,18)
       do k=k1,k2; do j=j1,j2; do i=i1,i2;
          write(8,210) p(i,j,k)
       enddo; enddo; enddo
    endif
    
210 format(e14.5)
310 format(e14.5,e14.5,e14.5)

    close(8)

    ! TEMPORARY
    if ( zip_data ) then 
       filename = TRIM(rootname)//TRIM(int2text(rank,padding))//'.vtk'
       call system('gzip '//trim(filename))
    end if ! zip_data
    ! END TEMPORARY 
  end subroutine output4

  subroutine output5(timestep)
    use module_flow
    use module_grid
    use module_surface_tension
    use module_IO
    implicit none
    include 'mpif.h'
#ifdef HAVE_SILO
    include 'silo_f9x.inc'
#endif	
    integer :: timestep	
#ifdef HAVE_SILO
    ! Silo Util Variables

    integer::narg,cptArg !#of arg & counter of arg
    character(len=70)::name !Arg name
    character(len=70)::path, file_name
    !character(len=40)::
    real(4), dimension(:,:,:), allocatable :: matrix_small
    real(8), dimension(:), allocatable :: x_axis, y_axis, z_axis
    integer :: iee, ise, jee, jse, kee, kse
    integer :: i, j, k, ierr2, dbfile, optlist, lfile_name
    integer, dimension(3) :: dims_mesh, dims_cpu, dims_vof, ghostlow, ghosttop
    real(8) :: deltaX
    integer, save :: index = 0

    padd = padding
    path = 'out/VTK'

    !Debugging messages
    !Write(*,*) 'Starting job in rank: ', rank

    ! Setting string lengths
    levarnames = 25 + 2*padd
    lemeshnames = 24 + 2*padd

    ! Setting number of processors for each spatial dimension
    dims_cpu(1) = nPx; dims_cpu(2) = nPy; dims_cpu(3) = nPz;

    ! Voxel size of structured regular mesh
    deltaX = xLength/REAL(Nx)

    ! Setting limits of the domain to be output
    ise=imin; iee=imax; if(coords(1)==0) ise=is; if(coords(1)==nPx-1) iee=ie;
    jse=jmin; jee=jmax; if(coords(2)==0) jse=js; if(coords(2)==nPy-1) jee=je;
    kse=kmin; kee=kmax; if(coords(3)==0) kse=ks; if(coords(3)==nPz-1) kee=ke;

    ! Debugging messages
    !WRITE(*,*) 'is In rank ', rank, is, ie, js, je, ks, ke
    !WRITE(*,*) 'Maximim In rank ', rank, imin, imax, jmin, jmax, kmin, kmax
    !WRITE(*,*) 'coords in rank ', rank, coords(1), coords(2), coords(3)
    !WRITE(*,*) 'ise In rank ', rank, ise, iee, jse, jee, kse, kee

    ! Allocating arrays
    allocate(matrix_small(imin:imax,jmin:jmax,kmin:kmax))
    allocate(x_axis(ise:iee+1),y_axis(jse:jee+1),z_axis(kse:kee+1))

    ! Defining mesh axys
    do i=ise,iee+1
       x_axis(i)= REAL(i-3)*deltaX !+ REAL(coords(1))*(xLength/REAL(nPx))
    enddo
    !Write(*,*) 'In rank', rank, ' x limits ', x_axis
    do j=jse,jee+1
       y_axis(j)= REAL(j-3)*deltaX !+ coords(2)*yLength/nPy
    enddo
    do k=kse,kee+1
       z_axis(k)= REAL(k-3)*deltaX !+ coords(3)*zLength/nPz
    enddo

    ! Defining dimensions of the mesh
    dims_mesh(1) = iee - ise + 2
    dims_mesh(2) = jee - jse + 2
    dims_mesh(3) = kee - kse + 2

    ! Defining dimensions of the cvof data
    dims_vof(1) = iee - ise + 1
    dims_vof(2) = jee - jse + 1
    dims_vof(3) = kee - kse + 1

    ! Debugging messages
    !WRITE(*,*) 'Limits In rank ', rank, iee, ise, jee, jse, kee, kse

    ! Defining ghost zones
    ghostlow(1) = is-ise
    ghostlow(2) = js-jse
    ghostlow(3) = ks-kse
    ghosttop(1) = iee-ie
    ghosttop(2) = jee-je
    ghosttop(3) = kee-ke

    ! Writing multi mesh file
    if (rank == 0) call write_master(TRIM(path)//'/fbasic',index, time, timestep)

    ! Setting *.silo file path
    file_name = TRIM(path)//'/fbasic'//i2t(index,padd)//'-'//i2t(rank,padd)//".silo"
    ! Setting *.silo file path length
    lfile_name = 20 + 2*padd

    !Debugging message
    !write(*,*) 'Path for silo is ', file_name

    ! Generating .silo file
    ierr2 = dbcreate(TRIM(file_name), lfile_name, DB_CLOBBER, DB_LOCAL, &
         'Comment about the data', 22, DB_PDB, dbfile)

    ! Setting ghost layers
    ierr2 = dbmkoptlist(2, optlist)
    ierr2 = dbaddiopt(optlist, DBOPT_HI_OFFSET, ghosttop)
    ierr2 = dbaddiopt(optlist, DBOPT_LO_OFFSET, ghostlow)


    ! Appending mesh to *.silo file
    ierr2 = dbputqm (dbfile, 'srm', 18, "x", 1, &
         "y", 1, "z", 1, x_axis, y_axis, z_axis, dims_mesh, 3, &
         DB_DOUBLE, DB_COLLINEAR, optlist, ierr2)
    matrix_small = REAL(cvof)

    ! Appending cvof variable to *.silo file  
    ierr2 = dbputqv1 (dbfile, 'cvof', 4, 'srm', 3, &
         matrix_small(ise:iee,jse:jee,kse:kee), dims_vof, &
         3, DB_F77NULL, 0, DB_FLOAT, DB_ZONECENT, DB_F77NULL, ierr2) 
         
    do k=kmin,kmax; do j=jmin,jmax; do i=imin,imax;
       matrix_small(i,j,k)=0.5*(u(i,j,k)+u(i-1,j,k))
    enddo; enddo; enddo
        
    ! Appending u_component variable to *.silo file  
    ierr2 = dbputqv1 (dbfile, 'uvel', 4, 'srm', 3, &
         matrix_small(ise:iee,jse:jee,kse:kee), dims_vof, &
         3, DB_F77NULL, 0, DB_FLOAT, DB_ZONECENT, DB_F77NULL, ierr2) 
    do k=kmin,kmax; do j=jmin,jmax; do i=imin,imax;
       matrix_small(i,j,k)=0.5*(v(i,j,k)+v(i,j-1,k))
    enddo; enddo; enddo
         
    ! Appending v_component variable to *.silo file  
    ierr2 = dbputqv1 (dbfile, 'vvel', 4, 'srm', 3, &
         matrix_small(ise:iee,jse:jee,kse:kee), dims_vof, &
         3, DB_F77NULL, 0, DB_FLOAT, DB_ZONECENT, DB_F77NULL, ierr2) 
	do k=kmin,kmax; do j=jmin,jmax; do i=imin,imax;
       matrix_small(i,j,k)=0.5*(w(i,j,k)+w(i,j,k-1))
    enddo; enddo; enddo
	
    ! Appending w_component variable to *.silo file  
    ierr2 = dbputqv1 (dbfile, 'wvel', 4, 'srm', 3, &
         matrix_small(ise:iee,jse:jee,kse:kee), dims_vof, &
         3, DB_F77NULL, 0, DB_FLOAT, DB_ZONECENT, DB_F77NULL, ierr2) 
    
    

    ! Closing *.silo file		
    ierr2 = dbclose(dbfile)

    ! Debugging message	
    !WRITE(*,*) "Every thing is fine! in proc: ", rank
    !210 format(e14.5)

    ! Updating index
    index = index + 1

#else
    call pariserror('For output type 5 Silo library is required')
#endif

  end subroutine output5

  function i2t(number,length)
    integer :: number, length, i
    character(len=length) :: i2t
    character, dimension(0:9) :: num = (/'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'/)
    if(number>=10**length) write(*,*) "i2t error: string is not large enough"
    do i=1,length
       i2t(length+1-i:length+1-i) = num(mod(number/(10**(i-1)),10))
    enddo
  end function i2t
  

  subroutine write_master(rootname, step, time, timestep)
    implicit none
#ifdef HAVE_SILO
    include 'silo_f9x.inc'
#endif
    integer err, ierr, dbfile, nmesh, oldlen, m, step
    character(*) :: rootname
    character(len=50) :: file_n
    character(len=40) :: fullname
    character(len=levarnames), dimension(numProcess) :: varnames, vec1n, vec2n
    character(len=levarnames), dimension(numProcess) :: vec3n, vecn
    character(len=lemeshnames), dimension(numProcess) :: meshnames
    integer, dimension(numProcess) :: lmeshnames, lvarnames, meshtypes, vartypes
    integer :: lfile_n, lsilon, optlist, timestep
    real(8) :: time

#ifdef HAVE_SILO
    ! Setting mesh types and variable types
    meshtypes = DB_QUAD_RECT
    vartypes = DB_QUADVAR

    lmeshnames = lemeshnames
    lvarnames = levarnames

    ! Setting multi mesh and variables paths
    file_n = TRIM(rootname)//i2t(step,padd)//'-'
    do m=0,numProcess-1
       fullname = TRIM(file_n)//TRIM(i2t(m,padd))//'.silo:srm'
       !Debugging message
       !write(*,*) 'Paths1 ', fullname
       meshnames(m+1) = TRIM(fullname)
       varnames(m+1) = TRIM(file_n)//TRIM(i2t(m,padd))//'.silo:cvof'
       vec1n(m+1) = TRIM(file_n)//TRIM(i2t(m,padd))//'.silo:uvel'
       vec2n(m+1) = TRIM(file_n)//TRIM(i2t(m,padd))//'.silo:vvel'
       vec3n(m+1) = TRIM(file_n)//TRIM(i2t(m,padd))//'.silo:wvel'
       !write(*,*) 'Paths ', meshnames(m+1)
    enddo

    ! Setting length of multi mesh file pash
    lsilon = 10 + padd

    ! Creating root file
    err = dbcreate('multi'//i2t(step,padd)//'.root', lsilon, DB_CLOBBER, DB_LOCAL, &
         "multimesh root", 14, DB_PDB, dbfile)

    if(dbfile.eq.-1) write (6,*) 'Could not create Silo file!'

    !Set the maximum string length
    oldlen = dbget2dstrlen()
    err = dbset2dstrlen(lemeshnames)

    ! Setting ghost layers, time step and physical time
    err = dbmkoptlist(2, optlist)
    err = dbaddiopt(optlist, DBOPT_CYCLE, step)
    err = dbaddiopt(optlist, DBOPT_DTIME, time)
    ! Append the multimesh object.
    err = dbputmmesh(dbfile, "srucmesh", 8, numProcess, meshnames, &
         lmeshnames, meshtypes, optlist, ierr)

    !Restore the previous value for maximum string length
    err = dbset2dstrlen(oldlen)

    ! Set the maximum string length
    oldlen = dbget2dstrlen()
    err = dbset2dstrlen(levarnames)

    ! Append the multivariable object.
    err = dbputmvar(dbfile, "cvof", 4, numProcess, varnames, lvarnames, &
         vartypes, DB_F77NULL, ierr)
         
	err = dbputmvar(dbfile, "uvel", 4, numProcess, vec1n, lvarnames, &
         vartypes, DB_F77NULL, ierr)
         
    err = dbputmvar(dbfile, "vvel", 4, numProcess, vec2n, lvarnames, &
         vartypes, DB_F77NULL, ierr)
         
    err = dbputmvar(dbfile, "wvel", 4, numProcess, vec3n, lvarnames, &
         vartypes, DB_F77NULL, ierr)
         
    err = dbputdefvars(dbfile, 'defvars',7, 1, 'velocity',8, &
    	DB_VARTYPE_VECTOR, '{uvel,vvel,wvel}', 16, DB_F77NULL, ierr)

    ! Set maximum string length
    err = dbset2dstrlen(oldlen)

    ! Close file
    err = dbclose(dbfile)

#endif
    !End subroutine
  end subroutine write_master

  ! End of Output zone================================================================================
end module module_st_testing




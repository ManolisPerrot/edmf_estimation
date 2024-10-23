#!/bin/bash


file=new_gabls4_meanprofile_les_MESONH_DIFU_1m_D1.nc
ncap2 -A -s 'zf=array(1.0,1.0,$zf)' $file $file

file=new_gabls4_meanprofile_les_MESONH_DIFU_1m_D2.nc
ncrename -d zz,zf $file
ncap2 -A -s 'zf=array(1.0,1.0,$zf)' $file $file


file=new_gabls4_meanprofile_les_MESONH_DIFU_50cm_D2.nc
ncrename -d zz,zf $file
ncap2 -A -s 'zf=array(0.5,0.5,$zf)' $file $file

file=new_gabls4_meanprofile_les_MESONH_DIFU_Dz50cm_D2.nc
ncrename -d zz,zf $file
ncap2 -A -s 'zf=array(0.5,0.5,$zf)' $file $file


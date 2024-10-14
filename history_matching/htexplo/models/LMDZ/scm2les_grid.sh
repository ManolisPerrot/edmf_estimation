#!/bin/bash

#. env.sh

#set -vx

####################################
## Author: MP Lefebvre & F.Hourdin (september 2018)
## This script transform file hourly_std.nc file which is on the 1D grid
## to hourly_grid_std.nc which is on the LES grid
####################################
orig_file=hourly_std.nc
\rm -f hourly_std_LES.nc*
\rm -f surf.nc


for var in `ncdump -h $orig_file | grep long_name | sed -e 's/:.*//' -e '/time/d'` ; do
# echo $var

if [ $var = levf -o $var = lon -o $var = lat  ] ; then
#echo PAS BON VAR 0D
echo 

elif [ "`ncdump -h $orig_file | grep -i "float $var" | grep levf`" = "" ] ; then

#echo TRAITEMENT VARIABLES SURF $var
ncdump -h $orig_file | grep -i "float $var" 
#echo ALORS ...
ncks -v $var $orig_file -A surf.nc
else

cat <<eod> tmp.jnl
use $orig_file
define axis/z=0:10000:100 axm
let NEW = ZAXREPLACE( $var,zf[l=1],z[gz=axm])
save/file=tmp.nc/CLOBBER NEW
quit
eod

ferret -batch -gif -script tmp.jnl
ncrename -O -v NEW,$var tmp.nc
ncks -A -v $var tmp.nc hourly_std_LES.nc

fi

done

rm -f ferret.jnl*
rm -f tmp.jnl
rm -f tmp.nc

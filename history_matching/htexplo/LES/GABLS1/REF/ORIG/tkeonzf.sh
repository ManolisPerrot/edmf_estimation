#!/bin/bash

# script thatinterpolate tke on zf levels (middle of layers)

module load cdo
module load nco

rm -f tmp1.nc
rm -f tmp2.nc
rm -f toto*.nc

newf=tkezf_${1}

cp $1 $newf


ncks -v zh $newf tmp1.nc
ncks -v zf $newf tmp2.nc

cdo intlevelx3d,tmp2.nc $newf tmp1.nc toto.nc

ncks -v tke toto.nc toto2.nc
ncrename -d lev,levf toto2.nc

ncrename -v tke,tke_h $newf
ncks -A -v tke toto2.nc $newf




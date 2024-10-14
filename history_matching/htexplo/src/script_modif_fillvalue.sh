#!/bin/sh

#. env.sh

cat << EOF > ficnco.nco
wpvp_conv(:,0)=wpvp_conv@_FillValue;
wpthp_conv(:,0)=wpthp_conv@_FillValue;
wpthp_pbl(:,0)=wpthp_pbl@_FillValue;
wpup_conv(:,0)=wpup_conv@_FillValue;
wpup_pbl(:,0)=wpup_pbl@_FillValue;
wpqp_conv(:,0)=wpqp_conv@_FillValue;
wpqp_pbl(:,0)=wpqp_pbl@_FillValue;
EOF
ls SCM* >list
for run in `more list`; do
ncap2 -O -S ficnco.nco ${run} new_${run}
done
cdo ensmin new_SCM-1-*.nc ensmin_SCM.nc
cdo ensmax new_SCM-1-*.nc ensmax_SCM.nc
cdo ensavg new_SCM-1-*.nc ensavg_SCM.nc

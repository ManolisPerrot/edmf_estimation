#!/bin/bash
# copy in the same dir as bench.sh, or change last line

met=""
for l in `cat list_selected.txt`  # list_selected.txt must be in the same dir
do
  for i in 01 05 08 # sza tab = [ 00 11 22 33 44 55 66 77 ]
  do
    s=`echo $l | awk -F "." ' { print $1 } '`
    c=`echo $l | awk -F "." ' { print $3 } '`
    t=`echo $l | awk -F "." ' { print $4 } '`
    thismet=RAD_${c}_${s}${t}_unt_${i}_${i}
    met=$met$thismet","
    thismet=RAD_${c}_${s}${t}_uptoa_${i}_${i}
    met=$met$thismet"," 
    thismet=RAD_${c}_${s}${t}_abs_${i}_${i}
    met=$met$thismet","
  done 
done

met=${met:0:-1}
name=miepf_8cases_3sza_unt_uptoa_abs_relativeTolfctSZA_q3Bias_overwrite_master
echo $name
echo $met

eval "./bench.sh ECRAD -wdir $name -waves `seq 1 15` -serie \
      _paper_overwrite -metrics $met -param param_papertuning_overwrite > \
      log_${name}_wave1-15.out 2>&1"

#!/bin/bash
# copy in the same dir as bench.sh, or change last line

met=""
for l in REF.1.ARMCU.008 REF.1.RICO.005  # list_selected.txt must be in the same dir
do
  for i in 01 05 08 # sza tab = [ 00 11 22 33 44 55 66 77 ]
  do
    s=`echo $l | awk -F "." ' { print $1 } '`
    c=`echo $l | awk -F "." ' { print $3 } '`
    t=`echo $l | awk -F "." ' { print $4 } '`
    thismet=RAD_${c}_${s}${t}_unt_${i}_${i}
    met=$met$thismet","
    #thismet=RAD_${c}_${s}${t}_uptoa_${i}_${i}
    #met=$met$thismet"," 
    #thismet=RAD_${c}_${s}${t}_abs_${i}_${i}
    #met=$met$thismet","
  done 
done

met=${met:0:-1}
name=BENCHECRAD
echo $name
echo $met

eval "./bench.sh ECRAD -wdir $name -metrics $met > log_${name}_wave1.out 2>&1"

#!/bin/bash

set -vx
##############################################################################
#
# This script merge individual 3D metrics files (one file per metric) into 
# one file called metrics_${wnb}.csv.
#
# NB: It should be used on the machine the 3D runs were done, i.e. irene or jean-zay.
#
# Input files (fin)  : ${ens}${wnb}_${metric_name}_${yr}.csv
# Output file (fout) : metrics_${wnb}.csv
# 
# ens      : the prefix of the ensemble runs
# wnb      : wave number
# yr       : year of the simulations
# wdir     : directory containing the metrics files
# met_list : list of 3D metrics to merge
#
# NB : individual metrics' files are in the $dmet directory
#      each metric file contains 2 columns with 
#      the simulation name in the 1st column and 
#      the metric' value in the 2nd column
#
# Usage : 
# ./merge_csv.sh -ens ${ens} -wnb ${wnb} -yr ${yr} -wdir ${wdir} "$met_list"
#
#
# Ionela Musat, 16.05.2023
##############################################################################

season=YEAR
hostname=`hostname`
local=`pwd`
. ${local}/env_tuning_3Dmet_"${hostname:0:5}".sh ${season}

echo Check/modify the input parameters below : wnb, ens, yr, wdir, met_list
# ens : the prefix of the ensemble runs
ens=SCM-
# wnb : wave number
wnb=40
# yr : year of the simulations
yr=1996
# wdir : directory containing the metrics files
wdir=${dmet}
wdir=${dmet}/METRICS
# met_list : list of 3D metrics to merge
met_list="glob.rt glob.rlut circAa.rsut circAa.rlut subs.rsut weak.rsut conv.rsut subs.rlut weak.rlut conv.rlut etoa.crest etoa.hfls MJO.pr GT50.pr AMMA.pr"
met_list="glob.rt glob.rlut circAa.rsut circAa.rlut subs.rsut weak.rsut conv.rsut subs.rlut weak.rlut conv.rlut etoa.crest etoa.hfls"

cd ${wdir}
#----------------------------------------------------------------
# Reading arguments
#----------------------------------------------------------------

while (($# > 0)) ; do
  case $1 in
    -dmet) dmet=$2 ; echo dmet $dmet ;  shift ; shift ; echo OPTION $* ;;
    -yr) yr=$2 ; echo yr $yr ;  shift ; shift ; echo OPTION $* ;;
    -ens) ens=$2 ; echo ens $ens ;  shift ; shift ; echo OPTION $* ;;
    -wnb) wnb=$2 ; echo WAVE $nWAVE ;  shift ; shift ; echo OPTION $* ;;
    -wdir) wdir=$2 ; echo wdir $wdir ;  shift ; shift ; echo OPTION $* ;;
    -help|-h) echo Usage "$0 [-wnb ${wnb}] [-ens ${ens}] [-yr ${yr}] [-wdir $dmet ] [metrics1] [metrics2] ..." ; exit ;;
    *) met_list=( ${met_list[*]} $1 ) ; shift ;;
  esac
done

echo met_list is $met_list

if [ "$met_list" = "" ] ; then 
echo met_list is empty, stopping here
exit
fi
fout=metrics_${wnb}.csv

wave=$wnb

# Remove old files
rm -f metrics_${wnb}.csv

echo '-----------------------------------------------------------'
echo STARTING loop on metrics
echo '-----------------------------------------------------------'
echo 'sim' $met_list|sed -e 's/ /,/g' >$fout

starting=1
\rm tmp3
for metric_name in ${met_list[@]};do
   echo $metric_name
   fin=${ens}${wnb}_${metric_name}_${yr}.csv
   echo $fin
   #more $fin
   #========================
   # Concatenation
   #========================
   if [ $starting == 1 ];then
      
      less ${fin} |awk '{print $1"," $2}' > tmp3
   else
      less ${fin} |awk '{print $2}' > tmp
      paste -d, tmp3 tmp >tmp2
      \mv tmp2 tmp3
      rm tmp
   fi
   starting=0
done # end loop $metric_name
cat tmp3>>$fout
exit

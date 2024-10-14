#!/bin/bash

#set -vx
###############################################################################
#
# This script merge individual metrics files (one file per metric) into 
# one file called metrics_${nwave}.csv
# and individual reference metrics files into one file called obs.csv
#     (if ref=y)
#
# Input files (fin)   : metrics_WAVE${nwave}_${metric_name}.csv for simulation
#                       metrics_REF_${metrics_name}.csv for references
# Output files (fout) : metrics_${nwave}.csv for simulations
#                       obs.csv for references
#
# Input files have to be in WORK/${EXP}/${wdir} directory
# as the output files would be (default value wdir=ImportedMetrics)
#
# nwave         : wave number
# metrics_name  : metrics name let to user choice
# EXP           : working tuning directory
# wdir          : input and ouput directory for specific metrics
#
#
# NB : individual metric files for simulation contains 2 columns : 
#      simulation name (SCM-${nwave}-${nsimu}) and metric value separated by ","
#      individual references files for references contains 2 columns : 
#      SIM,OBS_${metric_name}
#      and two lines : 
#      MEAN for targetted value and VAR for variance value (as a variance !)
#
# Usage : 
# ./merge_csv_othermet.sh -nwave ${nwave} -wdir ${wdir} -ref $ref "$met_list"
# 
# ref option (y/n) to merge references or not
#
# Maelle Coulon, adapted from merge_csv.sh, December 2023
##############################################################################

# nwave : wave number
nwave=41

# wdir : directory containing the metrics files
wdir=ImportedMetrics

#list of metric names
met_list="" 

#also merge references : 
ref=n #default option : no

cd ${wdir}
#----------------------------------------------------------------
# Reading arguments
#----------------------------------------------------------------

while (($# > 0)) ; do
  case $1 in
    -nwave) nwave=$2 ; echo WAVE $nWAVE ;  shift ; shift ; echo OPTION $* ;;
    -wdir) wdir=$2 ; echo wdir $wdir ;  shift ; shift ; echo OPTION $* ;;
    -ref) ref=$2 ; echo ref $ref ;  shift ; shift ; echo OPTION $* ;;
    -help|-h) echo Usage "$0 [-nwave ${nwave}] [-wdir $wdir ] [metrics1] [metrics2] ..." ; exit ;;
    *) met_list=( ${met_list[*]} $1 ) ; shift ;;
  esac
done

echo met_list is $met_list

if [ "$met_list" = "" ] ; then 
echo met_list is empty, stopping here
exit
fi
echo '-----------------------------------------------------------'
echo START MERGING metrics for simulations
echo '-----------------------------------------------------------'
fout=metrics_${nwave}.csv

echo 'sim' $met_list|sed -e 's/ /,/g' >$fout

# Remove old files
mv -f metrics_${nwave}.csv metrics_${nwave}_$$.csv

starting=1
\rm tmp tmp?
for metric_name in ${met_list[@]};do
   echo metrics name : $metric_name
   fin=metrics_WAVE${nwave}_${metric_name}.csv
   echo file in : $fin
   #========================
   # Concatenation
   #========================
   if [ $starting == 1 ];then
      
      less ${fin} |awk -F, '{print $1"," $2}' > tmp3
   else
      less ${fin} |awk -F, '{print $2}' > tmp
      paste -d, tmp3 tmp >tmp2
      \mv tmp2 tmp3
      rm tmp
   fi
   starting=0
done # end loop $metric_name
cat tmp3>>$fout

if [ $ref == y ] ; then
  echo '-----------------------------------------------------------'
  echo START MERGING metrics for references
  echo '-----------------------------------------------------------'
  fout=obs.csv
  
  echo 'sim' $met_list|sed -e 's/ /,/g' >$fout
  
  # Remove old files
  mv -f obs.csv obs_$$.csv
  
  starting=1
  \rm tmp tmp?
  for metric_name in ${met_list[@]};do
     echo $metric_name
     fin=metrics_REF_${metric_name}.csv
     echo $fin
     #========================
     # Concatenation
     #========================
     if [ $starting == 1 ];then
  
        less ${fin} |awk -F, '{print $1"," $2}' > tmp3
     else
        less ${fin} |awk -F, '{print $2}' > tmp
        paste -d, tmp3 tmp >tmp2
        \mv tmp2 tmp3
        rm tmp
     fi
     starting=0
  done # end loop $metric_name
  cat tmp3>>$fout
fi
exit

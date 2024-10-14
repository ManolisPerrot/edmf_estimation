#!/bin/bash

#. env.sh

##############################################################################
# Computing metrics from LES and SCM
# Result in csv format
# Auteur: F Couvreux, R Honnert, F Hourdin, N Villefranque, C Rio, n'co
##############################################################################
#
# metrics are specified in list_case
# metrics names follow the syntax
#
# CASE_SUBCASE_METRICS_T1_T2
# T1 and T2 are initial and final time step for time averages
# 
# unless it is a radiative metric, in which case the syntax is
# RAD_CASE_SUBCASETIME_METRICS_SZA1_SZA2
#
# available METRICS :
# ===================
#
# 1/ zav-400-600-var  -> variable "var" averaged between 400 and 600 m
#
# 2/ Ay-var -> integral ( min ( var -var(t=1) ) dz ) / integral ( dz )
#           integral taken from 0 to  zmax
#
# 3/ nebzave, neb2zave, neb4zave : Effective cloud height 
#           = int ( neb^p z dz ) / int ( neb^p dz ) with  p=1, 2 or 4
#
# 4/ nebmax : maximum cloud fraction on the column
#
# 5/ nebzmin, nebzmax : minimum/maximum cloud height
#
# 6/ lwp : liquid water path
#
# TBD :
# =====
# 1/ integrals are computed assuming rho=1 because rho is not systematically avalble
# 2/ the time average is coded for zav metrics only
#
##############################################################################

nWAVE=1


#----------------------------------------------------------------
# Reading arguments
#----------------------------------------------------------------

list_case=""
while (($# > 0)) ; do
  case $1 in
    -wave) nWAVE=$2 ; echo WAVE $nWAVE ;  shift ; shift ; echo OPTION $* ;;
    -help|-h) echo Usage "$0 [-wave N] [metrics1] [metrics2] ..." ; exit ;;
    *) list_case=( ${list_case[*]} $1 ) ; shift ;;
  esac
done

# Default metrics
if [ $list_case = "" ] ; then list_case=( ARMCU_REF_zav-400-600-theta_9_9 ) ; fi
	
wavedir=WAVE$nWAVE
mkdir -p ${wavedir}/individual_metrics

wave=$nWAVE
starting=1

# Remove old files
rm -f metrics_$wave.csv metrics_LES_$wave.csv 

echo '-----------------------------------------------------------'
echo STARTING loop on metrics
echo '-----------------------------------------------------------'

for metric_name in ${list_case[@]};do

   echo Computing Metric $metric_name

   # Where are the reference (target) nc files?
   if [ ${metric_name:0:3} == RAD ] ; then 
       # Radiative metrics
       REF=RAD
       REFs=RAD
   else 
       REF="LES"
       REFs="LES CTRL"
   fi

   echo Starting loop on References '('$REFs')' and simulations for wave $nWAVE
   for dir in $REFs ${wavedir} ; do
       echo ./extract_onemetric_csv.sh $metric_name $dir
       ./extract_onemetric_csv.sh $metric_name $dir
       if [ $? -ne 0 ] 
       then
         exit 1
       fi

       #========================
       # Concatenation
       #========================
       if [ $dir = $REF ] ; then
            dirname=REF
       else
            dirname=$dir
       fi
       if [ $starting == 1 ];then
         cp -f ${dir}_$metric_name.csv ${wavedir}/metrics_${dirname}_$wave.csv
       else
         cut -d, -f2 ${dir}_$metric_name.csv | paste -d, ${wavedir}/metrics_${dirname}_$wave.csv - > temp
         mv temp ${wavedir}/metrics_${dirname}_$wave.csv
       fi
       mv ${dir}_$metric_name.csv ${wavedir}/individual_metrics
   done
   starting=0
done # end loop $metric_name

#delete simulations that didn't work in at least one case
res=`grep ,, ${wavedir}/metrics_${dirname}_${wave}.csv | cut -c1-10`
echo res = $res
if [ -n "${res}" ] ;  then
  echo delete simulations that didnt work in at least one case :
  for sim in `echo $res` ; do
    echo sim = $sim
    echo $sim >> ${wavedir}/list_delsimu
    sed -i '/'$sim'/d' ${wavedir}/metrics_${dirname}_${wave}.csv
    sed -i '/'$sim'/d' ${wavedir}/Par1D_Wave${wave}.asc
  done
fi
res=`grep NaN ${wavedir}/metrics_${dirname}_${wave}.csv | cut -c1-10`
echo res = $res
if [ -n "${res}" ] ;  then
  echo delete simulations that didnt work in at least one case :
  for sim in `echo $res` ; do
    echo sim = $sim
    echo $sim >> ${wavedir}/list_delsimu
    sed -i '/'$sim'/d' ${wavedir}/metrics_${dirname}_${wave}.csv
    sed -i '/'$sim'/d' ${wavedir}/Par1D_Wave${wave}.asc
  done
fi

#!/bin/bash

#################################################################
# Script de lancement d'une serie de simulations pour HIGH TUNE #
#################################################################

if [ $# != 2 ]; then
	echo Use : ./$0 RADXXX/CASE/SUBCASE WAVEN
	exit 1
fi

tmp=$1
RAD=${tmp:0:6} # RADXXX
tmp=${tmp:7}   # CASE/SUBCASE
CASE="$(sed 's/\/.*//' <<< "$tmp")"
SUBC="$(sed 's/^[^;]*\///' <<< "$tmp")"
WAVEN=$2
EXPE=`pwd`/WAVE$WAVEN

# Here the model is ecrad
# Change the next line to match your installation
ECRAD=/home/villefranquen/Work/ECRAD/ecrad-1.1.0

if [ ! -d $ECRAD ]
then
  echo $ECRAD "cannot be found. Modify the ECRAD variable in" $0 "and try again."
  exit 1
fi

HTN=$ECRAD/test/tuning

if [ ! -d $HTN ]
then
  echo "Creating" $HTN "directory. Files from runECRAD will be copied in it."
  mkdir -p $HTN
  cp ../../models/ECRAD/runECRAD/* $HTN
fi

mkdir -p ${EXPE}/${CASE}/${SUBC}

bin=$ECRAD/bin/ecrad
dup=$HTN/duplicate_profiles.sh
chn=$HTN/change_namelist.sh
nam=$HTN/config_spartacus
inp=../../LES1D_ecRad/${CASE}-${SUBC}-${RAD:3}_1D.nc
cp $inp $HTN
inp=$HTN/${CASE}-${SUBC}-${RAD:3}_1D


# duplicate input profile
$dup ${inp}.nc ${inp}_sza.nc

# create config files from $EXPE/Par1D_Wave1.asc
sed -e 's/"//g' $EXPE/Par1D_Wave$WAVEN.asc > $HTN/param.asc

cd $HTN

params=()
for i in `head -1 param.asc` ; do
   params=( ${params[*]} $i )
done
nl=`wc -l param.asc | awk ' { print $1 } '`
il=2
while [ $il -le $nl ] ; do
   # extracting parameter values
   vals=()
   for i in `sed -n -e ${il}p param.asc`  ; do
      vals=( ${vals[*]} $i )
   done
   sim=${vals[0]}
   ip=1
   keyvals=
   while [ $ip -lt ${#vals[*]} ] ; do 
      keyvals=$keyvals" "${params[$ip]}"="${vals[$ip]}
      (( ip = $ip + 1 ))
   done

   # changing namelist
   $chn ${nam}.nam ${nam}_${sim}.nam ${keyvals}
   
   # running ecrad
   $bin ${nam}_${sim}.nam ${inp}_sza.nc ${sim}.nc

   mv ${sim}.nc ${EXPE}/${CASE}/${SUBC}
   (( il = $il + 1 ))
done

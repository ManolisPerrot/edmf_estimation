#!/bin/bash

#################################################################
# Script de lancement d'une serie de simulations pour HIGH TUNE #
#################################################################

if [ $# -lt 3 ]; then
	echo Use : ./$0 RAD/CASE/SUBCASE,RAD/CASE2/SUBCASE... WAVEN MODEL
	exit 1
fi

if [ $# -gt 3 ] ; then
  listecas=${@:1:$#-2} # all but last arguments
else
  listecas=$1
fi

WAVEN=${@: -2}       # antelast arg
MODEL=${@: -1}       # last arg
echo $listecas 

HERE=`pwd`

for cas in $listecas
do
  echo $cas
  tmp=${cas:4}   # CASE/SUBCASE
  echo $tmp
  CASE="$(sed 's/\/.*//' <<< "$tmp")"
  SUBC="$(sed 's/^[^;]*\///' <<< "$tmp")"
  RAD=${cas:0:3}${SUBC: -3} # RADXXX
  EXPE=`pwd`/WAVE$WAVEN

  echo $CASE
  echo $SUBC
  echo $RAD

  # Here the model is ecrad
  # Change the next line to match your installation
  ECRAD=/home/villefranquen/Work/ECRAD/ecrad-1.1.0

  if [ ! -d $ECRAD ]
  then
    echo $ECRAD "cannot be found. Modify the ECRAD variable in" $0 "and try again."
    exit 1
  fi

  HTN=$ECRAD/test/tuning_scenes
  L1D=../../LES1D_ecRad

  echo "Creating" $HTN "directory. Files from runECRAD will be copied in it."
  if [ ! -d $HTN ]
  then
    mkdir -p $HTN
  fi
  cp -f ../../models/ECRAD/runECRAD/* $HTN
  inp=$HTN/${CASE}-${SUBC}-${RAD:3}_1D
  echo $inp
  tmp=$L1D/${SUBC:0:-3}*${CASE}*${RAD:3}_1D.nc
  echo $inp $tmp
  cp $tmp ${inp}.nc

  mkdir -p ${EXPE}/${CASE}/${SUBC}

  bin=$ECRAD/bin/ecrad
  dup=$HTN/duplicate_profiles.sh
  scl=$HTN/scale_input.sh
  chn=$HTN/change_namelist.sh
  nam=$HTN/config_spartacus_these
  nam1D=$HTN/config_tripleclouds_these
  
  # duplicate input profile
  $dup ${inp}.nc ${inp}_sza.nc
  
  # create config files from $EXPE/Par1D_Wave1.asc
  sed -e 's/"//g' $EXPE/Par1D_Wave$WAVEN.asc > $HTN/param.asc
  
  cd $HTN
  
  params=()
  for i in `head -1 param.asc` ; do
     params=( ${params[*]} $i )
  done
  nl=`wc -l param.asc | awk ' { print $1 } '` # number of lines in the param.asc file
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
        # SELECTIONNER LES PARAMETRES QUI S'APPELLENT ECRAD_
        # et enlever le prefixe "ECRAD_" au nom du paramètre
        keyvals=$keyvals" "${params[$ip]}"="${vals[$ip]}
        (( ip = $ip + 1 ))
     done
  
     # before: scale input profiles ${inp}_sza.nc
     #$scl ${inp}_sza.nc ${inp}_sza_${sim}.nc ${keyvals}
     # now: change namelist
     echo $keyvals
     $chn ${nam}.nam ${nam}_${sim}.nam ${keyvals}
     $chn ${nam1D}.nam ${nam1D}_${sim}.nam ${keyvals}
     
     # running ecrad
     $bin ${nam}_${sim}.nam ${inp}_sza.nc ${sim}.nc
     $bin ${nam1D}_${sim}.nam ${inp}_sza.nc ${sim}_1D.nc
     ncrename -v flux_dn_sw,flux_dn_sw1D ${sim}_1D.nc -O ${sim}_1D.nc
     ncks -C -v flux_dn_sw1D ${sim}_1D.nc -A ${sim}.nc
     ncap2 -s "eff3D_dn_sw=flux_dn_sw-flux_dn_sw1D" ${sim}.nc -A ${sim}.nc
  
     cp ${sim}.nc ${EXPE}/${CASE}/${SUBC}
     (( il = $il + 1 ))
  done

  cd $HERE

done

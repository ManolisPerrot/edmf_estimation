#!/bin/bash

#################################################################
# Script de lancement d'une serie de simulations pour HIGH TUNE #
#################################################################

if [ $# -lt 2 ]; then
	echo Use : ./$0 RAD/CASE/SUBCASE,RAD/CASE2/SUBCASE... WAVEN
	exit 1
fi

if [ $# -gt 2 ] ; then
  listecas=${@:1:$#-1} # all but last arguments
else
  listecas=$1
fi

WAVEN=${@: -1}       # last arg
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
  ECRAD=/home/villefranquen/Work/ECRAD/ecrad-1.3.0

  if [ ! -d $ECRAD ]
  then
    echo $ECRAD "cannot be found. Modify the ECRAD variable in" $0 "and try again."
    exit 1
  fi

  HTN=$ECRAD/work/tuning_overwriteParams_paper
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
  nam=$HTN/config_spartacus_mean_profiles_all_paper
  
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
     params=()
     for i in `head -1 param.asc` ; do
        params=( ${params[*]} $i )
     done
     # extracting parameter values
     vals=()
     for i in `sed -n -e ${il}p param.asc`  ; do
        vals=( ${vals[*]} $i )
     done
     sim=${vals[0]}
     ip=1
     keyvals=
     sclvals=
     while [ $ip -lt ${#vals[*]} ] ; do 
        echo $ip
        echo ${params[$ip]}
        if [[ ${params[$ip]} == *"scale"* ]] ; then
          echo "Scaling"
          sclvals=$sclvals" "${params[$ip]}"="${vals[$ip]}
        else 
          echo "Namelist"
          if [[ ${params[$ip]} == "FSD" ]] ; then
            params[$ip]="fractional_std"
          elif [[ ${params[$ip]} == "DZ_OVP" ]] ; then
            params[$ip]="overlap_decorr_length"
          elif [[ ${params[$ip]} == "CS" ]] ; then
            echo ${params[$ip]} ${vals[$ip]}
            params[$ip]="low_inv_effective_size"
            vals[$ip]=`echo ${vals[$ip]} | awk '{ print  1./ $1 }' `
            echo ${params[$ip]} ${vals[$ip]}
          fi
          keyvals=$keyvals" "${params[$ip]}"="${vals[$ip]}
        fi
        (( ip = $ip + 1 ))
     done
      
     # first: scale input profiles ${inp}_sza.nc
     # echo $sclvals
     $scl ${inp}_sza.nc ${inp}_sza_${sim}.nc ${sclvals}
      
     echo $keyvals
     # then: change namelist
     $chn ${nam}.nam ${nam}_${sim}.nam ${keyvals}
      
     # running ecrad
     cmd="$bin ${nam}_${sim}.nam ${inp}_sza_${sim}.nc ${sim}.nc"
     eval $cmd
     if [ ! $? -eq 0 ] 
     then 
       echo "Something went wrong while running"
       echo $cmd 
       exit 1 
     fi
     cp ${sim}.nc ${EXPE}/${CASE}/${SUBC}
     (( il = $il + 1 ))
  done

  cd $HERE

done

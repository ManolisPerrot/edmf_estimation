#!/bin/bash

#################################################################
# Script de lancement d'une serie de simulations pour HIGH TUNE #
#################################################################

####### To run several occurences in parrallel ######
# You can put nproc = 1 to run it in sequentiel mode

nproc=$(( `lscpu  -e=core | sort | uniq | wc -l` - 1 ))
nproc=1
echo nproc = $nproc
wait_max=300
if [ $nproc = 1 ]   ; then wait_max=1 ; fi

###### To choose LES1D_ecRad file #####
## default option is empty
dir_les=L12.8km_hourly_ave
dir_les=""








### Reading arguments 

if [ $# -lt 3 ]; then
	echo Use : ./$0 RAD/CASE/SUBCASE,RAD/CASE2/SUBCASE... WAVEN MODEL
	exit 1
fi

if [ $# -gt 3 ] ; then
  listecas=${@:1:$#-2} # all but last two arguments
else
  listecas=$1
fi

WAVEN=${@: -2:1}       # antelast arg
MODEL=${@: -1}       # last arg
echo $listecas 

HERE=`pwd` # WORK/BENCHMODEL

if [ "$MODEL" == LMDZ ] ; then
  echo you are running ECRAD on $MODEL SCM
  echo WARNING : SCM clear sky is replaced by LES clear sky !
elif [ "$MODEL" != ECRAD ] ; then
  echo you ask to run ECRAD on $MODEL SCM
  echo some hypothesis are made for the treatment of the SCM for ECRAD to be able to run on it, on dephy2ecrad.sh and replaceclr_SCMtoLES.sh ONLY AVAILABLE for LMDZ SCM
  echo ask Maelle Coulon or Najda Villefranque for more informations
  exit 1
fi

### NOM DE LA NAMELIST A UTILISER POUR FAIRE TOURNER ECRAD 
namelist=config_spartacus_tune_lw3D
########

# Here the model is ecrad
# This is filled automatically by setup_ECRAD.sh
ECRAD=/home/villefranquen/work/tuning/HighTune-R440/../ecrad
HTN=$ECRAD/work/tuning_lw3D/

if [ ! -d $ECRAD ]
then
  echo $ECRAD "cannot be found. Modify the ECRAD variable in" $0 "and try again."
  exit 1
fi

echo "Creating" $HTN "directory. Files from runECRAD will be copied in it."
if [ ! -d $HTN ]
then
  mkdir -p $HTN
fi

cp -f ../../models/ECRAD/runECRAD/*sh      $HTN
cp -f ../../models/ECRAD/runECRAD/$namelist.nam $HTN

EXPE=`pwd`/WAVE$WAVEN
bin=$ECRAD/bin/ecrad
dup=$HTN/duplicate_profiles.sh
scl=$HTN/scale_input.sh
chn=$HTN/change_namelist.sh
nam=$HTN/$namelist
nam2nam=$HTN/nam2nam.sh
path_data=../../data #path depuis le repertoire ou ecrad tourne

# if ECRAD standalone
L1D=${HERE}/../../LES1D_ecRad/$dir_les

# create config files from $EXPE/Par1D_Wave1.asc
sed -e 's/"//g' $EXPE/Par1D_Wave$WAVEN.asc > $HTN/param.asc

#Some path changes on files on ${ECRAD}/dephy2ecard
sed -e "s#HERE=.*.#HERE=${ECRAD}/dephy2ecRad#" ${ECRAD}/dephy2ecRad/dephy2ecrad.sh > ${ECRAD}/dephy2ecRad/tmp_dephy2ecrad.sh
mv ${ECRAD}/dephy2ecRad/tmp_dephy2ecrad.sh ${ECRAD}/dephy2ecRad/dephy2ecrad.sh
chmod +x ${ECRAD}/dephy2ecRad/dephy2ecrad.sh

sed -e "s#HERE=.*.#HERE=${ECRAD}/dephy2ecRad#" ${ECRAD}/dephy2ecRad/replaceclr_SCMtoLES.sh > ${ECRAD}/dephy2ecRad/tmp_replaceclr_SCMtoLES.sh
mv ${ECRAD}/dephy2ecRad/tmp_replaceclr_SCMtoLES.sh ${ECRAD}/dephy2ecRad/replaceclr_SCMtoLES.sh
chmod +x ${ECRAD}/dephy2ecRad/replaceclr_SCMtoLES.sh 


cd $HTN

mkdir -p ${EXPE}/NAMECRAD

params=()
for i in `head -1 param.asc` ; do
   params=( ${params[*]} $i )
done
nl=`wc -l param.asc | awk ' { print $1 } '` # number of lines in the param.asc file
il=2
#start loop on parameters vectors for which we run simulations

######## Creating ECRAD namelist : namelist-ecrad_SCM-${WAVEN}-${sim} ######
echo CREATING ECRAD NAMELIST
#loop on simulations
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

  sim=${vals[0]: -3} # vals[0] = SCM-XXX => sim = XXX
  names=`head -1 param.asc | sed -e 's/\"//g' -e 's/ /,/g'` 
  vals_nam2nam=`sed -n -e ${il}p param.asc  | sed -e 's/\"//g' -e 's/ /,/g'`
  outnam=$EXPE/NAMECRAD/namelist_ecrad_SCM-${WAVEN}-${sim}
  $nam2nam -names $names -vals $vals_nam2nam -input $HTN/$namelist.nam -output $outnam 
  sed -i'' -e "s#directory_name.*.#directory_name=\"$path_data\"#" $outnam
  (( il = $il + 1 ))
done
namelist=namelist_ecrad_SCM-${WAVEN}-


######### Runing ECRAD ###########
echo RUNING ECRAD
cp $EXPE/NAMECRAD/${namelist}* $HTN
if [ -f $EXPE/NAMECRAD/sclvals.txt ]  ; then cp $EXPE/NAMECRAD/sclvals.txt $HTN ; fi

iproc=0
iii=0
# start loop on CASE/SUBCASE
for cas in $listecas 
do
  #echo $cas      # RAD/CASE/SUBCASEXXX
  tmp=${cas:4}   # CASE/SUBCASEXXX
  CASE="$(sed 's/\/.*//' <<< "$tmp")"     # CASE
  SUBC="$(sed 's/^[^;]*\///' <<< "$tmp")" # SUBCASEXXX
  TIME=${SUBC: -3}                        # XXX
  SUBC=`echo $SUBC | sed -e "s/$TIME//g"` # SUBCASE
  echo START LOOP ON $CASE ${SUBC}${TIME}
  #echo "cas  =" $cas
  #echo "tmp  =" $tmp
  #echo "case =" $CASE
  #echo "subc =" $SUBC
  #echo "time =" $TIME
  
  mkdir -p ${EXPE}/${CASE}/${SUBC}

  inp_in=$HTN/${CASE}-${SUBC}-${TIME}
  les1D=$L1D/${SUBC}.1.${CASE}.${TIME}_1D #LES pour le rayonnement

  function run_ECRAD {
    thisnam=$1
    inp=$2
    outecrad=$3
    if [ "$MODEL" == ECRAD ]
    then
      cp ${les1D}.nc ${inp}.nc
      scout=${inp}-${WAVEN}-${sim}
    else
      inp=${inp}-${WAVEN}-${sim}
      suf=${CASE}-${SUBC}${TIME}-${WAVEN}-${sim}
      tmp=${EXPE}/${CASE}/${SUBC}/SCM-${WAVEN}-${sim}.nc
      extract_time=`echo "$TIME-1" | bc -l`
      ncks -d time,$extract_time $tmp -O ${inp}-tmp-ncks.nc
      bash ${ECRAD}/dephy2ecRad/dephy2ecrad.sh ${inp}-tmp-ncks.nc ${inp}-dephy.nc > log_dephy2ecrad_$suf.out
      bash ${ECRAD}/dephy2ecRad/replaceclr_SCMtoLES.sh ${inp}-dephy.nc ${les1D}.nc ${inp}-replace.nc > log_replace-$suf.out
      cp ${inp}-replace.nc ${inp}.nc
      ##################### WATCH OUT ##################
      # THIS IS ONLY HERE BECAUSE THE MC REFS WERE RUN #
      #             WITH RE = 10 e-6 !!                #
      ncap2 -s "re_liquid=1e-5" ${inp}.nc -A ${inp}.nc #
      ##################################################
      scout=${inp}
    fi
        # duplicate input profile
    if [ ! -f ${inp}_sza.nc ]
    then
      $dup ${inp}.nc ${inp}_sza.nc > log_duplicate-$suf.out 2>&1
    fi

    # first: scale input profiles ${inp}_sza.nc
    if [ -f sclvals.txt ]
    then
      (( ip = $il + 1 ))
      sclvals=`sed -n "$ip p " sclvals.txt`
      echo $sclvals
      $scl ${inp}_sza.nc ${scout}_sza.nc ${sclvals}
      inp=${scout}
    fi
    cmd="$bin $thisnam ${inp}_sza.nc $outecrad"
    outlog=log_ECRAD_$suf

    eval $cmd > $outlog 2>&1
    cp $outecrad ${EXPE}/${CASE}/${SUBC}/RAD${TIME}-${WAVEN}-${sim}.nc
    if [ ! $? -eq 0 ]
    then
      echo "WARNING !!! Simulation $outecrad crashes"
      exit 1
    fi
  }

  il=0
  nsims=`ls ${namelist}* | wc -l `
  echo nsims = $nsims
  for sim in ` ( cd ${EXPE}/NAMECRAD ; ls ${namelist}* | sed -e "s/${namelist}//" ) ` ; do
    (( il = $il + 1 ))
    thisnam=$HTN/${namelist}${sim}
    outecrad=${HTN}/OUT-$CASE-$SUBC-RAD${TIME}-${WAVEN}-${sim}.nc
    suf=${CASE}-${SUBC}${TIME}-${WAVEN}-${sim}
    out=log_ECRAD_${suf}.out
    echo !!!!!!!!!!  RUNING $CASE ${SUBC}${TIME} $sim !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    if [ $nproc = 1 ] ; then
      time run_ECRAD $thisnam $inp_in $outecrad > $out  2>&1
      grep crashes $out ; \rm -f $out
    else
      # Parallel mode : ecrad  run as bacground process
      ( time run_ECRAD $thisnam $inp_in $outecrad > $out 2>&1 ; grep crashes $out ; \rm -f $out.gz ; gzip $out ) &
    fi
    (( iproc = $iproc + 1 ))
    if [ $iproc = $nproc -o $il = $nsims ] ; then
      dernier_fichier=$outecrad
      echo dernier_fichier = $outecrad
      iii=0
      while [ ! -f $dernier_fichier -a $iii -le $wait_max ] ; do
        sleep 1
        (( iii = $iii + 1 ))
	echo iii = $iii
        if [ $iii = $wait_max ] ; then 
	  echo You waited too long.
	  echo Last simulation failed
	  echo check $outecrad
	  exit
	fi
      done
      iproc=0
    fi
  done #fin boucle sur les simus

  
  #############################################################################
  # To be sure that all simulations are finished
  #############################################################################
  isim=2
  for sim in ` ( cd ${EXPE}/NAMECRAD ; ls ${namelist}* | sed -e "s/${namelist}//" ) ` ; do
    echo Final check for $sim
    outecrad=${HTN}/OUT-$CASE-$SUBC-RAD${TIME}-${WAVEN}-${sim}.nc
    while [ ! -f $outecrad ] ; do
      echo Waiting for passenger $outecrad
      sleep 3
    done
    (( isim = $isim + 1 ))
  done

  cd $HTN
done #fin boucle sur les cas
#on vide le repertoire de travail de ecrad pour pas être géné à la prochaine vague
\rm $HTN/*.nc
if [ -f $HTN/sclvals.txt ] ; then rm $HTN/sclvals.txt ; fi 
exit


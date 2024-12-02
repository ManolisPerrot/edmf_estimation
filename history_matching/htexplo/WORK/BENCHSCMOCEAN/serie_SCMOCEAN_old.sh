#!/bin/sh

#set -ex

## checks if exactly two arguments are passed to the script (a case/subcase and a wave 
## number). If not, it prints the usage instructions and exits.
if [ $# != 2 ] ; then
cat <<eod
Use : serie_EdmfOcean.sh CASE/SUBCASE NWAVE
eod
exit 1
fi

## extracts the current working directory (WORKDIR) and the values of case and subcase from 
## the first argument. The wave number (nwave) is taken from the second argument.
DIRMUSC=$REP_MUSC
WORKDIR=`pwd`

model=SCMOCEAN
tmp=$1
case="$(sed 's/\/.*//' <<< "$tmp")"
subcase="$(sed 's/^[^;]*\///' <<< "$tmp")"
name='SCM'
nwave=$2

## Paths for parameters and output directories are defined based on the case, subcase, and
## nwave (wave number).

## file containing parameters on which the SCM has to be evaluated 
PARAM=$WORKDIR/WAVE${nwave}/Par1D_Wave${nwave}.asc

repout=$WORKDIR/WAVE${nwave}/${case}/${subcase}
DIRNAMELIST=$WORKDIR/WAVE$nwave/namelist
DIRCONFIG=$WORKDIR/WAVE$nwave/config


## A few variables in the environment to specify the simulation configuration (model component: e.g. small_ap, etc...
# Please edit param_SCMOCEAN 
## TODO! or not? 
. ./param_SCMOCEAN

# Type of cleaning : no, nc, lfa, nclfa, all
clean='no'


#Use for rerunning some simulations in case of some (random) crashes (useful on mac)
## Mano: 'n' --> not reruning ??
rerun='n'

echo '***********************************************************************************'
echo 'Check in configsim.py that case, nlev and timestep is consistent with run_tuning.sh'
echo 'model ='$model
echo 'case = '$case
echo 'subcase = '$subcase
echo 'nlev = '$nlev
echo 'timestep = '$timestep
echo 'cycle = '$cycle ## to remove?
echo 'simuref = '$simuREF
echo 'namref = '$namref
echo 'wave = '$nwave
echo 'param = '$PARAM
echo 'repout ='$repout
echo '***********************************************************************************'

if [ $rerun == 'n' ]; then

## Creates necessary directories (mkdir -p) for storing output data and namelists. It then 
## removes old files (rm -f).
mkdir -p $repout
rm -f $repout/*
mkdir -p $DIRNAMELIST
rm -f $DIRNAMELIST/*
mkdir -p $DIRCONFIG
rm -f $DIRCONFIG/*

# creates a symbolic link to the parameter file param.asc
## it contains all the parameters on which we will run the SCM
rm -f param.asc
ln -s $PARAM param.asc
n=`wc -l param.asc | awk ' { print $1 } '`
nl=$(expr $n - 1)
echo 'nb de simu='$nl

#====== Specific to SCMOCEAN?






#===================================


















# Preparation des namelists
cp $namref namref
python prep_nam_tuning.py
mv namref.${name}* $DIRNAMELIST
mv namref $DIRNAMELIST
cp param.asc $DIRNAMELIST

rm -f param.asc

# Preparation des fichiers de config
python prep_config_tunning.py $nl $name $case $subcase $nwave $model $simuREF $cycle $MASTER $PGD $PREP $namsfx
mv config_* $DIRCONFIG

# Preparation fichier de configuration pour les simulations

cd $DIRMUSC

## temporarily overwrites a Python configuration file (configsim.py) with values for the 
## model (SCMOCEAN), case, number of levels (nlev), and timestep.
mv configsim.py configsim.py.save
cat << EOF > configsim.py
import sys
import EMS_cases as CC

model = '$model'

allcases=False

cases = ['$case']

nlev = $nlev
timestep = $timestep

for cc in cases:
  if not(cc in CC.cases):
    print 'case', cc, 'not available'
    print 'available cases:', CC.cases
    sys.exit()

lsurfex = True
if model in ['AROME','ARPPNT']:
    lsurfex = False
EOF

# Iterations sur les simulations
rm -f $WORKDIR/err.log

for i in `seq -f "%03g" 1 ${nl}`
#for i in `seq -f "%03g" 1 2`
do
  if [ $model == 'SCMOCEAN' ]; then
    ln -s $DIRMUSC/SURFEX/${cycle}/${simuREF} $DIRMUSC/SURFEX/${cycle}/${simuREF}.${name}-${nwave}-$i
  fi
  run_MUSC_cases.py $DIRCONFIG/config_${cycle}_${simuREF}.${name}-${nwave}-$i.py $case $subcase
# Pour être cohérent avec le calcul fait sur les LES
  cdo houravg $DIRMUSC/simulations/${cycle}/${simuREF}.${name}-${nwave}-$i/L${nlev}_${timestep}s/$case/$subcase/Output/netcdf/Out_klevel.nc $repout/${name}-${nwave}-$i.nc || echo $i >> $WORKDIR/err.log
  if [ $model == 'SCMOCEAN' ]; then
    rm -f $DIRMUSC/SURFEX/${cycle}/${simuREF}.${name}-${nwave}-$i
  fi
  if [ $clean == 'nc' ]; then
    rm -rf $DIRMUSC/simulations/${cycle}/${simuREF}.${name}-${nwave}-$i/L${nlev}_${timestep}s/$case/$subcase/Output/netcdf/*.nc
  fi
  if [ $clean == 'lfa' ]; then
    rm -rf $DIRMUSC/simulations/${cycle}/${simuREF}.${name}-${nwave}-$i/L${nlev}_${timestep}s/$case/$subcase/Output/LFAf/*.lfa
  fi
  if [ $clean == 'nclfa' ]; then
    rm -rf $DIRMUSC/simulations/${cycle}/${simuREF}.${name}-${nwave}-$i/L${nlev}_${timestep}s/$case/$subcase/Output/netcdf/*.nc
    rm -rf $DIRMUSC/simulations/${cycle}/${simuREF}.${name}-${nwave}-$i/L${nlev}_${timestep}s/$case/$subcase/Output/LFAf/*.lfa
  fi
  if [ $clean == 'all' ]; then
    rm -rf $DIRMUSC/simulations/${cycle}/${simuREF}.${name}-${nwave}-$i
  fi
done

mv configsim.py.save configsim.py

else

# On relance les simulations qui ont planté
ERRIN=err.log
ERROUT=err2.log
rm -f $WORKDIR/$ERROUT
cd $DIRMUSC/

mv configsim.py configsim.py.save
cat << EOF > configsim.py
import sys
import EMS_cases as CC

model = '$model'

allcases=False

cases = ['$case']

nlev = $nlev
timestep = $timestep

for cc in cases:
  if not(cc in CC.cases):
    print 'case', cc, 'not available'
    print 'available cases:', CC.cases
    sys.exit()

lsurfex = True
if model in ['AROME','ARPPNT']:
    lsurfex = False
EOF

for i in `cat $WORKDIR/$ERRIN`
do
  if [ $model == 'SCMOCEAN' ]; then
    ln -s $DIRMUSC/SURFEX/${cycle}/${simuREF} $DIRMUSC/SURFEX/${cycle}/${simuREF}.${name}-${nwave}-$i
  fi
  run_MUSC_cases.py $DIRCONFIG/config_${cycle}_${simuREF}.${name}-${nwave}-$i.py $case $subcase
# Pour être cohérent avec le calcul fait sur les LES
  cdo houravg $DIRMUSC/simulations/${cycle}/${simuREF}.${name}-${nwave}-$i/L${nlev}_${timestep}s/$case/$subcase/Output/netcdf/Out_klevel.nc $repout/tmp_${name}-${nwave}-$i.nc || echo $i >> $WORKDIR/$ERROUT
  cd  $repout
  ncks -v wpvp_conv,wpthp_conv,wpthp_pbl,wpup_conv,wpup_pbl,wpqp_conv,wpqp_pbl -d levh,1,91 tmp_${name}-${nwave}-$i.nc ${name}-${nwave}-$i.nc

  if [ $model == 'SCMOCEAN' ]; then
    rm -f $DIRMUSC/SURFEX/${cycle}/${simuREF}.${name}-${nwave}-$i
  fi
done

mv configsim.py.save configsim.py

fi

cd $WORKDIR

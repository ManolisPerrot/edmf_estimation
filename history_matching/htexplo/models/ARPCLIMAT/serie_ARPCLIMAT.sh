#!/bin/sh

#set -ex

if [ $# != 2 ] ; then
cat <<eod
Use : serie_ARPCLIMAT.sh CASE/SUBCASE NWAVE
eod
exit 1
fi

DIRMUSC=$REP_MUSC
WORKDIR=`pwd`

model=ARPCLIMAT
#model=AROME

#case=ARMCU
#subcase=REF
#case=AYOTTE
#subcase=24SC
tmp=$1
case="$(sed 's/\/.*//' <<< "$tmp")"
subcase="$(sed 's/^[^;]*\///' <<< "$tmp")"
name='SCM'
nwave=$2

PARAM=$WORKDIR/WAVE${nwave}/Par1D_Wave${nwave}.asc

repout=$WORKDIR/WAVE${nwave}/${case}/${subcase}
DIRNAMELIST=$WORKDIR/WAVE$nwave/namelist
DIRCONFIG=$WORKDIR/WAVE$nwave/config


# A few variables in the environment to specify the simulation configuration (model component)
# Please edit param_ARPCLIMAT

. ./param_ARPCLIMAT

# Type of cleaning : no, nc, lfa, nclfa, all
clean='no'

#Use for rerunning some simulations in case of some (random) crashes (useful on mac)
rerun='n'

echo '***********************************************************************************'
echo 'Check in configsim.py that case, nlev and timestep is consistent with run_tuning.sh'
echo 'model ='$model
echo 'case = '$case
echo 'subcase = '$subcase
echo 'nlev = '$nlev
echo 'timestep = '$timestep
echo 'cycle = '$cycle
echo 'simuref = '$simuREF
echo 'namref = '$namref
echo 'wave = '$nwave
echo 'param = '$PARAM
echo 'repout ='$repout
echo '***********************************************************************************'

if [ $rerun == 'n' ]; then

mkdir -p $repout
rm -f $repout/*
mkdir -p $DIRNAMELIST
rm -f $DIRNAMELIST/*
mkdir -p $DIRCONFIG
rm -f $DIRCONFIG/*


rm -f param.asc
ln -s $PARAM param.asc
n=`wc -l param.asc | awk ' { print $1 } '`
nl=$(expr $n - 1)
echo 'nb de simu='$nl

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
  if [ $model == 'ARPCLIMAT' ]; then
    ln -s $DIRMUSC/SURFEX/${cycle}/${simuREF} $DIRMUSC/SURFEX/${cycle}/${simuREF}.${name}-${nwave}-$i
  fi
  run_MUSC_cases.py $DIRCONFIG/config_${cycle}_${simuREF}.${name}-${nwave}-$i.py $case $subcase
# Pour être cohérent avec le calcul fait sur les LES
  cdo houravg $DIRMUSC/simulations/${cycle}/${simuREF}.${name}-${nwave}-$i/L${nlev}_${timestep}s/$case/$subcase/Output/netcdf/Out_klevel.nc $repout/${name}-${nwave}-$i.nc || echo $i >> $WORKDIR/err.log
  if [ $model == 'ARPCLIMAT' ]; then
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
  if [ $model == 'ARPCLIMAT' ]; then
    ln -s $DIRMUSC/SURFEX/${cycle}/${simuREF} $DIRMUSC/SURFEX/${cycle}/${simuREF}.${name}-${nwave}-$i
  fi
  run_MUSC_cases.py $DIRCONFIG/config_${cycle}_${simuREF}.${name}-${nwave}-$i.py $case $subcase
# Pour être cohérent avec le calcul fait sur les LES
  cdo houravg $DIRMUSC/simulations/${cycle}/${simuREF}.${name}-${nwave}-$i/L${nlev}_${timestep}s/$case/$subcase/Output/netcdf/Out_klevel.nc $repout/tmp_${name}-${nwave}-$i.nc || echo $i >> $WORKDIR/$ERROUT
  cd  $repout
  ncks -v wpvp_conv,wpthp_conv,wpthp_pbl,wpup_conv,wpup_pbl,wpqp_conv,wpqp_pbl -d levh,1,91 tmp_${name}-${nwave}-$i.nc ${name}-${nwave}-$i.nc

  if [ $model == 'ARPCLIMAT' ]; then
    rm -f $DIRMUSC/SURFEX/${cycle}/${simuREF}.${name}-${nwave}-$i
  fi
done

mv configsim.py.save configsim.py

fi

cd $WORKDIR

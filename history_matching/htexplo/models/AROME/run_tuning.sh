#!/bin/sh

#DIR0=`pwd`
DIRMUSC=/home/couvreux/MUSC
WORKDIR=`pwd`

#model=ARPCLIMAT
model=AROME

case=ARMCU
subcase=REF
#case=AYOTTE
#subcase=A24SC
name='SCM'
nwave=1

PARAM=$WORKDIR/WAVE1/Par1D_Wave${nwave}.asc

repout=$WORKDIR/WAVE${nwave}/${case}/${subcase}
DIRNAMELIST=$WORKDIR/WAVE$nwave/namelist
DIRCONFIG=$WORKDIR/WAVE$nwave/config



if [ $model == 'ARPCLIMAT' ]; then
  nlev=91
  timestep=300
  cycle=arp631
  simuREF=CMIP6
  namref=$DIRMUSC/main/namelist/ARPCLIMAT/nam.atm.tl127l91r.CMIP6.v631
elif [ $model == 'AROME' ]; then 
  nlev=90
  timestep=50
  cycle=41t1_op1.11_MUSC
  simuREF=AROME_OPER
  namref=$DIRMUSC/namelist/AROME/namarp_41t1_AROME_HTUNE
elif [ $model == 'ARPPNT' ]; then 
  nlev=90
  timestep=300
  cycle=41t1_op1.11_MUSC
  simuREF=ARPPNT_OPER
  namref=$DIRMUSC/namelist/ARPPNT/namarp_41t1_ARPEGE_OPER
fi

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
#echo $n
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
python prep_config_tunning.py $nl $name $case $subcase $nwave $model
mv config_* $DIRCONFIG

# Simulations
rm -f $WORKDIR/err.log
cd $DIRMUSC/main
sed s/CASEREF/$case/g configsimREF.py > tmp
sed s/MODEL/$model/g tmp > configsim.py
for i in `seq -f "%03g" 1 ${nl}`
do
  ln -s $DIRCONFIG/config_${cycle}_${simuREF}.${name}-${nwave}-$i.py $DIRMUSC/main/config/. 
  if [ $model == 'ARPCLIMAT' ]; then
    ln -s $DIRMUSC/main/SURFEX/${cycle}/${simuREF} $DIRMUSC/main/SURFEX/${cycle}/${simuREF}.${name}-${nwave}-$i
  fi
  run_MUSC_cases.py ${cycle} ${simuREF}.${name}-${nwave}-$i $case $subcase
#  cp $DIR0/../simulations/${cycle}/${simuREF}.${name}-${nwave}-$i/L${nlev}_${timestep}s/$case/Output/netcdf/Out_1hourly_klevel.nc $repout/${name}-${nwave}-$i.nc
# Pour être cohérent avec le calcul fait sur les LES
  cdo houravg $DIRMUSC/main/simulations/${cycle}/${simuREF}.${name}-${nwave}-$i/L${nlev}_${timestep}s/$case/$subcase/Output/netcdf/Out_klevel.nc $repout/${name}-${nwave}-$i.nc || echo $i >> $WORKDIR/err.log
  rm -f $DIRMUSC/main/config/config_${cycle}_${simuREF}.${name}-${nwave}-$i.py
  if [ $model == 'ARPCLIMAT' ]; then
    rm -f $DIRMUSC/main/SURFEX/${cycle}/${simuREF}.${name}-${nwave}-$i
  fi
done

else

# On relance les simulations qui ont planté
ERRIN=err2.log
ERROUT=err3.log
rm -f $WORKDIR/$ERROUT
cd $DIRMUSC/main/
for i in `cat $WORKDIR/$ERRIN`
do
  ln -s $DIRCONFIG/config_${cycle}_${simuREF}.${name}-${nwave}-$i.py $DIRMUSC/main/config/. 
  if [ $model == 'ARPCLIMAT' ]; then
    ln -s $DIRMUSC/main/SURFEX/${cycle}/${simuREF} $DIRMUSC/main/SURFEX/${cycle}/${simuREF}.${name}-${nwave}-$i
  fi
  run_MUSC_cases.py ${cycle} ${simuREF}.${name}-${nwave}-$i $case $subcase
#  cp $DIR0/../simulations/${cycle}/${simuREF}.${name}-${nwave}-$i/L${nlev}_${timestep}s/$case/Output/netcdf/Out_1hourly_klevel.nc $repout/${name}-${nwave}-$i.nc
# Pour être cohérent avec le calcul fait sur les LES
  cdo houravg $DIRMUSC/main/simulations/${cycle}/${simuREF}.${name}-${nwave}-$i/L${nlev}_${timestep}s/$case/$subcase/Output/netcdf/Out_klevel.nc $repout/${name}-${nwave}-$i.nc || echo $i >> $WORKDIR/$ERROUT
  rm -f $DIRMUSC/main/config/config_${cycle}_${simuREF}.${name}-${nwave}-$i.py
  if [ $model == 'ARPCLIMAT' ]; then
    rm -f $DIRMUSC/main/SURFEX/${cycle}/${simuREF}.${name}-${nwave}-$i
  fi
done

fi

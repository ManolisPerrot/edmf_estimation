#!/bin/bash

unset LANG

## D'ABORD FAIRE
# svn checkout --username htune https://svn.lmd.jussieu.fr/HighTune/trunk HighTune
# cd HighTune && bash setup.sh

if [ $# -lt 1 ] ; then 
  echo "Usage: $0 <nwave>|clean|setup [wave_two_metrics]"
  exit
fi

wave=$1
wave_two_metrics=9999 # starting from this wave, a second metric will be added
if [ $# -eq 2 ] ; then 
  wave_two_metrics=$2
fi

local=`pwd`
src=../../src

if [ "$wave" == "clean" ] ; then
echo -----------------------------------
echo  clean : menage des précédents runs
echo -----------------------------------

    \rm -r param ModelParam.R *.csv *Rdata *RData *asc *pdf Remain* WAVE* 
    exit
fi

if [ "$wave" == "setup" ] ; then
echo -----------------------------------
echo  setup : recuperation des logiciels
echo -----------------------------------

  cd $src
  \cp -f run_exemple_and_plot.sh $local/
  \cp -f HistoryMatching_addon.R htune_Emulating_Multi_Metric_Multi_LHS_new.R $local/
  \cp -f htune_convertDesign.R kLHC.R htune_convert.R param2R.sh htune_csv2Rdata.R $local/
  \cp -f htune_emulator_predictions.R htune_plot_emulator_predictions.py $local/
  cd -
  \cp -r $src/../ExeterUQ_MOGP/BuildEmulator . 
  \cp -f $src/BuildEmulator_tmp.R BuildEmulator/BuildEmulator.R
  ln -sf $src/../ExeterUQ_MOGP/HistoryMatching .
  ln -sf $src/../mogp_emulator .
  exit
fi

echo ------------------
echo  Work : WAVE $wave
echo ------------------

mkdir WAVE${wave}

set -ex

echo -------------------------------------------------------------
echo '[min,max]' des parametres
echo -------------------------------------------------------------
cat > param <<eod
a 0.7 2. 1   linear
b 0.5 1  0.8 linear
eod
cat param
# c -2. 2.  0.2 linear

echo -------------------------------------------------------------
echo Cible et tolerance pour les metriques
echo -------------------------------------------------------------

if [ $wave -lt $wave_two_metrics ] ; then 
  cat > cibles.csv <<eod
  TYPE,F
  MEAN,45
  VAR,0.0003
eod
else
  cat > cibles.csv <<eod
  TYPE,F,G
  MEAN,.8,.45
  VAR,0.0001,0.0003
eod
fi
cat cibles.csv
\cp -f cibles.csv metrics_REF_${wave}.csv


echo -------------------------------------------------------------
echo  Generation et transformation du fichier dee parametres
echo -------------------------------------------------------------

if [ ${wave} == 1 ] ; then
   ./param2R.sh param
   Rscript htune_convertDesign.R -LHCSIZE 10 -NLHC 1 -wave ${wave}
else
    echo 2B/ Computing the LHS for wave ${wave}
    Rscript htune_convertDesign.R -wave ${wave}
fi

echo -------------------------------------------------------------
echo  Generation des resultats de modeles
echo -------------------------------------------------------------

if [ $wave -lt $wave_two_metrics ] ; then 
  echo SIM,F > Metrics.csv
  tail -n +2 Par1D_Wave${wave}.asc | awk ' { sim=$1 ; a=$2 ; b=$3 ; c=$4 ; F=exp(-a*a)+0.01*cos(b*1000); print sim","F } ' | sed -e 's/"//g' >> Metrics.csv
  # tail -n +2 Par1D_Wave${wave}.asc | awk ' { sim=$1 ; a=$2 ; b=$3 ; F=10*log(2*a-1)+238+0.05*cos(b*1000000); print sim","F } ' | sed -e 's/"//g' >> Metrics.csv
else
  echo SIM,F,G > Metrics.csv
  tail -n +2 Par1D_Wave${wave}.asc | awk ' { sim=$1 ; a=$2 ; b=$3 ; c=$4 ; F=exp(-a*a)+0.01*cos(b*1000); G=a+0.05*sin(a*200); print sim","F","G } ' | sed -e 's/"//g' >> Metrics.csv
fi

\cp -f Par1D_Wave${wave}.asc Params.asc
Rscript --vanilla htune_csv2Rdata.R ${wave} -dir . -par Params.asc -sim Metrics.csv 

echo -------------------------------------------------------------
echo  Emulateur + history matching
echo -------------------------------------------------------------

\cp -f Params.asc Metrics.csv Wave${wave}.RData Par1D_Wave${wave}.asc Wave${wave}_SCM.Rdata Wave${wave}_REF.Rdata WAVE${wave}/
# ModelParam.R
time Rscript htune_Emulating_Multi_Metric_Multi_LHS_new.R -wave ${wave} -cutoff 3 -sample_size 30000 -sample_size_next_design 10

evince InputSpace_wave${wave}.pdf

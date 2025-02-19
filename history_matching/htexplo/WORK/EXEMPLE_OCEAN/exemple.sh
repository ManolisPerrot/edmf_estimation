#!/bin/bash

unset LANG

## D'ABORD FAIRE
# svn checkout --username htune https://svn.lmd.jussieu.fr/HighTune/trunk HighTune
# cd HighTune && bash setup.sh

if [ $# -lt 1 ] ; then 
  echo "Usage: $0 <nwave>|clean|setup [wave_two_metrics]"
  exit
fi


# 0.1/ Default values
metrics=FC_TH
waves=1 # could be waves=`seq 1 15`, waves="1 2 3"
sample_size=300000
sample_size_next_design=45

# 0.3/ options
while (($# > 0)) ; do
        case $1 in
          # -serie) serie=$2 ; shift ; shift ;; # useful for ecRad runs 
          # -wdir) wdir=$2 ; shift ; shift ;;
          # -param) param=$2 ; shift ; shift ;;
          -sample_size) sample_size=$2 ; shift ; shift ;;
          -sample_size_next_design) sample_size_next_design=$2 ; shift ; shift ;;
          -wave)  wave="$2"  ; shift ; shift ;;
	        # -GCM)  GCM="$2"  ; shift ; shift ;;
          # -model) model=$2 ; shift ; shift ;;
          -metrics) metrics="`echo $2 | sed -e 's/,/ /g'`" ; shift ; shift ;;
          # -dry) dryrun=1 ; shift ;;
          # TODO: WRITE --help
#           -h|-help|--help) echo Usage: $0 "[-param param_file] [-waves "1 [2 3 ...]"] [-wdir DIRNAME] [-sample_size sample_size] [-model model] [-metrics metrics1,metrics2,...] or directly "$0 model"" ; cat <<eod
# -param param_file : param_file contains the name, the min/max/nominal values, and the mode of exploration Linear/Log
#                     of the parameters
# -wdir WDIR        : the history matching sequence will be run on WORK/WDIR
# -waves WAVES      : WAVES is a sequence of numbers. 1 ; "1 2 3" ; "\`seq 1 20\`" 
#                     Can start at N+1 if waves 1 to N are already done
# -sample_size SAMPLESIZE : sample size for the NROY graphics
# -sample_size_next_design SAMPLESIZENEX : sample size for next design
# -model MODEL      : name of MODEL, available on models/
# -metrics METRICS  : METRICS is a list of metrics separated by "," or " "
# eod
#                 exit 0 ;;
          *) model=$1 ; shift ;;
        esac
done

echo "wave=$wave"
echo "metrics=$metrics"


# wave=$1
wave_two_metrics=9999 # starting from this wave, a second metric will be added
# if [ $# -eq 2 ] ; then 
#   wave_two_metrics=$2
# fi

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
echo Enable conda environment
echo -------------------------------------------------------------

source /home/manolis/anaconda3/etc/profile.d/conda.sh
conda deactivate
conda activate hightune

echo -------------------------------------------------------------
echo '[min,max,default]' of parameters
echo -------------------------------------------------------------
# /!\ ATTENTION l'ordre à l'air différent que dans SCM/LES : min, max, default et PAS min, default, max
cat > param <<eod
Cent 0 0.99 0.9 linear
Cdet 1 1.99 1.7 linear
wp_a 0.01 1.0 0.9 linear
wp_b 0.01 1.0 0.9 linear
wp_bp 0.25 2.5 2. linear
up_c  0 1. 0.5 linear
bc_ap 0 0.45 0.2 linear
delta_bkg 0.25 2.5 2. linear
wp0 1e-8 1e-1 0.5e-7 log
eod
cat param

echo -------------------------------------------------------------
echo Target and tolerance for metrics
echo -------------------------------------------------------------

# L2 metrics for field X:  int (X_scm - X_les)^2 dz dt / int dz dt
# /!\ in hightune terminology, there is a metric_scm that should match a metric_les.
# With our choice, 
# metric_scm = int (X_scm - X_les)^2 dz dt / int dz dt
# metric_les = int (X_les - X_les)^2 dz dt / int dz dt = 0 by DEFINITION
# VAR is error_model**2+error_data**2

# Define all the possible metrics and there mean/tolerance, with syntax: case_X  
cat > cibles_all.csv <<eod
TYPE,FC_TH,FC_dzTH,WC_TH,WC_dzTH,WC_U,WC_dzU
MEAN,0,0,0,0,0,0
VAR,1e-12,1e-12,1e-12,1e-12,1e-12,1e-12
eod

# Extract the columns corresponding to user-defined metrics
metrics_str=$(echo $metrics | tr ' ' ',') # Convert space-separated metrics to comma-separated
csvcut -c "TYPE,$metrics_str" cibles_all.csv > cibles.csv

cat cibles.csv
\cp -f cibles.csv metrics_REF_${wave}.csv


echo -------------------------------------------------------------
echo  Generation et transformation du fichier de parametres
echo -------------------------------------------------------------

if [ ${wave} == 1 ] ; then
# TODO: put nsampkes and NLHC in argument of the script
   ./param2R.sh param
    nsample=1
    # For the first wave, the sampling is done a $nsample sub-sampling
    # of size $subsample_size with a Latin Hypercube sampling
    subsample_size=$(( $sample_size_next_design / $nsample + 1 ))
   Rscript htune_convertDesign.R -LHCSIZE $subsample_size -NLHC $nsample -wave ${wave}
else
    echo 2B/ Computing the LHS for wave ${wave}
    Rscript htune_convertDesign.R -wave ${wave}
fi

echo -------------------------------------------------------------
echo  Generation des resultats de modeles
echo -------------------------------------------------------------

conda deactivate
conda activate base


python compute_metrics.py $wave $metrics

conda deactivate
conda activate hightune

\cp -f Par1D_Wave${wave}.asc Params.asc
Rscript --vanilla htune_csv2Rdata.R ${wave} -dir . -par Params.asc -sim Metrics.csv 

echo -------------------------------------------------------------
echo  Emulateur + history matching
echo -------------------------------------------------------------

\cp -f Params.asc Metrics.csv Wave${wave}.RData Par1D_Wave${wave}.asc Wave${wave}_SCM.Rdata Wave${wave}_REF.Rdata WAVE${wave}/
# ModelParam.R
time Rscript htune_Emulating_Multi_Metric_Multi_LHS_new.R -wave ${wave} -cutoff 3 -sample_size 30000 -sample_size_next_design 10

#evince InputSpace_wave${wave}.pdf

#!/bin/bash

unset LANG

## D'ABORD FAIRE la toute première fois 
# svn checkout --username htune https://svn.lmd.jussieu.fr/HighTune/trunk HighTune
# cd HighTune && bash setup.sh

set -eo pipefail


# usage (Check for at least one argument)
if [ $# -lt 1 ]; then
    echo "Usage: $0 clean|setup|[-wave NWAVE] [other options]"
    exit 1
fi

# 0.1/ Default values
metric_args='LES_IDEAL_GARANAIK2023_C01_mld4h --tol 1' #metricName of the form caseId_metricType and optional non-default tolerance 
waves=1 # could be waves=`seq 1 15`, waves="1 2 3"
sample_size_next_design=10 # number of SCM evaluations at each wave, 10*number of parameters
sample_size=30000 # number of Gaussian Process evaluations
action="run"

# 0.3/ options
while (($# > 0)) ; do
        case $1 in
          clean)   
            action="clean"  # special action
            shift 
            ;;
          -sample_size) sample_size=$2 ; shift ; shift ;;
          -sample_size_next_design) sample_size_next_design=$2 ; shift ; shift ;;
          -wave)  wave="$2"  ; shift ; shift ;;
	        # -GCM)  GCM="$2"  ; shift ; shift ;;
          # -model) model=$2 ; shift ; shift ;;
        #   -metrics) metrics="`echo $2 | sed -e 's/,/ /g'`" ; shift ; shift ;;
        #   -tolerance)  tolerance="$2"  ; shift ; shift ;; #tolerance to the metrics
          -metrics)
            shift
            # of the format caseID_metricType [--tol tolerance1] for each metric
            metric_args=("$@")
            break
            ;;
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
# -metrics METRICS  : METRICS is a list of metrics separated by "," 
# eod
#                 exit 0 ;;
          *) model=$1 ; shift ;;
        esac
done

echo "wave=$wave"
echo "metrics and tolerances ${metric_args[@]}"

# wave=$1
wave_two_metrics=9999 # starting from this wave, a second metric will be added
# if [ $# -eq 2 ] ; then 
#   wave_two_metrics=$2
# fi

local=`pwd`
src=../../src

if [ "$action" == "clean" ]; then
echo -----------------------------------
echo  clean : Cleaning previous runs
echo -----------------------------------

    \rm -r param ModelParam.R *.csv *Rdata *RData *asc *pdf Remain* WAVE* param_after_wave*
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
# Check if running a wave and the directory exists
if [ "$action" == "run" ]; then
    wave_dir="WAVE${wave}"
    if [ -d "$wave_dir" ]; then
        echo "$wave_dir already exists, indicating that wave1 has been previously done."
        echo "Please run '$0 clean' before rerunning this wave."
        exit 1
    fi
fi

mkdir WAVE${wave}

# set -ex

echo -------------------------------------------------------------
echo Enable conda environment
echo -------------------------------------------------------------

# set +u   # disable "unbound variable" check temporarily

# Initialize conda in a user-independent way
if command -v conda >/dev/null 2>&1; then
    eval "$(conda shell.bash hook)"
    conda deactivate 2>/dev/null || true
    conda activate hightune
else
    source ~/.bashrc
    micromamba activate hightune
fi



# set -u   # re-enable strict mode
# -------------------------------------------------------------
# Sanity checks (fail fast)
# -------------------------------------------------------------
#echo "Using conda env:"
#conda info --envs | awk '$1=="hightune"{print $1, $2}'

echo "Python executable:"
which python

echo -------------------------------------------------------------
echo '[min,max,default]' of parameters
echo -------------------------------------------------------------
# /!\ ATTENTION l'ordre à l'air différent que dans SCM/LES : min, max, default et PAS min, default, max
cat > param <<eod
cc1 2.5000 10.000 5.0000 linear
cc2 0.4000 1.6000 0.8000 linear
cc3 1.0000 4.0000 1.9680 linear
cc4 0.5360 2.1360 1.1360 linear
cc6 0.2000 0.8000 0.4000 linear
ct1 2.9500 12.500 5.9500 linear
ct2 0.3000 1.2000 0.6000 linear
ct3 0.5000 2.0000 1.0000 linear
ct5 0.1533 0.6633 0.3333 linear
ctt 0.3000 1.4000 0.7200 linear
eod
cat param

echo -------------------------------------------------------------
echo Target and tolerance for metrics
echo -------------------------------------------------------------

#mld4h: mld averaged over the 4 last hours

#TODO: clarify if it is STD or var ??

# cat > cibles_all.csv <<eod
# TYPE,perfect_mld4h
# MEAN,-39.0
# VAR,1
# eod

python compute_metrics_les.py ${metric_args[@]}

# # Extract the columns corresponding to user-defined metrics
# metrics_str=$(echo $metrics | tr ' ' ',') # Convert space-separated metrics to comma-separated
# csvcut -c "TYPE,$metrics_str" cibles_all.csv > cibles.csv

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

#conda deactivate
#conda activate baseMano

python compute_metrics_gotm.py $wave ${metric_args[@]}

#conda deactivate
#conda activate hightune

\cp -f Par1D_Wave${wave}.asc Params.asc
Rscript --vanilla htune_csv2Rdata.R ${wave} -dir . -par Params.asc -sim Metrics.csv 

echo -------------------------------------------------------------
echo  Emulateur + history matching
echo -------------------------------------------------------------

\cp -f Params.asc Metrics.csv Wave${wave}.RData Par1D_Wave${wave}.asc Wave${wave}_SCM.Rdata Wave${wave}_REF.Rdata WAVE${wave}/
# ModelParam.R
time Rscript htune_Emulating_Multi_Metric_Multi_LHS_new.R -wave ${wave} -cutoff 3 -sample_size $sample_size -sample_size_next_design $sample_size_next_design

evince InputSpace_wave${wave}.pdf

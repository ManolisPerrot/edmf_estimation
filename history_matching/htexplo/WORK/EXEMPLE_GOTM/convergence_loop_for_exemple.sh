  #!/bin/bash

  unset LANG
  # set -ex


  # if [ $# -lt 1 ] ; then 
  #   echo "Usage: $0 <nwave>|clean|setup [wave_two_metrics]"
  #   exit
  # fi


  # 0.1/ Default values
  metrics=FC_TH,WC_TH
  sample_size_next_design=90 # number of SCM evaluations at each wave, 10*number of parameters
  sample_size=300000 # number of Gaussian Process evaluations
  nroy_treshold=0.05 
  wave_max=15

  # 0.3/ options
  while (($# > 0)) ; do
          case $1 in
            # -serie) serie=$2 ; shift ; shift ;; # useful for ecRad runs 
            # -wdir) wdir=$2 ; shift ; shift ;;
            # -param) param=$2 ; shift ; shift ;;
            -sample_size) sample_size=$2 ; shift ; shift ;;
            -sample_size_next_design) sample_size_next_design=$2 ; shift ; shift ;;
            -nroy_treshold) nroy_treshold=$2 ; shift ; shift ;;
            -wave_max) wave_max=$2 ; shift ; shift ;;
            # -wave)  wave="$2"  ; shift ; shift ;;
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
  # -metrics METRICS  : METRICS is a list of metrics separated by "," 
  # eod
  #                 exit 0 ;;
            *) model=$1 ; shift ;;
          esac
  done

  # echo "wave=$wave"
  echo "metrics=$metrics"



  if [ -d WAVE1 ]; then 
    source exemple.sh -wave clean
  fi 


  echo -------------------------------------------------------------
  echo Initialization of the loop
  echo -------------------------------------------------------------
  wave=1
  source exemple.sh -wave $wave -metrics $metrics -sample_size $sample_size -sample_size_next_design $sample_size_next_design
  nroy_n=$(< Remaining_space_after_wave_1.txt)

  echo "Remaining space after wave 1: $nroy_n"

  echo -------------------------------------------------------------
  echo Loop on waves until convergence is reached
  echo -------------------------------------------------------------
  while [ $wave -lt $wave_max ] ; do
    wave=$(( $wave + 1 ))
    echo "wave=$wave"
    source exemple.sh -wave $wave -metrics $metrics -sample_size $sample_size -sample_size_next_design $sample_size_next_design
    nroy_n1=$(< Remaining_space_after_wave_${wave}.txt)
    delta=$(echo "$nroy_n - $nroy_n1" | bc -l)
    echo -------------------------------------------------------------
    echo "Remaining space after wave $wave: $nroy_n1"
    echo "delta NROY=$delta"
    echo -------------------------------------------------------------
    if [ "$(echo "$delta < $nroy_treshold" | bc -l)" -eq 1 ]; then
      echo -------------------------------------------------------------
      echo "Convergence reached"
      echo "Remaining space after wave $wave: $nroy_n1"
      echo -------------------------------------------------------------
      break
    fi
    nroy_n=$nroy_n1
  done

  if [ $wave -eq $wave_max ] ; then
    echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    echo "Convergence not reached after $wave_max waves"
    echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  fi

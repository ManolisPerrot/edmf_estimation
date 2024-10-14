#!/bin/bash

################################################################################
# SPECIFC slurm
#SBATCH --job-name=htexplo
#SBATCH --ntasks=32               # nb process mpi
#SBATCH --ntasks-per-node=32      # mpi / node
#SBATCH --cpus-per-task=1         # omp/mpi
#SBATCH --hint=nomultithread      # 1 thread /core (no hyperthreading)
#SBATCH --output=outhtexplo%j     # output file
#SBATCH --error=outhtexplo%j      # error file
#SBATCH --time=04:00:00
################################################################################


ulimit -s unlimited
unset LANG # for computation with awk

################################################################################
# HighTune bench.sh
#
# Author : Hourdin et al., frederic.hourdin@lmd.ipsl.fr
# Started in 2017
# Originally written as a bench of the htexplo tools, it has evolved
# in an an automatic tool that can run most of the applications.
# It can serve also as a guide on how to use it.
#
################################################################################
# 
# General structure and main functions called
#
# 0) Initialisations
#
# for N in 1 ... Nwave ; do
# 
#       2) if (N==1) param2R.sh -> ModelParam.R
#          if (N==1)  -> Waves[N].RData +  Par1D_Wave[N].asc
#          else          Waves[N].RData -> Par1D_Wave[N].asc
# 
#       3) serie_[MODEL].sh
#             Par1D_Wave3.asc -> Simulations 
#             Results on WAVE[N]/[CASE]/[SUBCASE]/SCM*nc
# 
#       4) compute_metrics_csv.sh 
#             simulations -> metrics csv
#          htune_csv2Rdata.R
#             csv to Rdata including adding old simulations.
# 
#       5) Emulator + history matching
#            htune_Emulating_Multi_Metric_Multi_LHS.R
#            Emulators sotred in :
#            -> WAVE[N]/EMULATOR_MULT_METRIC_wave[N].RData
#            -> WAVE[N]/EMULATOR_MULT_METRIC_wave[N]_mogp
#            New sample of parameter vectors in NROY[N]
#            -> Waves[N+1].RData
# 
# done
#
################################################################################
#  The htexplo tools are inheritated from the HighTune project,
#  and are described in a 3-part paper entitled
#  "Process-based climate model development harnessing machine learning"
#  Part I : General presentation
#  https://www.lmd.jussieu.fr/~hourdin/PUBLIS/ItuneI2020.pdf
#  Part II : An application to the LMDZ model
#  https://www.lmd.jussieu.fr/~hourdin/PUBLIS/Hourdin_HighTune_2021_Proof.pdf
#  Part III : An application to raditive transfer comupations
#
#  Results of part II can be reproduced by running the following commands :
#  Section 4 :
# ./bench.sh -wdir ArtII1 -waves "`seq 1 20`" -param param_ArtII1 -metrics "ARMCU_REF_zav-400-600-theta_7_9,ARMCU_REF_zav-400-600-qv_7_9,ARMCU_REF_nebmax_7_9,RICO_REF_nebmax_19_25,SANDU_REF_neb4zave_50_60"
#  Section 5 :
#  ./bench.sh -wdir ArtII2 -waves "`seq 1 40`" -param param_ArtII2 -sample_size 3000000 -sample_size_next_design 90 -metrics "ARMCU_REF_zav-400-600-theta_7_9,ARMCU_REF_zav-400-600-qv_7_9,IHOP_REF_zav-400-600-theta_7_9,ARMCU_REF_nebzave_7_9,ARMCU_REF_neb4zave_7_9,ARMCU_REF_nebmax_7_9,RICO_REF_nebmax_19_25,SANDU_SLOW_neb4zave_50_60,SANDU_REF_neb4zave_50_60,SANDU_REF_nebzave_50_60,SANDU_FAST_neb4zave_50_60"

################################################################################


echo '====================================================================='
echo   O/ default values and reading arguments
echo '====================================================================='


# 0.1/ Default values
model=LMDZ
metrics=RICO_REF_nebmax_9_9
param=param
waves=1 # could be waves=`seq 1 15`, waves="1 2 3"
serie="" 
sample_size=300000
sample_size_next_design=45

GCM=no
# Managing GCM GCM waves
# GCM = no : SCM/LES only
# GCM = pre : preparation of a wave. From design to metrcis computation in 1D
#            before breaking for running GCM, computing associated metrics and combining them with 1D
# GCM = post : runing emulator and preparing the next wave (pre)

# to only print commands and not execute them
dryrun=0

# 0.3/ options
while (($# > 0)) ; do
        case $1 in
          -serie) serie=$2 ; shift ; shift ;; # useful for ecRad runs 
          -wdir) wdir=$2 ; shift ; shift ;;
          -param) param=$2 ; shift ; shift ;;
          -sample_size) sample_size=$2 ; shift ; shift ;;
          -sample_size_next_design) sample_size_next_design=$2 ; shift ; shift ;;
          -waves)  waves="$2"  ; shift ; shift ;;
	        -GCM)  GCM="$2"  ; shift ; shift ;;
          -model) model=$2 ; shift ; shift ;;
          -metrics) metrics="`echo $2 | sed -e 's/,/ /g'`" ; shift ; shift ;;
          -dry) dryrun=1 ; shift ;;
          -h|-help|--help) echo Usage: $0 "[-param param_file] [-waves "1 [2 3 ...]"] [-wdir DIRNAME] [-sample_size sample_size] [-model model] [-metrics metrics1,metrics2,...] or directly "$0 model"" ; cat <<eod
-param param_file : param_file contains the name, the min/max/nominal values, and the mode of exploration Linear/Log
                    of the parameters
-wdir WDIR        : the history matching sequence will be run on WORK/WDIR
-waves WAVES      : WAVES is a sequence of numbers. 1 ; "1 2 3" ; "\`seq 1 20\`" 
                    Can start at N+1 if waves 1 to N are already done
-sample_size SAMPLESIZE : sample size for the NROY graphics
-sample_size_next_design SAMPLESIZENEX : sample size for next design
-model MODEL      : name of MODEL, available on models/
-metrics METRICS  : METRICS is a list of metrics separated by "," or " "
eod
                exit 0 ;;
          *) model=$1 ; shift ;;
        esac
done

# the run function will print command and exe or not depending on value of
# $dryrun
run() {
  echo "$@"
  if [ $dryrun -eq 0 ] ; then 
    $@
  fi
}

echo '====================================================================='
echo  1/ experiment setup and controls
echo '====================================================================='

if [ "$wdir" = "" ] ; then wdir=BENCH$model ; fi

if [ $GCM = post ] ; then
    echo '====================================================================='
    echo 1A/ Continuing an experiment after 3D GCM. Noting to initialize
    echo '====================================================================='
    echo CAS POST GCM $waves
    if [ "`echo $waves | wc -w`" != "1" ] ; then
           echo Just one wave when GCM is post ; exit
    fi

elif [ -d WORK/$wdir ] ; then
    echo '====================================================================='
    echo 1B/ Continuing an existing experiment
    echo '====================================================================='

    echo "Directory WORK/$wdir already exists. Do you want to continue (Y/n) ?"
    #read answ
    answ=Y
    if [ "$answ" = "n" ] ; then
        exit
    fi

    cd WORK/$wdir
    first_wtbd=`echo $waves | awk ' { print $1 } '`
    # Checking wether the sampling is available for WAVE$first_wtbd
    if [ ! -f WAVE$first_wtbd/Wave${first_wtbd}.RData_orig \
      -a ! -f Wave${first_wtbd}.RData ] ; then
      echo No Wave${first_wtbd}.RData file avaialable ; exit
    fi

    wavesdone="" ; for w in $waves ; do if [ -d WAVE$w ] ; then
       wavesdone="$wavesdone WAVE$w" ; fi ; done
    # Case were some of the waves tbd are there already
    lastwdone=`echo $wavesdone | awk ' { print $NF } ' | sed -e 's/WAVE//'`
    if [ $lastwdone -ne $first_wtbd ] ; then
	echo WAVES $wavesdone were already present
	echo From which wave do you really like to restart, the following\
             ones being be saved as WAVEN_$$ "(0 to stop)"
	read first_wtbd
	waves="`seq $first_wtbd \`echo $waves | awk ' { print $NF } '\``"
    fi

    if [ ! -f Wave${first_wtbd}.RData ] ; then
        mv WAVE${first_wtbd}/Wave${first_wtbd}.RData_orig Wave${first_wtbd}.RData
    fi

    echo '--------------------------------------------------------------------'
    echo 1A.1 saving previously run waves
    for w in $waves ; do
       if [ -d WAVE$w ] ; then
          echo saving wave $w in wave ${w}_$$
          mv WAVE$w WAVE${w}_$$
       fi
    done # Saving previously run waves
    cd -

else

   echo '======================================================================'
   echo 1C/ Running setup.sh $model $workdir for a new experiment
   echo '======================================================================'

   # 0.4/ Temporary trick to be able to compare old (ExeterUQ) and new
   #     (ExeterUQ_MOGP) Exeter tools
   #     To be removed as soon as the new versions are stabilized (2020/07/20)
   ExeterUQ=ExeterUQ_MOGP # ExeterUQ=ExeterUQ to come back to the old version
   sed -i'' -e 's/^ExeterUQ=.*.$/ExeterUQ='$ExeterUQ'/' setup.sh

   mkdir -p log
   if [[ "$metrics" = *"RAD"* ]] ; then
      echo Running ./setup.sh ECRAD $wdir : log in log/setup_rad$$
      ./setup.sh ECRAD $wdir > log/setup_rad$$ 2>&1
      if [ $? != 0 ] ; then
         echo Error in setup, tail log/setup_rad$$ : `tail log/setup_rad$$` ; exit 1
      fi
   fi
   if [ "$model" != ECRAD ] ; then
      echo Running ./setup.sh $model $wdir : log in log/setup_$model$$
      ./setup.sh $model $wdir > log/setup_$model$$ 2>&1
      if [ $? != 0  ] ; then
         echo Error in setup, tail log/setup_$model$$ ; tail log/setup_$model$$ ; exit 1
      fi
   fi
fi



                ##########################################
                echo  STARTING LOOP ON WAVES ON WORK/$wdir
                ##########################################




cd WORK/$wdir
source env.sh
for wave in $waves ; do

# Imposing a decreasing cutoff for the NROY definition (rather arbitrary)
# if [ $wave -le  4 ] ; then cutoff=3. ; elif [ $wave -le 7 ] ; then cutoff=2.5 ; else cutoff=2. ; fi
if [ $wave -le  10 ] ; then cutoff=3. ; elif [ $wave -le 70 ] ; then cutoff=2.5 ; else cutoff=2. ; fi

if [ "${GCM}" = "no" -o "${GCM}" = "pre" ] ; then

   echo '======================================================================'
   echo 2/ Building design for wave $wave
   echo '======================================================================'

   cp Wave${wave}.RData Wave${wave}.RData_orig
   if [ $wave = 1 ] ; then
       # Generating ModelParam.R from $param file
       run ./param2R.sh $param
       nsample=1
       # For the first wave, the sampling is done a $nsample sub-sampling
       # of size $subsample_size with a Latin Hypercube sampling
       subsample_size=$(( $sample_size_next_design / $nsample + 1 ))
       run Rscript htune_convertDesign.R -LHCSIZE $subsample_size -NLHC $nsample
   else 
       echo 2B/ Computing the LHS for wave $wave
       run Rscript htune_convertDesign.R -wave $wave
   fi 
   mkdir WAVE${wave}
   mv Wave${wave}.RDat* WAVE${wave}/
   mv Par1D_Wave${wave}.asc WAVE${wave}/



   echo '======================================================================'
   echo  3/ Running the requires SCM simulations for wave $wave
   echo '======================================================================'

   # extracting the list of required simulations from the list of
   # metrics ; simus = CASE/SUBCASE 
   simus=`for m in $metrics ; do if [ ${m:0:3} != RAD ] ; then echo \`echo $m | awk -F_ ' {print $1"/"$2 } '\` ; else str=\`echo $m | awk -F_ ' {print $2"/"$3 } '\` ; echo ${str:0:-3} ; fi ; done | sort | uniq`
   sed -i'' "s/WAVEN=.*/WAVEN="$wave"/g" expe_setup.R

   # extracting the list of required simulations from the list of
   # metrics ; only radiative metrics (first 3 chars = RAD) :
   # simus_rad = RAD/CASE/SUBCASE 
   simus_rad=`for m in $metrics ; do if [ ${m:0:3} == RAD ] ; then echo \`echo $m | awk -F_ ' {print $1"/"$2"/"$3 } '\` ; fi ; done | sort | uniq`
   echo 'LIST SIMU SCM:' $simus
   echo 'LIST SIMU RAD:' $simus_rad
   
   if [ "$model" != ECRAD ]
   then #run scm on $simus (list of CASE/SUBCASE)
     echo ./serie_${model}${serie}.sh $simus $wave '>' `pwd`/log/serie_$wave.log
     run time ./serie_${model}${serie}.sh $simus $wave   > `pwd`/log/serie_$wave.log 2>&1
     if [ $? != 0 ]; then
       echo "Error during serie_"${model}${serie}".sh"
       exit 1
     fi
   fi
 
   if [ "$simus_rad" != "" ]
   then #run ecrad on $simus_rad on 1D LES if model=ECRAD or scm runs otherwise
     echo ./serie_ECRAD${serie}.sh $simus_rad $wave $model '>' `pwd`/log/serie_${wave}_ECRAD.log
     run time ./serie_ECRAD${serie}.sh $simus_rad $wave $model > `pwd`/log/serie_${wave}_ECRAD.log 2>&1

     if [ $? != 0 ]; then
       echo "Error during serie_ECRAD"${serie}".sh"
       exit 1
     fi
   fi

   echo '===================================================================='
   echo  4/ Computing metrics runing for wave $wave
   echo '======================================================================'

   echo ./compute_metrics_csv.sh $metrics -wave $wave '>' log/metrics_$wave.log
   run time ./compute_metrics_csv.sh $metrics -wave $wave  > log/metrics_$wave.log 2>&1

   if [ $? != 0 ]; then
     echo "Error during compute_metrics_csv.sh"
     exit 1
   fi

   echo launch post_processing for 1D simulations in parallel 
   run bash post_processing_1D.sh $wave > log/out_post_processing_1D_$wave 2>&1 &

fi # GCM


if [ "${GCM}" = "no" -o "${GCM}" = "post" ] ; then

   echo '======================================================================'
   echo  5/ Building emulators and estimating NROY space $wave
   echo '======================================================================'


   echo '--------------------------------------------------------------------'
   echo 5.1/ Increasing sample_size if Nroy too small for wave '>' 1
   echo '--------------------------------------------------------------------'
   comp_sample_size() {
   if [ $wave -gt 1  ] ; then
     anticipated_reduction=1.5
     prev_remaining_space=Remaining_space_after_wave_$(( $wave - 1 )).txt
     echo      By $anticipated_reduction from one wave to the other
     echo      Reading the previous NROY fraction in $prev_remaining_space
     if [ ! -f $prev_remaining_space ] ; then
         echo "Error: $prev_remaining_space does not exist" ; exit
     else
         nroy_size=`cat $prev_remaining_space`
         if [ "$nroy_size" = 0 -o "$nroy_size" = "" ] ; then
            echo "Error: $prev_remaining_space empty or containing 0" ; exit
         else
            # bc - l doesn't handle scientific notation : 
	    is_es=`echo $nroy_size | grep e`
	    if [[ -n $is_es ]] ; then
	      #convert nroy_size to be handled by bc -l
	      n1=`echo ${nroy_size} | sed 's/e/\\*10\\^/' | sed 's/+//'`
	    else 
	      n1=$nroy_size
	    fi

            nroy_size_next=`echo $n1 / $anticipated_reduction | bc -l`
            sample_size_next_min=`echo $sample_size_next_design / $nroy_size_next | bc -l | cut -d. -f1`
            if [ $sample_size -lt $sample_size_next_min ] ; then
                sample_size=$sample_size_next_min
            fi
            echo New sample_size $sample_size
         fi
     fi
   fi
   }
   run comp_sample_size

   echo '----------------------------------------------------------------------'
   echo  5.2 Introducting results of the previous best simulations
   echo '----------------------------------------------------------------------'

   cat WAVE$wave/Par*asc > WAVE$wave/Params.asc
   cat WAVE$wave/metrics_WAVE*csv > WAVE$wave/Metrics.csv

   include_previous_waves=None

   case $include_previous_waves in 

       None)  echo Unsing only simylations from last wave ;;
    
       All)   for iw in `seq 1 $(( $wave - 1 ))` ; do
                  tail -n +2 WAVE${iw}/Par1D_Wave${iw}.asc >> WAVE${wave}/Params.asc
                  tail -n +2 WAVE${iw}/metrics_WAVE${iw}_${iw}.csv >> WAVE${wave}/Metrics.csv
              done ;;

       Bests) if [[ $wave -gt 1 && -f PrevSimulationsToBeIncluded.csv \
            && `wc -l PrevSimulationsToBeIncluded.csv | awk ' { print $1 } '` -gt 0  ]] ; then
            for sim in `cat PrevSimulationsToBeIncluded.csv` ; do
                for iw in `seq 1 $(( $wave - 1 ))` ; do # Loop on waves needed to avoid taking info in WAVEN_XXXX
                   grep $sim WAVE$iw/Par1D_Wave*.asc  >>  WAVE$wave/Params.asc
                   grep $sim WAVE$iw/metrics_WAVE*csv >>  WAVE$wave/Metrics.csv
                done
            done
       fi

   esac

   run Rscript --vanilla htune_csv2Rdata.R $wave -dir WAVE$wave -par Params.asc -sim Metrics.csv > log/cvs2Rdata.log 2>&1

   echo '----------------------------------------------------------------------'
   echo  5.3 Running htune_run_$wave.sh , log: log/htune_wave$wave.log
   echo '----------------------------------------------------------------------'
   echo Reading simulated metrics in WAVE${wave}/Wave${wave}_SCM.Rdata
   echo and corres. targets and tolerances in WAVE${wave}/Wave${wave}_REF.Rdata

   emulator=htune_Emulating_Multi_Metric_Multi_LHS.R
   echo source env.sh > htune_run_$wave.sh
   echo time Rscript $emulator -wave $wave \
       -cutoff $cutoff -sample_size $sample_size -sample_size_next_design \
       $sample_size_next_design >> htune_run_$wave.sh
   run time bash htune_run_$wave.sh     > log/htune_wave$wave.log 2>&1
   run gs -sDEVICE=pdfwrite -dPDFSETTINGS=/ebook -q -o InputSpace_wave${wave}_light.pdf InputSpace_wave${wave}.pdf
   \mv InputSpace_wave${wave}*pdf WAVE$wave/


   echo '----------------------------------------------------------------------'
   echo  5.4 Computing scores for the next wave, log in log/scores_$wave.log
   echo '----------------------------------------------------------------------'

   comp_scores() {
   ./post_scores.sh 1 $wave -nograph >> log/scores_$wave.log 2>&1 
   cat score*[0-9].csv | sed -e /MAX/d | awk -F, ' { if ( $NF <= 2. ) { print $1 } } ' > BestSimulations0-2.csv
   cat score*[0-9].csv | sed -e /MAX/d | awk -F, ' { if ( $NF >= 2 && $NF <= 3. ) { print $1 } } ' > PrevSimulationsToBeIncluded.csv
   echo 'Simulations with err/tolerance < 2 :'
   for iw in `seq 1 $wave` ; do
       echo `grep '\-'${iw}'\-' BestSimulations0-2.csv | wc -l` "in wave $iw"
   done
   }
   run comp_scores

   echo '======================================================================'
   echo  6/ Graphics
   echo '======================================================================'

   nmetrics=`echo $metrics | wc -w`
   nparams=`wc -l $param | awk ' { print $1 } '`

   function combine_pdf {
      if [ $nmetrics -gt 1 ] ; then
         pdfjam --nup ${nmetrics}x${nmetrics} WAVE$wave/Plots_Metrics.pdf --outfile tmp.pdf
      else
         \cp -f WAVE$wave/Plots_Metrics.pdf tmp.pdf
      fi
      pdfjam InputSpace_wave$wave.pdf WAVE$wave/Plots_LOO.pdf tmp.pdf --landscape --outfile WAVE$wave/synthesis.pdf
      
      nsubplots=`echo $nmetrics | awk ' { print int(($1-1)^0.5) + 1 } '` ; # echo $nsubplots
      \rm -f tmp*pdf ; ii=1
      for i in `seq -w 1 $nparams` ; do
         (( if = $ii + $nmetrics - 1 ))
         pdfjam --nup ${nsubplots}x${nsubplots} WAVE$wave/Plots_Metrics.pdf ${ii}-${if} --outfile tmp$i.pdf --landscape
         (( ii = $if + 1 ))
      done
      pdfjam tmp*.pdf --outfile WAVE$wave/PlotMetrics.pdf --landscape
   }
   run combine_pdf > out$$ 2>&1 &


fi

done

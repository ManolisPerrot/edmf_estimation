#!/bin/bash
#set -vx

graph=true
force_recompute=false


export MPLBACKEND='Agg' # To avoid infinitely slow python through ssh


##################################################################
# Computing and ploting scores from the htexplo results
# The scores consists, for each metrics in the ratio of the
# error to the tolerance.
# Those scores are stored in files named scoresXX.csv
# where XX is the wave number
# graphs Averaged.pdf and Maximum.pdf are generated
# Author : Frédéric Hourdin
##################################################################
#. env.sh

wavemin=0
wavemax=0
SCMvsLES=1

# 0.3/ options
while (($# > 0)) ; do
    case $1 in
      -h|--help) echo Use : $0 WAVEmin WAVEmax [-nograph] [-f] ; exit 1 ;;
      -nograph) graph=false ; shift ;;
      -f) force_recompute=true ; shift ;;
      *) if [ $# = 1 ] ; then
            $0 -h ; exit 1
         else
            wavemin=$1 ; wavemax=$2
            shift ; shift
         fi ;;
    esac
done

echo $(( $wavemin * $wavemax ))
if [ ! $(( $wavemin * $wavemax )) -gt 0 ] ; then $0 -h ; exit 1 ; fi

unset LANG # To avoid french notation, 0,003 instead of 0.003

#\rm -r tt* XMGR


echo --------------------------------------------------------------------------
echo Loop on waves
echo --------------------------------------------------------------------------

for wave in $(seq $wavemin $wavemax) ; do

  echo WAVE $wave

  if [ $SCMvsLES = 1 ] ; then
     # Standard SCM/LES setup.sh of HighTune bench
     param_file=WAVE${wave}/Par1D_Wave${wave}.asc
     sim_file=WAVE${wave}/metrics_WAVE${wave}_${wave}.csv
     obs_file=WAVE${wave}/metrics_REF_${wave}.csv
     score_file=score${wave}.csv
  else
     # more adhoc cases
     param_file=param.asc
     sim_file=metrics.csv
     obs_file=obs.csv
     score_file=score.csv
     sed -e 's/,/ /g' param.csv  > param.asc
  fi

  if [ ! -f ${score_file} -o $force_recompute = true ] ; then
      nmetrics=$(( `head -1 $sim_file | sed -e 's/,/ /g' |wc -w` - 1 ))
      echo WAVE $wave, $nmetrics metrics

      echo `head -1 $sim_file`,AVE,MAX > $score_file
      # Obs (LES) values : mean and variance
      grep  MEAN $obs_file   | sed -e s'/,/ /g' > csv.mean
      grep  VAR  $obs_file   | sed -e s'/,/ /g' > csv.std

      #####################################################################
      # Loop on simulations
      #####################################################################

      echo --------------------------------------------------------------------------
      echo Computing Error / tolreance '>'   $score_file
      echo     then adding  AVE and AVE
      echo --------------------------------------------------------------------------

      for sim in `awk -F, ' { print $1 } ' $sim_file | sed -n -e '2,$p'` ; do

         echo sim $sim
         # getting parameters for simulation $sim
         grep $sim $param_file > csv.param
         # getting metrics for simulation $sim
         grep $sim $sim_file | sed -e s'/,/ /g' > csv.SCM
         # Creating files containing the values SCM mean(obs) std(obs) for the 
         # various parameters
         for type in param SCM mean std ; do
              \rm -f line.$type
              for i in `cat csv.$type` ; do echo $i >> line.$type ; done
         done
         # Computing the normalised erroe    ( SCM - OBS )^2 / VAR  > tmp
         paste line.SCM line.mean line.std | sed -n -e '2,$p' | awk ' { print ( $1 - $2 )^2 / $3 } ' >| tmp
         # formatting as a csv line
         metrics_scores=`awk ' { print $1 ^ 0.5 } ' tmp` ; metrics_scores=`echo $metrics_scores | sed -e 's/ /,/g'`
         ave_score=`awk '  BEGIN { m=0 ; n=0 } { m=m+$1 ; n=n+1 } END { print (m/n)^0.5 }  ' tmp`
         max_score=`awk '  BEGIN { max = 0. } { if ( $1 > max ) { max = $1 } } END { print max^0.5 } ' tmp`
         echo $sim,$metrics_scores,$ave_score,$max_score >> $score_file
      done
      sed -i'' -e 's/ //g' ${score_file}
    fi
done

head -1 $sim_file | awk -F, ' { print $(NF-1) } '


if [ $graph = false ] ; then exit 0 ; fi

echo --------------------------------------------------------------------------
echo       Plotting maximum and average of error/tolerance
echo --------------------------------------------------------------------------
m1=
echo MIN MAX $wavemin $wavemax
for STAT in Maximum Average ; do
    echo STAT $STAT
    mkdir -p XMGR/$STAT
    \rm XMGR/$STAT/Wave_*
    list=""
    for i in $(seq $wavemin $wavemax)  ; do
           echo i $i
           awk -F, ' { print $(NF'$m1') } ' score$i.csv | sed -e 1d | sort -g > XMGR/$STAT/Wave_$i
           list="$list Wave_$i"
    done
    cd XMGR/$STAT
    pwd
    echo python ../../plot_scores.py $list "$STAT (error/tolerance)"
    python ../../plot_scores.py $list "$STAT (error/tolerance)"
    mv -f tmp.pdf ../../$STAT.pdf
    cd -
    m1="-1"
done


echo --------------------------------------------------------------------------
echo          computing normalized scores per metrics
echo --------------------------------------------------------------------------

list=""
for wave in `seq $wavemin $wavemax` ; do
  list="$list XMGR/WAVE$wave/tmp.pdf"
  echo DIAGNOSTICS METRICS WAVE $wave
  if [ ! -d XMGR/WAVE$wave ] ; then
      mkdir -p XMGR/WAVE$wave
      # sorting the score file according to the max metrics
      pwd
      nmetrics=$(( `head -1 score$wave.csv | sed -e 's/,/ /g' | wc -w` - 1 ))
      tail +2 score$wave.csv | sort --field-separator=',' -g -k$(( $nmetrics + 3 )) >| tmp
      echo "tail +2 score$wave.csv | sort --field-separator=',' -g -k$(( $nmetrics + 3 ))"
      for i in $(seq 2 $(( $nmetrics + 1 )) ) ; do
          awk -F, ' { print $'$i' } ' tmp | \
          sed -e 1d > XMGR/WAVE$wave/`sed -n -e 1p  score$wave.csv | awk -F, ' { print $'$i' } '`
      done
      cd XMGR/WAVE$wave
      echo python ../../plot_scores.py WAVE* "Normalized Error (error/tolerance), Wave #$wave"
      python ../../plot_scores.py WAVE* "Normalized Error (error/tolerance), Wave #$wave"
      pwd
      echo mv -f tmp.pdf ../../WAVE$wave/Scores_per_metrics$wave.pdf
      ls -lrt
#exit
      mv -f tmp.pdf ../../WAVE$wave/Scores_per_metrics$wave.pdf
      cd -
  fi
done

\rm ScoreMax.csv ScoreMean.csv
for i in `seq $wavemin $wavemax` ; do
   awk -F, ' { print $NF } ' score$i.csv  | sed 1d | sort -n | head -1 >> ScoreMax.csv
   awk -F, ' { print $(NF -1) } ' score$i.csv  | sed 1d | sort -n | head -1 >> ScoreMean.csv
done

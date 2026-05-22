#!/bin/bash


# Coverts ascii file with min, max and nominal values of parameters
# into a R code

list_case=""
while (($# > 0)) ; do
  case $1 in
    -help|-h) echo Usage "$0 [NLHCIZE NLHC] parameter_file" ; exit 0 ;;
    *) case $# in
         1) PARAM_FILE=$1 ; shift ;;
         *) $0 -h ; exit 1
       esac ;;
  esac
done


if [ ! -f $PARAM_FILE ] ; then echo fichier $PARAM_FILE inexistant ; exit 1 ; fi

NPARA=`wc -l $PARAM_FILE |awk ' {print $1 }'`
\rm -f ModelParam.R
echo NPARA=$NPARA >> ModelParam.R

names=( names lows highs defaults )

for col in  1 2 3 4 ; do
    (( ii = $col -1 ))
    liste='param.'${names[$ii]}='c('
    for val in `awk ' {print $'$col' } ' $PARAM_FILE` ; do
       if [ $col == 1 ] ; then       
         liste=$liste'"'$val'",'
       else
         liste="$liste$val,"
       fi
    done
   echo $liste | sed -e 's/,$/)/' >> ModelParam.R
done


liste="which.logs<-c("
ival=0
ilog=0
for val in `awk ' { print $5 } ' $PARAM_FILE` ; do
   (( ival = $ival + 1 ))
   if [ "$val" = "log" ] ; then
         liste="$liste$ival,"
         ilog=1
   fi
done
if [ $ilog == 0 ]; then 
        echo $liste | sed -e 's/($/()/' >> ModelParam.R
else
        echo $liste | sed -e 's/,$/)/' >> ModelParam.R
fi

cat <<eod>> ModelParam.R
  param.defaults <- param.defaults[1:NPARA]
  param.highs <- param.highs[1:NPARA]
  param.lows <- param.lows[1:NPARA]
  param.names <- param.names[1:NPARA]
eod

cat ModelParam.R

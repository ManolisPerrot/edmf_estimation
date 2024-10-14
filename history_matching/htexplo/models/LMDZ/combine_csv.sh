#!/bin/bash

# Merge metrics 
##############################################################################
# Combine metrics from 1D and 3D
# Result in .RData
#
# Use : ./combine_csv.sh $wave
#
# wave: wave number
# ITUNE_D : tuning directory
# ImportedMetrics   : tuning directory for the 3D metrics 
# 
# NB: 1/ WAVE${wave} will be moved to WAVE${wave}_1D
#     2/ metrics_WAVE${wave}_${wave}.csv will be renamed metrics_WAVE${wave}_${wave}_1D.csv
#     3/ 3D metrics file is called metrics_${wave}.csv
#
# Auteur: F Hourdin
# Comments + debuging : I. Musat
##############################################################################

###############################################################################
# Parameters controling the access to 1D tuning directory and 3D results
###############################################################################

# Wave number. Should be the same for the 1D and 3D tuning.
#wave=47
wave=$1

#ITUNE_D=/home/hourdin/ITUNE/R270/HighTune/WORK/LUDO2
ITUNE_D=`pwd`

echo OK0

###############################################################################
# Saving the metrics files of the 1D tuning
###############################################################################
cd $ITUNE_D
if [ ! -d WAVE${wave}_1D ] ; then cp -r WAVE${wave} WAVE${wave}_1D ; fi

echo OK1

###############################################################################
# Combining the 1D and 3D metrics
###############################################################################
# References
\rm o.csv
cut -d, -f2- ImportedMetrics/obs.csv > o.csv
paste -d, $ITUNE_D/WAVE${wave}_1D/metrics_REF_${wave}.csv o.csv >| $ITUNE_D/WAVE${wave}/metrics_REF_${wave}.csv

# Simulations
sed -n 1p $ITUNE_D/WAVE${wave}_1D/Par1D_Wave${wave}.asc >| par
head -1 $ITUNE_D/WAVE${wave}_1D/metrics_WAVE${wave}_${wave}.csv | cut -d, -f1- >| par1d
head -1 ImportedMetrics/metrics_${wave}.csv | cut -d, -f2- >| par3d 
paste -d, par1d par3d >| $ITUNE_D/WAVE${wave}/metrics_WAVE${wave}_${wave}.csv
# Loop on simulations that succeded in 3D
for sim in `awk ' { if (NR!=1) {print $1}} ' ImportedMetrics/metrics_${wave}.csv | cut -d, -f1` ; do
   echo $sim
   # Metrics
   grep $sim $ITUNE_D/WAVE${wave}_1D/metrics_WAVE${wave}_${wave}.csv > tmp1
   grep $sim ImportedMetrics/metrics_${wave}.csv | cut -d, -f2- > tmp2
   paste -d, tmp1 tmp2 >> $ITUNE_D/WAVE${wave}/metrics_WAVE${wave}_${wave}.csv
   # parameters
   grep $sim $ITUNE_D/WAVE${wave}_1D/Par1D_Wave${wave}.asc >> par
done
\mv -f par $ITUNE_D/WAVE${wave}/Par1D_Wave${wave}.asc


cd $ITUNE_D
\rm WAVE${wave}/Wave${wave}_REF.Rdata
\rm WAVE${wave}/Wave${wave}_SCM.Rdata
Rscript --vanilla htune_reduce_param.R $wave
Rscript --vanilla htune_csv2Rdata.R $wave

\rm o.csv tmp1 tmp2 par1d par3d

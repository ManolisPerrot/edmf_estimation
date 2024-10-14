#!/bin/bash

export MPLBACKEND='Agg' # To avoid infinitely slow python through ssh

##################################################################
# Creating precomputation for htexplo results plots
# for the current tuning wave : 
# 1) Compute scores for the SCM simulations
# 2) Compute ensembles statistics for SCM simulation
# 3) Compute the cloud cover = Max{rneb} and their ensembles and add it to ens${stat}.nc files
# 4) Compute ensembles statistics for RAD simulation (en${stat}_RAD${itime}.nc)
#
# Take the number of the wave as argument
#
# Author : Frédéric Hourdin - Maelle Coulon--Decorzens
##################################################################
#. env.sh
# set -vx

export MPLBACKEND='Agg' # To avoid infinitely slow python through ssh


WAVEN=1
WAVEN=$1

echo precomputation for post_plots for WAVE $WAVEN

# Computing scores fore all the SCM simulations of wave $WAVEN if not already done
if [ ! -f score$WAVEN.csv ] ; then echo Runing post_scores.sh first ; sleep 10 ; ./post_scores.sh $WAVEN $WAVEN ; fi
# Compute the mean and max of the ensembles
for d in WAVE$WAVEN/*/* ; do
  echo does WAVE$WAVEN exist ? in $d
  if [ -d $d ] ; then
    cd $d
    echo Yes, we start by computing stats on SCM
    ( for stat in min max avg ; do if [ ! -f ens${stat}.nc ] ; then cdo ens${stat} SCM*nc ens${stat}.nc ; fi ; done ) >> out.post$$ 2>&1

    #echo than we compute cc as max{rneb} first and their ensembles
    #nlast=`cat list_nruns | tail -n 1`
    #if [ ! -f ensavg_cc.nc ] ; then
    #  for nsim in `seq -w 001 ${nlast}` ; do 
    #    fic=SCM-${WAVEN}-${nsim}
    #    if [ ! -f ${fic}_cc.nc ] ; then
    #      ncwa -v rneb -a levf -y max ${fic}.nc ${fic}_cc.nc
    #      ncrename -v rneb,cc ${fic}_cc.nc
    #      ncatted -a long_name,cc,o,c,"Cloud cover as max(rneb)" ${fic}_cc.nc
    #      ncks -C -A -v cc ${fic}_cc.nc ${fic}.nc
    #    fi
    #  done
    #fi
    #( for stat in min max avg ; do if [ ! -f ens${stat}_cc.nc ] ; then cdo ens${stat} SCM*_cc.nc ens${stat}_cc.nc ; fi ; done ) >> out.post$$ 2>&1 

    #echo and we add cc stats to SCM stats
    #( for stat in min max avg ; do ncks -C -A -v cc ens${stat}_cc.nc ens${stat}.nc ; done ) >> out.post$$ 2>&1
    #echo and finally we erase the SCM-${waven}_???_cc.nc files
    #rm SCM-${WAVEN}-*_cc.nc
    
    # to know if there are some ECRAD files starting by RAD*.nc
    echo does radiative simulations exists ?
    radSim=`ls RAD*.nc`
    if [[ -n ${radSim:0:3} ]] ; then
      #there are some RAD*.nc file that we want to know their stat ensemble too
      list_time=""
      for fic in $radSim ; do
        res=`echo $list_time | grep ${fic:3:3}`
        if [[ -z $list_time ]] ; then
          list_time=${fic:3:3}
        elif [[ -z $res ]] ; then
          list_time=$list_time" "${fic:3:3}
        fi
      done
      echo yes, with time $list_time
      echo we compute their ensembles too
      for itime in $list_time ; do
        ( for stat in min max avg ; do if [ ! -f ens${stat}_RAD${itime}.nc ] ; then cdo ens${stat} RAD${itime}*nc ens${stat}_RAD${itime}.nc ; fi ; done ) #>> out.post$$ 2>&1
      done
      echo we are done with ensembles
    fi
    
    cd - >> out.post$$ 2>&1
 fi
done

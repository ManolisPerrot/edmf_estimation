#!/bin/bash

##################################################################
# Creating plot from the htexplo results
# 1) Plots vertical profiles for the various cases used with
#    best simulations and envelopes (trace_sens_LES.py)
#    you can specify severals hours of your case in time_cas
# 2) Plots time series with same color (trace_sens_LES.py)
#    for variables in list_serie
#    -> not runed by default
# 3) Scatter plots of cloud_cover used in ECRAD
#    (Mainly for Maelle, under development)
#    -> not runed by default
#
# Author : Frédéric Hourdin - Maelle Coulon--Decorzens
##################################################################
#. env.sh

\rm -f prof*png prof*pdf
cases=RCEOCE_REF
cases="RCEOCE_REF CINDY_REF ARMCU_REF IHOP_REF RICO_REF SANDU_SLOW SANDU_REF SANDU_FAST GABLS1_REF GABLS4_STAGE3 GABLS4_STAGE3SHORT"
list_serie="" #"cc"
list_scatter="" #"cc cldl cldt"
for cas in $cases ; do
 casdir=WAVE1/`echo $cas | sed -e 's:_:/:'`
 echo $casdir
 if [ -d $casdir ] ; then
   main=`echo $cas | cut -d_ -f1` ; sub=`echo $cas | cut -d_ -f2`
   case $cas in
      RCEOCE_REF|CINDY_REF) vars="hur rneb theta" ;;
      GABLS1_REF|GABLS4_STAGE3|GABLS4_STAGE3SHORT) vars="theta u v tke" ;;
      *) vars="qv rneb theta"
   esac
   res=`grep dateprof param_${cas}.py`
   #time by default in param_$cas.py
   time_cas=`echo ${res} | awk -F, '{print $4}'`
   case $cas in
      RICO_REF) time_cas="21" ; list_timerad="4 12" ;;
      ARMCU_REF) time_cas="20" ; list_timerad="8 12" ;;
      IHOP_REF) time_cas="13" ;;
      GABLS1_REF) time_cas="18" ;;
      GABLS4_STAGE3) time_cas="17" ;;
      GABLS4_STAGE3SHORT) time_cas="17" ;;
      SANDU_REF|SANDU_SLOW|SANDU_FAST) time_cas="0" ;;
   esac
   date_prof=`echo ${res} | awk -F= '{print $2}'`
   for time in $time_cas ; do
     date_prof_new=`echo ${date_prof} | awk -F, '{print $1"," $2","$3",'$time',"$4","$5")" }'` 
     sed -e "s/dateprof=.*./dateprof=${date_prof_new}/" param_${cas}.py >> tmp_param_${cas}.py ; mv tmp_param_${cas}.py param_${cas}.py

     for var in $vars ; do
       echo profil ${var} ${main} ${sub} ${time}
       python trace_sens_LES.py ${var} ${main} ${sub}
       #display profil_${cas}_${var}_*.png
       out=`basename profil_${cas}_${var}_*.png .png`
       echo $out
       convert $out.png $out.pdf
     done
   done # end loop on time_cas
   for var in $list_serie ; do
     echo serie ${var} ${main} ${sub}
     python trace_sens_LES.py ${var} ${main} ${sub}
   done
   for var in $list_scatter ; do
     for time_rad in $list_timerad ; do
       echo scatter cc ${var} ${main} ${sub} ${time_rad}
       python scatter_cc_ECRAD.py ${var} ${main} ${sub} ${time_rad} 
     done
   done
 fi
done

#pdfjam --nup 3x3 --frame true prof*pdf --outfile t.pdf --landscape

HERE=`pwd`
config=config_spartacus_upTOA

cp /data/mcoulon/01_RAYT-CLOUD_COMPENSATION/NPV6.3_round3/PROF_LES/metriques/metrics_LES_${config}.csv ${HERE}/


metrics=""
i=0
for sza in 01 05 08 ; do
  var=uptoa
  metrics=${metrics}" "ARMCU_REF008_${var}_${sza}_${sza}
  metrics=${metrics}" "ARMCU_REF012_${var}_${sza}_${sza}
  metrics=${metrics}" "RICO_REF005_${var}_${sza}_${sza}
  metrics=${metrics}" "RICO_REF012_${var}_${sza}_${sza}
done


#list_met=`echo $metrics | sed -e "s/,/ /g"`
#metrics=ARMCU_REF008_uptoa_01_01
for met in $metrics ; do
  echo $met
  CAS=`echo $met | awk -F_ '{ print $1 }'`
  tmp=`echo $met | awk -F_ '{ print $2 }'`
  SUBCAS=${tmp:0:3}
  HOUR=`echo ${tmp:3:6} | sed -e "s/0//g"`
  sza=`echo $met | awk -F_ '{ print $4 }'`
  
  echo python scatter_metriques_vs_cc_ECRAD.py cc $CAS $SUBCAS $HOUR $sza $met $config
  python scatter_metriques_vs_cc_ECRAD.py cc $CAS $SUBCAS $HOUR $sza $met $config
  mkdir SCATTER_MET
  mv scatter*uptoa*.png SCATTER_MET/
done

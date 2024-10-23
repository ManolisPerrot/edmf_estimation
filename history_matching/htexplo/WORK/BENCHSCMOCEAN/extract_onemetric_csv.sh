#!/bin/bash

#. env.sh


#set -vx

########################################################################
# Compute average btwn t1,t2,zmin,zmax for ncdf file
# Auteur: C Rio, F Hourdin
# Modified: F Couvreux
# Modified: 23/01/2019 N Villefranque from r110
# Modified: 23/09/2022 N Villefranque from r318
########################################################################

metric_full_name=$1

# if radiative metric, metric_full_name is
# RAD_CASE_SUBCASETIME_metrics_SZA1_SZA2
# ex: RAD_RICO_REF005_uptoa_01_01

dir=$2 # = LES/RAD or WAVEi

# tolerance on temperature at a given level
dtmin=0.5

# tolerance on humidity at a given level
dqmin=0.0005

# tolerance on wind components at a given level
dumin=0.25
dvmin=0.25

# tolerance on tke at a given level
dtkemin=0.005

# Tolerance (relative) on cloud cover (averaged, max ...)
err_neb=0.25

# Tolerance (relative) on cloud cover (averaged, max ...)
fact_noise=0.75

# Tolerance (relative) on cloud height (or other height possibly)
#      Shoud be at least of the order of dZ/Z
fact_dz_min=0.2

##### Options for radiative metrics #####
dir_rad=L12.8km_hourly_ave #specify a directory for specific radiative references

dir_rad="" #or empty for usual radiative references (empty by default)

## Tolerances for radiative metrics
#two choices : absolute or relative tolerances
#opt_rad : 1 for using absolute tolerances 
#          2 for relative tolerances (default option)


opt_rad=2

# 1. Absolute tolerance 

# Tolerances (absolute) for down surf, up toa, abs 
# HG dedd : 8.2 Wm2 x .38 = 3.1
err_dnsurf=3.8 # arrondi à 10 Wm2
# Mie : 17.2 Wm2 x .38 (cc) = 6.5 Wm2
err_dnsurf=7.6 # arrondi à 20 Wm2
err_dnsurf=10 
# HG dedd ou Mie ~ same : 12 Wm2 x .38 = 4.5
err_uptoa=4
err_uptoa=4

# HG dedd ou Mie ~ same : 7 Wm2 x .38 = 2.7
err_abs=3.8   # arrondi à 10 Wm2 
err_abs=4

# 2. Relative tolerances (to the mean reference value of the metrics)

# Tolerance (relative) for downward surface flux 
# = 0.07 (relative error on slab w/ phi HG-deddington) * 0.38 (~ largest scene cloud cover)
fact_dnsurf=0.0266
# = 0.14 (relative error on slab w/ phi Mie) * 0.38 (~ largest scene cloud cover)
fact_dnsurf=0.0532

# Tolerance (relative) for upward TOA flux  ## CORRECTED (10/09/2020)
# = 0.03 (relative error on slab w/ HG-deddington) * 0.38 (~ largest scene cloud cover)
fact_uptoa=0.0114
# = 0.07 (relative error on slab w/ phi Mie) * 0.38 (~ largest scene cloud cover)
fact_uptoa=0.0266

# Tolerance (relative) for absorbed flux
# = 0.03 (relative error on slab w/ phi HG-deddington or phi Mie) * 0.38 (~ largest scene cloud cover)
fact_abs=0.0114

# SZA 0
# q3 bias toa 5.866733431816101
# q3 bias abs 0.42227742820978165
# q3 bias sur 2.8116886615753174
# SZA 4
# q3 bias toa 8.072209358215332
# q3 bias abs 1.258452981710434
# q3 bias sur 2.751413941383362
# SZA 7
# q3 bias toa 4.059819459915161
# q3 bias abs 3.6166998147964478
# q3 bias sur 4.093038201332092

# Relative tolerance = ~ diff between spartacus with mean observed paramter values vs MC 
fact_unt_00=0.07 ; fact_abs_00=0.01 ; fact_uptoa_00=0.04
fact_unt_00=0.03 ; fact_abs_00=0.01 ; fact_uptoa_00=0.04

fact_unt_44=0.07 ; fact_abs_44=0.02 ; fact_uptoa_44=0.04
fact_unt_44=0.03 ; fact_abs_44=0.02 ; fact_uptoa_44=0.04

fact_unt_77=0.07 ; fact_abs_77=0.05 ; fact_uptoa_77=0.04
fact_unt_77=0.04 ; fact_abs_77=0.04 ; fact_uptoa_77=0.04

fact_lwtoa=0.03
fact_lwsurf=0.015

prefile_def=SCM

#########################################################################
unset LANG # avoiding french 0,003 instead of 0.003
#########################################################################

# only print the number without header or anything
NCKS="ncks -H -C -s %15.8f "

#########################################################################
# Decompisition of inputs
#########################################################################
#  IFS='_' read -a temp <<< $metric_full_name : TOO SOPHISTICATED FOR MACOS
temp=( `echo $metric_full_name | sed -e 's/_/ /g'` )
#echo metric_full_name $metric_full_name
#echo $temp
# si metrique non radiative
# temp = ( CAS SOUSCAS METRIC T1 T2 )
# si metrique radiative
# temp = ( RAD CAS SOUSCASTIME METRIC SZA1 SZA2 )

# Decomposition soit en
# cas_souscas_metrique_t1_t2 => comparaison SCM / LES ou LES / LES
# RAD_cas_souscas_metrique_t2_t2 => comparaison ecRad / MC sur le champ de cas/souscas, un souscas par instant, t2 = i_sza
# Attention de ne pas appeler un cas "RAD"
tmp=${temp[0]}
if [ ${tmp} == RAD ] # 3 first characters
then
  REF=RAD
  case_basis=${temp[1]}
  name_subcase=${temp[2]:0:-3}
  time=${temp[2]: -3}
  metric_name=${temp[3]}
  tmin=${temp[4]}
  tmax=${temp[5]} 
  prefile_def=RAD${time}
  #INS=${REF}${name_subcase: -3}
  case $tmin in 
    01) fact_unt=$fact_unt_00 ; fact_abs=$fact_abs_00 ; fact_uptoa=$fact_uptoa_00 ; fact_dnsurf=$fact_dnsurf_00 ;;
    05) fact_unt=$fact_unt_44 ; fact_abs=$fact_abs_44 ; fact_uptoa=$fact_uptoa_44 ; fact_dnsurf=$fact_dnsurf_44 ;;
    08) fact_unt=$fact_unt_77 ; fact_abs=$fact_abs_77 ; fact_uptoa=$fact_uptoa_77 ; fact_dnsurf=$fact_dnsurf_77 ;;
  esac
else
  REF=LES
  case_basis=${temp[0]}
  name_subcase=${temp[1]}
  metric_name=${temp[2]}
  tmin=${temp[3]}
  tmax=${temp[4]} 
fi

# metric_output_name : LES_cas_souscas_... ou RAD_RAD_cas_souscastemps_... ou WAVE1_cas_souscas ou WAVE1_RAD_cas_souscastemps_...
metric_output_name=${dir}_$metric_full_name
casename=$case_basis/$name_subcase
echo Cas $casename, metric $metric_name, time $tmin : $tmax, treating $dir
echo $metric_output_name # same info as above + subcase (+ time if RAD)

case $case_basis in
	ARMCU|RICO|IHOP) zmax_domain=3500 ;;
	SANDU) zmax_domain=2800 ;;
	GABLS1|GABLS4) zmax_domain=400 ;;
	*) zmax_domain=2000
esac

#########################################################################
nWAVE=${dir:4}

# a changer en fonction du repertoire de l'utilisateur
DIRin=$dir/$casename
if [ $REF == RAD -a $dir == RAD ] ; then
  DIRin=$DIRin/$dir_rad
fi
# ex: LES/ARMCU/REF ou RAD/ARMCU/REF ou WAVE1/ARMCU/REF

########################################################################
# list of files to be post processed
# LES or SCM
# trick to compute LES var when one LES only is available
# by shifting the time of the metrics by +1 or -1
# Default : no shift (shf=+0)
########################################################################
cd $DIRin
shfs="+0"
if [ -f LES0.nc ] ; then
  prefile=LES
  if [ ! -f LES1.nc ] ; then shfs="+0 -1 +1" ; fi
elif [ -f LESLESSCM_${nWAVE}-001.nc ] ; then
  prefile=LESLESSCM_${nWAVE}-
elif [[ `pwd` == *"/RAD/"* ]] ; then # on est dans RAD/
  if [ -f RAD${time}.nc ] ; then
    prefile=RAD
  else 
    echo "error: NO REFERENCE FOR THE METRIC" $metric_full_name
    exit 1
  fi
elif [ -f SCM.nc ] ; then
  # Gestion assez horrible. A retravailler.
  # Toutes lees autres simulations on des numéros à la fin.
  # Mais pas le controle qui s'appelle SCM.nc
  prefile="S"
else
  # if scm, prefile_def = SCM
  # if rad, prefile_def = RAD$time (RAD005)
  prefile=${prefile_def}-${nWAVE}-
fi
if [[ `pwd` == *"/RAD/"* ]] ; then
  # many RADXXX in CASE/SUBCASE, use only one
  ls ${prefile}${time}*nc > list
else
  ls ${prefile}*nc > list
fi
sed -e "s/$prefile//" -e "s/.nc//" list > list_nruns
nruns=`wc -l list_nruns | awk '{print $1}'`
nr=0
cd -

########################################################################
# Loop on metrics
########################################################################

tmp=metrics_tmp.csv
echo $metric_output_name >| $tmp
for run in `cat $DIRin/list_nruns`; do
  for shf in $shfs ; do 
    run3=${run}
    file=$DIRin/$prefile${run3}
    (( nr = $nr + 1 ))
    #################################################################
    #defini les bornes temporelles et verticales
    #################################################################
    t1=`echo $tmin | awk ' { print $1 - 1 '$shf' } '`
    t2=`echo $tmax | awk ' { print $1 - 1 '$shf' } '`
    t1R=`echo $tmin | awk ' { print $1 '$shf' } '`
    t2R=`echo $tmax | awk ' { print $1 '$shf' } '`

    if [ $REF == RAD ]
    then 
      if [ $dir == RAD ] 
      then # In Monte Carlo netCDF files
        vlev=vertical_levels
        vlev_toa=-1
        vlev_surf=0
        calc_std=1
      else # In ecRad netCDF files (reverse z order and head / tail are different )
        vlev=half_level
        vlev_toa=0
        vlev_surf=-1
        calc_std=0
      fi
      if [ "$metric_name" = "lwu" -o "$metric_name" = "lwd" ] ; then
        if [ $calc_std -eq 1 ] ; then # MC 
          std_lwtoa=`$NCKS  -d column,$t1,$t2 -d $vlev,$vlev_toa  -v std_flux_dn_lw $file.nc`
          std_lwsurf=`$NCKS -d column,$t1,$t2 -d $vlev,$vlev_surf -v std_flux_dn_lw $file.nc`
        else # ecRad => select right height because vertical levels don't correspond !!!
          vlev_toa=30
          vlev_surf=-4
        fi
        lwsurf=`$NCKS  -d column,$t1,$t2 -d $vlev,$vlev_surf -v flux_dn_lw $file.nc`
        lwtoa=` $NCKS  -d column,$t1,$t2 -d $vlev,$vlev_toa  -v flux_up_lw $file.nc`
      else
        dntoa=` $NCKS  -d column,$t1,$t2 -d $vlev,$vlev_toa  -v flux_dn_sw $file.nc`
        uptoa=` $NCKS  -d column,$t1,$t2 -d $vlev,$vlev_toa  -v flux_up_sw $file.nc`
        dnsurf=`$NCKS  -d column,$t1,$t2 -d $vlev,$vlev_surf -v flux_dn_sw $file.nc`
        upsurf=`$NCKS  -d column,$t1,$t2 -d $vlev,$vlev_surf -v flux_up_sw $file.nc`
        if [ $calc_std -eq 1 ] ; then
          std_dntoa=`$NCKS  -d column,$t1,$t2 -d $vlev,$vlev_toa  -v std_flux_dn_sw $file.nc`
          std_uptoa=`$NCKS  -d column,$t1,$t2 -d $vlev,$vlev_toa  -v std_flux_up_sw $file.nc`
          std_dnsurf=`$NCKS -d column,$t1,$t2 -d $vlev,$vlev_surf -v std_flux_dn_sw $file.nc`
          std_upsurf=`$NCKS -d column,$t1,$t2 -d $vlev,$vlev_surf -v std_flux_up_sw $file.nc`
        fi
      fi
    fi
    case ${metric_name:0:3} in
      "unt") # untrans(mitted)
        metric=`echo $dntoa $dnsurf | awk '{ print $1 - $2 }' `
        ;;
      "dns") metric=$dnsurf ;;
      "upt") metric=$uptoa  ;;
      "dnt") metric=$dntoa  ;;
      "abs") metric=`echo $dntoa $dnsurf $upsurf $uptoa | awk '{ print $1 - $2 + $3 - $4 }' ` ;;
      "lwu") metric=$lwtoa  ;;
      "lwd") metric=$lwsurf ;;

      #################################################################
      # Metrics computed in R with htune_netcdf2csvMetrics.R
      "neb"|"lwp"|"Ay-"|"net"|"rat"|"tra") 
      #################################################################
	      #metric=`Rscript --vanilla htune_netcdf2csvMetrics.R $file.nc $metric_name $t1R $t2R $zmax_domain | awk ' { print $2 } '`
	      metric=`Rscript htune_netcdf2csvMetrics.R $file.nc $metric_name $t1R $t2R $zmax_domain | awk ' { print $2 } '`
	      ;;

      #################################################################
      # Metrics computed in R with htune_netcdf2csvMetrics.R
      "noi")
      #################################################################
              tmp_=( `echo $metric_name | sed -e 's/-/ /g'` )
              var_=${tmp_[1]}
              z1_=${tmp_[2]}
              z2_=${tmp_[3]}
              echo tmp_ ${tmp_[*]}
              echo var $var_
	      echo Rscript htune_noise_metrics.R $file.nc $var_ $t1R $t2R $z1_ $z2_
	      metric=`Rscript htune_noise_metrics.R $file.nc $var_ $t1R $t2R $z1_ $z2_ | awk ' { print $2 } '`
	      ;;

      #################################################################
      # case of z-t box averages ("zav")
      # Metrics computed with cdo
      "zav")
      #################################################################
	      z1=`echo $metric_name | awk -F- ' { print $2 } '`
	      z2=`echo $metric_name | awk -F- ' { print $3 } '`
	      met=`echo $metric_name | awk -F- ' { print $4} '`
	   
        rm -f XXXX_intermediate_extract*.nc
        timename=`ncdump -h $file.nc | grep -i time |head -1 | awk ' {print $1 } '`
        # defining a mask in altitude (named "zf" in nc file) between z1 and z2.
	ncap2 -s "mask= (zf >= ${z1} && zf <= ${z2})" ${file}.nc XXXX_intermediate_extract.nc
        #echo "execute ncwa to perform time and z average"
        ncwa -m mask -a ${timename} -d ${timename},${t1},${t2} -v ${met} XXXX_intermediate_extract.nc XXXX_intermediate_extract2.nc
        #echo "execute ncwa to get the only non zero value"
        ncwa -y max XXXX_intermediate_extract2.nc XXXX_intermediate_extract3.nc
        # "put the value in type_metric_value"
        metric=`ncks -v ${met} -c -H XXXX_intermediate_extract3.nc | grep ${met} | grep '=' |  awk ' {print $3}'`
        ;;

      #################################################################
      *) echo Metrics $metric_name not available yet. ; echo 'Want to contribute ?' ; exit 1
      #################################################################

    esac
    echo $metric >> $tmp
    echo $metric
  done
done

####################################################################
# For LES : mean value and error
####################################################################

if [ $prefile = $REF ] ; then
  head=`head -1 $tmp`
  if [ $REF = LES ] ; then
    # Computing the LES mean  
    mean=`sed -n 2p $tmp`
    ################################################################
    # Computing the variance of the metrics from the LES ensemble
    ################################################################
    echo MEAN $mean
    var=`sed -n -e '2,$p' $tmp | awk ' BEGIN { var = 0 ; n=0 } { p = $1 - '$mean' ; var = var + p * p ; n = n + 1 } END { print var / ( n - 1 ) } '`

    ################################################################
    # Specifying "arbitrary" tolerance (max with LES variance retained)
    ################################################################

    case ${metric_name:0:3}  in

      ##############################################################
      # Controling errors on cloud fractions
      # Tolerance specified as a relative error $err_neb
      # or as a realtive errror on cloud fractions $fact_dz_min
      ##############################################################
      "neb") if [ "${metric_name}" = "nebmax" -o "${metric_name}" = "nebdz"  ] ; then fact=$err_neb ; else fact=$fact_dz_min ; fi ; var=`echo $var $mean $fact | awk ' { min=( $2 * $3 ) ^2 ; if ( $1 > min )  { print $1 } else { print min } } '` ;;

      "noi") var=`echo $var $mean $fact_noise | awk ' { min=( $2 * $3 ) ^2 ; if ( $1 > min )  { print $1 } else { print min } } '` ;;

      ##############################################################
      # case of z-t box averages ("zav")
      ##############################################################
      "zav")
      case $met  in
        # On impose que l'erreur sur theta soit au moins 0.1 * THmoy et sur qv 0.0005*qvmoy
        "theta") var=`echo $var $mean | awk ' { min=( '$dtmin' ) ^2 ; if ( $1 > min )  { print $1 } else { print min } } '` ;;
        "qv") var=`echo $var $mean | awk ' { min=( '$dqmin' ) ^2 ; if ( $1 > min )  { print $1 } else { print min } } '` ;;
	      # for wind components and tke, we impose a minimum error of dumin, dvmin dtkemin
	      "u") var=`echo $var $mean | awk ' { min=( '$dumin' ) ^2 ; if ( $1 > min )  { print $1 } else { print min } } '` ;;
	      "v") var=`echo $var $mean | awk ' { min=( '$dvmin' ) ^2 ; if ( $1 > min )  { print $1 } else { print min } } '` ;;
       	"tke") var=`echo $var $mean | awk ' { min=( '$dtkemin' ) ^2 ; if ( $1 > min )  { print $1 } else { print min } } '` ;;
	      # taking the same relativ error $err_neb as for the total cloud fraction
        "rneb") var=`echo $var $mean | awk ' { min=( '$err_neb' * $2 ) ^2 ; if ( $1 > min )  { print $1 } else { print min } } '` ;;
        *) ;;
      esac
    esac
  else # REF IS NOT LES => REF IS RAD
    mean=`sed -n 2p $tmp`

    case ${metric_name:0:3}  in
      "unt"|"abs")
        #there are some missing values for some sza in references files
        if [ $std_dntoa == NaNf ] ; then std_dntoa=0.0 ; echo ON EST PASSE PAR NANF ; fi
        ;;
    esac

    # set MC std, tolerance to error absolute (err) and relative (fact)
    case ${metric_name:0:3}  in
      "lwu") std=$std_lwtoa  ; err=$err_lwtoa  ; fact=$fact_lwtoa  ;;
      "lwd") std=$std_lwsurf ; err=$err_lwsurf ; fact=$fact_lwsurf ;;
      "unt") std=`echo $std_dntoa $std_dnsurf  |awk '{ print $1 + $2 }'` 
             err=$err_unt    ; fact=$fact_unt ;;
      "upt") std=$std_uptoa  ; err=$err_uptoa  ; fact=$fact_uptoa  ;;
      "dns") std=$std_dnsurf ; err=$err_dnsurf ; fact=$fact_dnsurf ;;
      "abs") std=`echo $std_dntoa $std_dnsurf $std_upsurf $std_uptoa | awk '{ print $1 + $2 + $3 + $4 }' `
             err=$err_abs    ; fact=$fact_abs ;;
    esac

    var=`echo $std | awk ' { var=( $1 * $1 ) ; { print var } }'`
    if [ $opt_rad == 1 ] ; then   # absolute tolerance (err)^2
      var=`echo $var $err  | awk ' { min=( $2 ) ^2 ; if ( $1 > min )  { print $1 } else { print min } } '`
    elif [ $opt_rad == 2 ] ; then # relative tolerance (mean*fact)^2
      var=`echo $var $mean $fact  | awk ' { min=( $2 * $3 ) ^2 ; if ( $1 > min )  { print $1 } else { print min } } '`
    fi
  fi
  echo TYPE,$head >| $metric_output_name.csv
  echo MEAN,$mean >> $metric_output_name.csv
  echo VAR,$var >> $metric_output_name.csv
else
  echo SIM > $DIRin/list_simus
  sed -e "s/.nc//" $DIRin/list >> $DIRin/list_simus
  paste -d, $DIRin/list_simus $tmp > $metric_output_name.csv
fi

\cp -f $metric_output_name.csv $DIRin

rm -f XXXX*.nc
rm -f *_metric_value
rm -f list*

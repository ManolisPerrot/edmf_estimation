#!/bin/bash

#####################################################################
# Transforming the physiq.def file that controls the LMDZ physics
# by modifying the value of a subset of parameters randomly
# generated by the htexplo tool
# Author : Frédéric Hourdin
#####################################################################
#. env.sh

list_case=""
input=physiq.def
output=""
model_tbd=ATM
nsub=13

while (($# > 0)) ; do
  #echo OPTION $1 $2
  case $1 in
    -names) names=( `echo $2 | sed -e 's/,/ /g'` ) ; shift ; shift ;;
    -vals) vals=( `echo $2 | sed -e 's/,/ /g'` ) ; shift ; shift ;;
    -input) input=$2 ; shift ; shift ;;
    -model) model_tbd=$2 ; shift ; shift ;;
    -output) output=$2 ; shift ; shift ;;
    -help|-h) echo Usage "$0 -names names -vals vals" ; exit ;;
    *) $0 -help ; exit
  esac
done

#echo names $names
#echo vals $vals

#####################################################################
# starting the loop on simulations
#####################################################################
sim=${vals[0]}
#echo sim $sim

\cp -f $input tmp$$
ip=1
#echo Nombre de variables a changer ${#vals[*]}
# transforming physiq.def to take modified parameter values
while [ $ip -lt ${#vals[*]} ] ; do
   model=ATM
   name_i=${names[$ip]}
   val_i=${vals[$ip]}
   #echo Boucle $name_i $val_i
   if [[ "$name_i" != *"RAD"* ]] ; then
     case $name_i in

	   ath) name=thermals_afact ; val=`grep thermals_fact_epsilon=.*.$ tmp$$ | awk -F= ' { print $2 * '$val_i' } '` ;;
	   A1) name=thermals_afact ; val=$val_i ;;
	   A2) name=thermals_fact_epsilon ; val=$val_i ;;
	   B1) name=thermals_betalpha ; val=$val_i ;;
	   CQ) name=thermals_detr_q_coef ; val=$val_i ;;
	   DZ|DZTH) name=thermals_ed_dz ; val=$val_i ;;
	   FDNTH) name=fact_thermals_down ; val=$val_i ;;
	   CLDLC|CLC) name="cld_lc_lsc cld_lc_con" ; val="$val_i $val_i" ;;
	   CLTAU) name="cld_tau_lsc cld_tau_con" ; val="$val_i $val_i" ;;
	   CLDCV) name=fact_cldcon ; val=$val_i ;;
	   BG1) name=cloudth_sigma1s_factor ; val=$val_i ;;
	   BG2) name=cloudth_sigma2s_factor ; val=$val_i ;;
	   RI) name=rain_int_min ; val=$val_i ;;
	   EVAP) name=coef_eva ; val=$val_i ;;
	   EVAI) name=coef_eva_i ; val=$val_i ;;
	   WDENSO) name=wdens_ref_o ; val=$val_i ;;
	   ALPBLK) name=alp_bl_k ; val=$val_i ;;
	   ALPWKK) name=alpk ; val=$val_i ;;
	   FALLV) name="ffallv_lsc ffallv_con" ; val="$val_i $val_i" ;;
	   RQSB) name=ratqsbas ; val=$val_i ;;
	   RQSH) name=ratqshaut ; val=$val_i ;;
	   RQSP0) name=ratqsp0 ; val=$val_i ;;
	   RQSDP) name=ratqsdp ; val=$val_i ;;
	   RQSTOP) name=ratqshaut ; val=$val_i ;;
	   AERIE) name=bl95_b0 ; val=$val_i ;;
	   OMEPMX|unmepmax) name=epmax ; val=`echo "1. - ${val_i}" | bc -l` ;;
	   SIGDZ) name=sigdz ; val=$val_i ;;
           STRIG) name=s_trig ; val=$val_i ;;
           WKPUP) name=wk_pupper ; val=$val_i ;;
	   WBSRF) name=flag_wb ; val=`echo "$val_i * 100." | bc -l` ;;
	   WBTOP) name=wbmax ; val=$val_i ;;
	   ELCV) name=elcrit ; val=$val_i ;;
	   TLCV) name=tlcrit ; val=$val_i ;;
	   TAUDIV) name=tetagdiv ; val=$val_i ;;
	   TAUROT) name=tetagrot ; val=$val_i ;;
	   TAUTEMP) name=tetatemp ; val=$val_i ;;
	   REI) name="rei_min rei_max" ; val="`echo "$val_i * 16." | bc -l` `echo "$val_i * 61.29" | bc -l`" ;;
           TAU_RWK) name=tau_ratqs_wake  ; val=$val_i ;;
           A_RWK) name=a_ratqs_wake  ; val=$val_i ;;
           GKDRAG) name=sso_gkdrag ; val=$val_i ;;
           PRN) name=atke_pr_neut ; val=$val_i ;;
	   CL) name=atke_clmix ; val=$val_i ;;
           LINF) name=atke_l0 ; val=$val_i ;;
           ALPHAPR) name=atke_pr_slope ; val=$val_i ;;
           RIC) name=atke_ric ; val=$val_i ;;
	   CEPSILON) name=atke_cepsilon ; val=$val_i ;;
           CE) name=atke_cke ; val=$val_i ;;
           SMIN) name=atke_smmin ; val=$val_i ;;
 
# Ocean
           RNALB) name=TBD      ; val=$val_i ; model=OCE ;;
           RNCDN) name=rn_cnd_s ; val=$val_i ; model=OCE ;;
           RNCE)  name=rn_ce    ; val=$val_i ; model=OCE ;;
           RNLC)  name=rn_lc    ; val=$val_i ; model=OCE ;;

# Continents 
           PCENT) name=WETNESS_TRANSPIR_MAX    ; val=$val_i ; for isub in `seq 2 $nsub` ; do val="$val,$val_i" ; done ; model=CONT ;;
           ASNOW) name=TCST_SNOWA ; val=$val_i ; model=CONT ;;

	   *) name=$name_i ; val=$val_i
     esac

     # On passe par des tableaux pour les cas ou on change plusieurs parametres d'un coup
     Names=( $name )
     Vals=( $val )

     if [ "$model" = "$model_tbd" ] ; then
        iv=0
        #echo names ${Names[@]} ${Vals[@]}
        while [ $iv != ${#Names[@]} ] ; do
           Name=${Names[$iv]}
           Val=${Vals[$iv]}
           #echo var $Name $Val $iv
           if [ "`grep $Name $input`" = "" ] ; then
              echo $Name=$Val >> tmp$$
           else
              sed  -e "s/"$Name"=.*.$/"$Name=$Val"/" tmp$$ >|tmp
              mv -f tmp tmp$$
           fi
           (( iv = $iv + 1 ))
        done
     fi
     #echo OK $ip
   fi
   (( ip = $ip + 1 ))
done

if [ "$output" == "" ] ; then
	cat tmp$$
else
	\mv -f tmp$$ $output
fi

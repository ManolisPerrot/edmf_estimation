#!/bin/bash

##################################################################
# Creating plot from the htexplo results
# 1) computes scores for the succesive waves
# 2) plots average and max normalized scores
# 3) plots vertical profiles for the various cases used with
#    best simulations and envelopes
#
# Note :
# 1) and 2) done by post_scores.sh
# 3) done by post.sh that calls plot_scores.py
# Author : Frédéric Hourdin
##################################################################
#. env.sh
# set -vx

export MPLBACKEND='Agg' # To avoid infinitely slow python through ssh


wavemin=1
wavemax=`ls Remaining_space_after_wave_* | cut -d _ -f5 | cut -d. -f1 | sort -n | tail -1`
# wavemax can also be set manually
#wavemax=20
nwave=$(( $wavemax - $wavemin + 1))

##################################################################
# Controle of a sublist for the waves shading on profiles
if [ $wavemax -le 3 ] ; then
  ListWaves=" `seq 1 $wavemax` "
else
  ListWaves=" 1 3 $wavemax "
fi
# could be also set manually
# ListWaves=" 1 3 6 "
# wave_inc=1
# ListWaves=$( seq $wavemin $wave_inc $wavemax )
##################################################################

# Scripts are now running with both python2 and phython3 (no print ...)
#if [ `python -V   2>&1 | awk ' { print $2 } ' | cut -c1` != 2 ] ; then
#        echo You should use python 2 and not 3 ; exit ; fi


###############################################################################
# Some preliminary computations
#------------------------------
#echo $wavemin $wavemax $(seq $wavemin $wavemax) ; exit
for i in $(seq $wavemin $wavemax) ; do
        echo wave $i
	./post_processing_1D.sh $i > out_post_plots$$ 2>&1
done
##############################################################################
# Ranking the SCM simulations according to scores
#------------------------------------------------

# Concatenation of scores for all waves
csvfile=score${wavemin}to${wavemax}.csv
head -1 score$wavemin > $csvfile
for i in $( seq $wavemin $wavemax ) ; do tail -n +2 score$i.csv >> $csvfile ; done

# Sorting simulation on the MAX score (could be MEAN replacing NF by NF-1)
# sort -n to have 1.0 < 10.
awk -F, ' { print  $(NF)","$0 } ' $csvfile | sort -n >| opt_scores.csv

# Names of the 10 best
simss=`tail -n +2 opt_scores.csv | head -10 opt_scores.csv | awk -F, ' { print $2 } '`
echo les 10 meilleures simulations sont : 
echo $simss
head -1 WAVE$wavemax/Par*asc >| params_opt.csv
for sim in $simss ; do
        grep $sim */Par*asc >> params_opt.csv
done

iname=0

#############################################################################
# Loop on the best 10 simulations according to the above ranking
#---------------------------------------------------------------
# in case simulations labeled with RADXXX
simss=`echo $simss | sed -e 's/RAD.../SCM/g'`

for sims in "$simss" $simss  ; do
echo $sims
cat <<eod>| simus.py
#-*- coding:UTF-8 -*-
# files that define the lists of the simulations you want to draw and also define information of the profiles
# time of the profile, color/style of the lines, xmin/xmax, ymin/ymax ranges)
from datetime import datetime

DIRDATA='./'

nomvar='theta'

# couleurs des courbes
#---------------------
# cycle de couleurs
listcoul=['black','red','green','fuchsia','blue','lime','darkviolet','cyan','darkorange','slateblue','brown','gold']

# exemple dictionnaire de couleurs en fonction du nom de fichier (sans le prefixe time_ ou prof_)
#black=reference; blue=bb; violet=turb, orange=pas de temps, Diffusion=vert, resolution=grey, advection=red, resv=brown,domain= microphysique=turquoise
dicocoul={\\
'SCM.nc' : 'black',\\
'LES0.nc' : 'slateblue',\\
'LES1.nc' : 'blue',\\
'LES2.nc' : 'blue',\\
'LES3.nc' : 'blue',\\
'LES4.nc' : 'blue',\\
'LES5.nc' : 'blue',\\
'LES6.nc' : 'blue',\\
'LES7.nc' : 'blue',\\
'LES8.nc' : 'blue',\\
eod

cols=( red green fuchsia lime darkviolet cyan darkorange slateblue brown gold )
ii=0
for sim in $sims ; do
cat <<eod>> simus.py
'$sim.nc' : '${cols[$ii]}',\\
eod
(( ii = $ii + 1 ))
done
cat <<eod>> simus.py
}

dicostyl={\\
'SCM.nc' : '-',\\
'LES0.nc' : '-',\\
'LES1.nc' : '-.',\\
'LES2.nc' : '-.',\\
'LES3.nc' : '-.',\\
'LES4.nc' : '-.',\\
'LES5.nc' : '-.',\\
'LES6.nc' : '-.',\\
'LES7.nc' : '-.',\\
'LES8.nc' : '-.',\\
eod

for sim in $sims ; do
cat <<eod>> simus.py
'$sim.nc' : '-',\\
eod
done

wave_ens=1
cat <<eod>> simus.py
}

# listcoul ou dicocoul ou dicohightune ou ...
#coul1d=listcoul
styl1d=dicostyl
coul1d=dicocoul

# liste des fichiers sélectionnés
listfic=[\\
'LES/'+Case+'/'+SubCase+'/LES0.nc',\\
'LES/'+Case+'/'+SubCase+'/LES1.nc',\\
'LES/'+Case+'/'+SubCase+'/LES2.nc',\\
'LES/'+Case+'/'+SubCase+'/LES3.nc',\\
'LES/'+Case+'/'+SubCase+'/LES4.nc',\\
'LES/'+Case+'/'+SubCase+'/LES6.nc',\\
'LES/'+Case+'/'+SubCase+'/LES7.nc',\\
'LES/'+Case+'/'+SubCase+'/LES8.nc',\\
eod



for sim in $sims ; do
w=`echo $sim | cut -d\- -f2`
echo $sim $w
cat <<eod>> simus.py
'WAVE$w/'+Case+'/'+SubCase+'/$sim.nc',\\
eod
done

cat <<eod>> simus.py
'CTRL/'+Case+'/'+SubCase+'/SCM.nc',\\
]
eod

echo 'list_ens=[\'  >> simus.py
for wave_ens in $ListWaves ; do
cat <<eod>> simus.py
'WAVE$wave_ens/'+Case+'/'+SubCase,\\
eod
done
echo ']'  >> simus.py
./post.sh
mv t.pdf Prof$iname.pdf
mkdir -p PROFILES_${wavemax}/BEST$iname
mv profil*  PROFILES_${wavemax}/BEST$iname
mv serie*.png  PROFILES_${wavemax}/BEST$iname
mv scatter*.png  PROFILES_${wavemax}/BEST$iname
(( iname = $iname + 1 ))
done
exit

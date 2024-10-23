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

ListWaves="-"
var=$1
sims="SCM-3-001 SCM-3-002"
ListWaves="1 2 3"

echo $sims

cat <<eod>| simus.py
#-*- coding:UTF-8 -*-
# files that define the lists of the simulations you want to draw and also define information of the profiles
# time of the profile, color/style of the lines, xmin/xmax, ymin/ymax ranges)
from datetime import datetime

DIRDATA='./'

#nomvar='theta'

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

if [ "$ListWaves" != "-" ] ; then
   echo 'list_ens=[\'  >> simus.py
   for wave_ens in $ListWaves ; do
   cat <<...eod>> simus.py
   'WAVE$wave_ens/'+Case+'/'+SubCase,\\
...eod
   done
   echo ']'  >> simus.py
fi

python trace_sens_LES.py $var $cas $sub

##############################################################
# Ce script plot la diminution de la taille du NROY
# au fur et a mesure des vagues
# 
# Arguments à renseigner par l'utilisateur : 
# WAVEN : numero de la vague final
# tab_cutoff : numero des vagues ou le cutoff change
# val_cutoff : valeur des cutoff correspondant
# ymin et ymax : bornes du graphique
#
# Script : 
# 1. commence a concatener les fichiers Remaining_space_after_wave_$i.txt
#    pour creer NROY_fraction_w1to'+str(WAVEN)+'.txt'
# 2. fait le tracé
#
# Maelle Coulon--Decorzens juin 2022
##############################################################

import numpy as np
import matplotlib.pyplot as plt
import os

#arguments à renseigner par l'utilisateur
WAVEN=40 #numero de la vague finale
tab_cutoff=[1,5,8]  #numero de vague ou le cutoff change
val_cutoff=[3,2.5,2] #valeur du cutoff
ymin=0.01
ymax=1


# concatenation des fichiers
name_file='NROY_fraction_w1to'+str(WAVEN)+'.txt'

os.system("if [ ! -f "+name_file+" ] ; then for i in `seq 1 "+str(WAVEN)+"` ; do NROY=`cat Remaining_space_after_wave_$i.txt` ; echo $NROY >> "+name_file+" ; done ; fi")

tab_NROY=np.loadtxt(name_file)
name_fig="plot_NROY_fraction_w1to"+str(WAVEN)+".png"

# tracé
pointille=['dashdot', 'dashed', 'dotted']
vagues=np.arange(1,WAVEN+1)
fig=plt.figure()
plt.yscale("log", basey=10)
plt.plot(vagues,tab_NROY)
for i in range(len(tab_cutoff)) :
    plt.vlines(tab_cutoff[i], ymin ,ymax, label='cutoff = '+str(val_cutoff[i]), ls=pointille[i], color='grey')
plt.ylim(ymin,ymax)
plt.grid(axis='y', which='minor', color="#d7d7d7")
plt.xlabel('numero de la vague')
plt.ylabel('fraction du NROY')
plt.legend()
plt.savefig(name_fig)
print('figure enregistree sous : '+name_fig)

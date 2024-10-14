
import os
import sys
import matplotlib as mpl
# "backend" pour sortie fichier uniquement
mpl.use('agg')
import matplotlib.pyplot as plt
import numpy as np
from matplotlib import dates
from datetime import datetime
from datetime import timedelta
import netCDF4 as nc4
import matplotlib.ticker as ticker
import matplotlib.cm as cm
import itertools
import util_hightune as util
from dicocoul import *
import copy
import pandas as pd
import dico_metrad as dic

list_ens=[]
list_ens_RAD=[]
if len(sys.argv) >= 7:
    Case=sys.argv[2]
    SubCase=sys.argv[3]
    Hour=sys.argv[4]
    sza=sys.argv[5]
    met=sys.argv[6]
else:
    print("this script need 6 arguments : name var, Case, Subcase, Hour of ECRAD file (without 0), sza and metric")
    sys.exit()

opt=1 #option pour tracer le rayonnement sur le profil LES

nompar='param_'+Case+'_'+SubCase+'.py'

case=nompar.split('_')[1].split('.')[0]
subcas=nompar.split('_')[2].split('.')[0]
cas=case+'_'+subcas

dicoglob=globals()
dicosimu=globals()

exec(open("./"+nompar).read(),dicoglob)
exec(open("./simus.py").read(),dicosimu)

nbfic=len(listfic)

dico_vmin_met,dico_vmax_met,dico_vmin_cc,dico_vmax_cc=dic.fct_dico()
nomvar=sys.argv[1]
if ((str(nomvar) not in vmintab) | (str(nomvar) not in vmaxtab)) :
    print("add values for variable "+str(nomvar)+" in "+nompar+ " vmintab et vmaxtab dictionnaries")
    print("stop the programm")
    sys.exit()
else : 
    vmin=dico_vmin_cc[met]
    vmax=dico_vmax_cc[met]
#print("vmin = ", vmin, "vmax = ", vmax)
vmin_met=dico_vmin_met[met]
vmax_met=dico_vmax_met[met]

#déclaration des dictionnaires
dicofic={}      # accès à toutes les données en fonction du nom de fichier
dico_SCM={}     # accès à cc des SCM
dico_RAD={}     # accès à cc des RAD
dico_met={}

i_time=int(Hour)-1 #indice de temps pour les couverture nuageuses des SCM
if(int(Hour)<10):
    Hour="00"+str(Hour)
elif(int(Hour)<100):
    Hour="0"+str(Hour)

#tout est fait "à la main"
if ( opt == 1 ) :
    path_res="/data/mcoulon/01_RAYT-CLOUD_COMPENSATION/NPV6.3_round3/PROF_LES/OUT_ECRAD/"
    nam=sys.argv[7]
    name_file=Case+"_RAD"+Hour+"_"+nam+".nc"
    file_target=nc4.Dataset(path_res+name_file, 'r')
    cc_target=file_target.variables['cloud_cover_sw'][0]


# Creation d'une liste etendue pour ajouter les min et max des ensembles
listfic=listfic+["WAVE1/metrics_REF_1.csv"]
list_int=copy.deepcopy(listfic)

for nomfic in list_ens:
    list_int.append(nomfic+'/ensmin.nc')
    list_int.append(nomfic+'/ensmax.nc')
    list_ens_RAD.append((nomfic+'/ensmin_RAD'+Hour+'.nc'))
    list_ens_RAD.append((nomfic+'/ensmax_RAD'+Hour+'.nc'))
    list_int.append(nomfic+'/ensmin_RAD'+Hour+'.nc')
    list_int.append(nomfic+'/ensmax_RAD'+Hour+'.nc')

listficext=[]
#for nomfic in list_int : 
#    if ("LES" not in nomfic) : 
#        listficext=listficext+[nomfic]
#    elif("LES" in nomfic) :
#        listfic.remove(nomfic)

#for nomfic in list_int : 
#    if (("LES" not in nomfic) & (nomvar!='cc')) : 
#        listficext=listficext+[nomfic]
#    elif(("LES" in nomfic) & (nomvar!='cc')) :
#        listfic.remove(nomfic)
#    elif(nomvar=='cc') : 
#        listficext=listficext+[nomfic]


for nomfic in list_int :
    if ("LES" not in nomfic) :
        listficext=listficext+[nomfic]
    elif("LES0" in nomfic) :
        listficext=listficext+[nomfic]

listficext=listficext+["WAVE1/metrics_REF_1.csv"]
###########################################################
#              Préparation des données                    #
###########################################################


for nomfic in listficext:
    #print( "nonfic", nomfic )
    # fichier netcdf
    #print(nomfic)
    if("RAD" not in nomfic) :
        if("LES0" in nomfic) : #LES
            print(" ####### LES0 : cc + metrique #######")
            dico_RAD[nomfic]=cc_target
            nomficmet="metrics_LES_"+nam+".csv"
            print(nomficmet)
            fic_csv=pd.read_csv(nomficmet)
            nommet="RAD_RAD_"+met
            dico_met[nomfic]=fic_csv[nommet][0]
            print(dico_met[nomfic])
        elif("SCM-" in nomfic) : #bests simus
            #print("DANS SCM cc + metrique")
            #print("SCM- in ", nomfic)
            #on recupere la cc de ECRAD dans dico_RAD :
            nomfic_split=nomfic.split('/')
            nomficRad=nomfic_split[-1]
            nomficRad=nomfic_split[0]+"/"+nomfic_split[1]+"/"+nomfic_split[2]+"/"+"RAD"+str(Hour)+nomficRad[3::]
            ficRad=nc4.Dataset(DIRDATA+nomficRad, 'r')
            dico_RAD[nomfic]=ficRad.variables['cloud_cover_sw'][0]

            #on recupère la valeure de la métrique dans dico_met
            wave=nomfic.split('/')[0]
            nomficmet=wave+'/metrics_'+wave+'_'+wave.replace("WAVE","")+'.csv'
            fic_csv=pd.read_csv(nomficmet)
            nommet=wave+'_RAD_'+met
            i_sim=int(nomfic.split('/')[3].split('-')[2].replace('.nc', ""))-1
            dico_met[nomfic]=fic_csv[nommet][i_sim]
            #print("dico_met :", dico_met[nomfic])
            #dico_met[nomfic]=pd.
        elif("metrics_REF" in nomfic) :
            #print("REF MET")
            fic_csv=pd.read_csv(nomfic)
            nommet="RAD_RAD_"+met
            #print("name fic = ", nomfic+"_MEAN")
            dico_met[nomfic+"_MEAN"]=fic_csv[nommet][0] #moyenne
            dico_met[nomfic+"_SQRT"]=np.sqrt(fic_csv[nommet][1]) #ecart-type
        elif("ens" in nomfic) :
            #print("ENS")
            wave=nomfic.split('/')[0]
            nomficmet=wave+'/metrics_'+wave+'_'+wave.replace("WAVE","")+'.csv'
            fic_csv=fic_csv=pd.read_csv(nomficmet)
            nommet=wave+'_RAD_'+met
            if("min" in nomfic) :
                dico_met[nomfic]=np.min(fic_csv[nommet])
            elif("max" in nomfic) :
                dico_met[nomfic]=np.max(fic_csv[nommet])




    else : #RAD is in nomfic : ensemble de cloud cover ECRAD
        #print("cc")
        ficRad=nc4.Dataset(nomfic, 'r')
        dico_RAD[nomfic]=ficRad.variables['cloud_cover_sw'][0]



del dicofic

print("!!!!!!!!!!! FIN CHARGEMENT DONNEES")
#sys.exit()
###########################################################
#                        PLOT                             #
###########################################################

figtitre="scatter_metriques_vs_"+nomvar+"_"+met+".png"

#creation de la figure
fig=plt.figure(figsize=(6,8))
fig.subplots_adjust(left=.15,right=.90,top=.9,bottom=0.40)
ax=fig.add_subplot(111)

# titre 
plottitle=Case+" "+SubCase+" "+str(Hour)
fig.suptitle(plottitle,fontsize=12.,x=0.52,y=.95,horizontalalignment='center')
#titre axe y
ax.set_ylabel(met, fontsize=12.)
#titre axe x
#if(nomvar=='cc') :
#    xlabel="Cloud cover as max(rneb)"
#else : 
#    xlabel="Cloud cover as "+nomvar

ax.set_xlabel("Cloud cover seen by ECRAD", fontsize=12.)

ax.set_xlim(vmin,vmax)
ax.set_ylim(vmin_met,vmax_met)

# on eleve la couleure noire qui correspond à la simu de controle, qu'on a pas traitée ici
if "black" in listcoul : 
    listcoul.remove('black')
#on enlève blue (je sais pas pourquoi ça marche pas)
if "blue" in listcoul : 
    listcoul.remove('blue')
#print(listcoul)
colors = itertools.cycle(listcoul)

for nomfic in listfic :
    #print("nomfic = ", nomfic)
    if ("CTRL" not in nomfic) : 
        style_courbe="-"
        largeur_ligne=2.
        petitnom=(nomfic.rsplit('/',1))[1].replace("min.nc","").replace("max.nc","")
        zlabel=(nomfic.rsplit('/',1))[1].replace(".nc", "")
        #print("petit nom = ", petitnom)
        #if (coul1d == listcoul):
        #    ax.scatter(dico_SCM[nomfic],dico_RAD[nomfic], marker='x', color=next(colors), label=zlabel)
        if petitnom != 'ens' : 
            try : 
                nomcoul=coul1d[util.basefic(nomfic)]
                stylcoul=styl1d[util.basefic(nomfic)]
            except KeyError:
                nomcoul='grey'
        
            xlinewidth=10
            if("LES0" in nomfic) : 
              xlinewidth=200
              xlabel="LES0 met = "+str(round(dico_met[nomfic]*10)/10)
              nomcoul='k'
            else : 
              xlinewidth=100
              stylcoul='-'
              if("LES1" in nomfic) : 
                  xlabel="LES ensemble"
              else :
                  xlabel=""
            if "LES0" in nomfic : 
                ax.scatter(dico_RAD[nomfic],dico_met[nomfic], zorder=20, clip_on=False, s=xlinewidth, color=nomcoul, label=xlabel,marker='x')
                ax.vlines(dico_RAD[nomfic],vmin_met, ymax=vmax_met, zorder=20, clip_on=False, color=nomcoul, lw=1)
            elif "SCM-" in nomfic  : 
                ax.scatter(dico_RAD[nomfic],dico_met[nomfic], marker='x', color=next(colors), label=zlabel, zorder=10)
            elif "metrics_REF" in nomfic : 
                #print("dans metrics REF")
                #REF MET MC : 
                ax.hlines(dico_met[nomfic+"_MEAN"],xmin=vmin, xmax=vmax, zorder=10, clip_on=False, color='b', lw=1, label="REF = "+str(round(10*dico_met[nomfic+"_MEAN"])/10))
                ax.hlines(dico_met[nomfic+"_MEAN"]+dico_met[nomfic+"_SQRT"],xmin=vmin, xmax=vmax, zorder=10, clip_on=False, color='b', lw=1, ls='--', label="REF + ou - sigma")
                ax.hlines(dico_met[nomfic+"_MEAN"]-dico_met[nomfic+"_SQRT"],xmin=vmin, xmax=vmax, zorder=10, clip_on=False, color='b', lw=1, ls='--')
                ax.hlines(dico_met[nomfic+"_MEAN"]+3*dico_met[nomfic+"_SQRT"],xmin=vmin, xmax=vmax, zorder=10, clip_on=False, color='b', lw=0.5, ls='--', label="REF +ou - 3.sigma")
                ax.hlines(dico_met[nomfic+"_MEAN"]-3*dico_met[nomfic+"_SQRT"],xmin=vmin, xmax=vmax, zorder=10, clip_on=False, color='b', lw=0.5, ls='--')


if(list_ens) : 
    ens_shades=['lightgrey','mistyrose','lemonchiffon','palegreen','paleturquoise']
    ens_lines_col=[ 'grey', 'lightcoral', 'orange', 'chartreuse', 'turquoise']
    icol_ens=0
    zorder=10
    for ens in list_ens : 
        #print("ens = ", ens)
        #plot MET ensemble
        #print("ensmin et ensmax sur vmin = ", vmin)
        ax.plot([vmin,vmin], [dico_met[ens+'/ensmin.nc'], dico_met[ens+'/ensmax.nc']], label=ens.split('/')[0], zorder=zorder, clip_on=False, color=ens_lines_col[icol_ens])
        ax.scatter(vmin, dico_met[ens+'/ensmin.nc'], clip_on=False, marker="_", color=ens_lines_col[icol_ens], s=200, lw=2)
        ax.scatter(vmin, dico_met[ens+'/ensmax.nc'], clip_on=False, marker="_", color=ens_lines_col[icol_ens], s=200, lw=2)

        #plot RAD ensemble
        radname=(list_ens_RAD[icol_ens].rsplit('/',1))[1].rsplit('_',1)[1]
        #print("ensemin_"+radname+" et ensmax sur vmin_met = ", vmin_met)
        ax.plot([dico_RAD[ens+'/ensmin_'+radname], dico_RAD[ens+'/ensmax_'+radname]], [vmin_met,vmin_met], zorder=zorder, clip_on=False, color=ens_lines_col[icol_ens])
        ax.scatter(dico_RAD[ens+'/ensmin_'+radname], vmin_met, clip_on=False, marker="|", color=ens_lines_col[icol_ens], s=200, lw=2)
        ax.scatter(dico_RAD[ens+'/ensmax_'+radname], vmin_met, clip_on=False, marker="|", color=ens_lines_col[icol_ens], s=200, lw=2)
        zorder=zorder+1
        icol_ens+=1


#if (opt == 1) :
#    ax.scatter(vmin, cc_target, clip_on=False, marker='x', color='k', s=200, lw=2)

# on trace la ligne y=x
x=np.linspace(vmin,vmax,num=10)
y=np.linspace(vmin,vmax,num=10)
ax.plot(x,y,lw=0.5,color='k')

#mise en forme
ax.xaxis.set_major_locator(ticker.MaxNLocator())
ax.xaxis.set_minor_locator(ticker.AutoMinorLocator())
ax.yaxis.set_major_locator(ticker.MaxNLocator())
ax.yaxis.set_minor_locator(ticker.AutoMinorLocator())
y_majorfmt=ticker.ScalarFormatter(useMathText=True)
ax.yaxis.set_major_formatter(y_majorfmt)
ax.yaxis.set_tick_params(which='both',direction='out')
ax.grid(True)
nbcol=2
ax.legend(bbox_to_anchor=(-0.13, -0.15),loc='upper left',ncol=nbcol,fontsize=10.,labelspacing=.3,numpoints=2,markerscale=1.,handlelength=2.,frameon=False)


print(figtitre)
plt.savefig(figtitre)




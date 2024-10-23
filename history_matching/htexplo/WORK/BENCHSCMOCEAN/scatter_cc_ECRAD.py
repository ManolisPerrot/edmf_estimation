
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

list_ens=[]
list_ens_RAD=[]
if len(sys.argv) == 5:
    Case=sys.argv[2]
    SubCase=sys.argv[3]
    Hour=sys.argv[4]
else:
    print("scatter_sens_LES.py need 4 arguments : name var, Case, Subcase and Hour of ECRAD file (without 0)")
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

nomvar=sys.argv[1]
if ((str(nomvar) not in vmintab) | (str(nomvar) not in vmaxtab)) :
    print("add values for variable "+str(nomvar)+" in "+nompar+ " vmintab et vmaxtab dictionnaries")
    print("stop the programm")
    sys.exit()
else : 
    vmin=vmintab[nomvar]
    vmax=vmaxtab[nomvar]

#déclaration des dictionnaires
dicofic={}      # accès à toutes les données en fonction du nom de fichier
dico_SCM={}     # accès à cc des SCM
dico_RAD={}     # accès à cc des RAD

i_time=int(Hour)-1 #indice de temps pour les couverture nuageuses des SCM
if(int(Hour)<10):
    Hour="00"+str(Hour)
elif(int(Hour)<100):
    Hour="0"+str(Hour)

#tout est fait "à la main"
if ( opt == 1 ) :
    path_res="/data/mcoulon/01_RAYT-CLOUD_COMPENSATION/NPV6.3_round3/PROF_LES/OUT_ECRAD/"
    nam="config_spartacus_glob"
    name_file=Case+"_RAD"+Hour+"_"+nam+".nc"
    file_target=nc4.Dataset(path_res+name_file, 'r')
    cc_target=file_target.variables['cloud_cover_sw'][0]

# Creation d'une liste etendue pour ajouter les min et max des ensembles
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

for nomfic in list_int : 
    if (("LES" not in nomfic) & (nomvar!='cc')) : 
        listficext=listficext+[nomfic]
    elif(("LES" in nomfic) & (nomvar!='cc')) :
        listfic.remove(nomfic)
    elif(nomvar=='cc') : 
        listficext=listficext+[nomfic]

###########################################################
#              Préparation des données                    #
###########################################################


for nomfic in listficext:
    #print( "nonfic", nomfic )
    # fichier netcdf
    print(nomfic)
    try:
        dicofic[nomfic]= nc4.Dataset(DIRDATA+nomfic,'r')
        ficok=True
    except:
        ficok=False
    if ( (ficok) & ("RAD" not in nomfic) ):
        dico_SCM[nomfic]=dicofic[nomfic].variables[nomvar][i_time][0][0]
        if("SCM-" in nomfic) :
            #print("SCM- in ", nomfic)
            nomfic_split=nomfic.split('/')
            nomficRad=nomfic_split[-1]
            nomficRad=nomfic_split[0]+"/"+nomfic_split[1]+"/"+nomfic_split[2]+"/"+"RAD"+str(Hour)+nomficRad[3::]
            ficRad=nc4.Dataset(DIRDATA+nomficRad, 'r')
            dico_RAD[nomfic]=ficRad.variables['cloud_cover_sw'][0]
    elif( (ficok) & ("RAD" in nomfic) ) :
        ficRad=nc4.Dataset(nomfic, 'r')
        dico_RAD[nomfic]=ficRad.variables['cloud_cover_sw'][0]

del dicofic
###########################################################
#                        PLOT                             #
###########################################################

figtitre="scatter_"+Case+"_"+SubCase+"_"+str(Hour)+"_"+nomvar+".png"

#creation de la figure
fig=plt.figure(figsize=(6,8))
fig.subplots_adjust(left=.15,right=.90,top=.9,bottom=0.40)
ax=fig.add_subplot(111)

# titre 
plottitle=Case+" "+SubCase+" "+str(Hour)
fig.suptitle(plottitle,fontsize=12.,x=0.52,y=.95,horizontalalignment='center')
#titre axe y
ax.set_ylabel("Cloud cover seen by ECRAD", fontsize=12.)
#titre axe x
if(nomvar=='cc') :
    xlabel="Cloud cover as max(rneb)"
else : 
    xlabel="Cloud cover as "+nomvar

ax.set_xlabel(xlabel, fontsize=12.)

ax.set_xlim(vmin,vmax)
ax.set_ylim(vmin,vmax)

# on eleve la couleure noire qui correspond à la simu de controle, qu'on a pas traitée ici
if "black" in listcoul : 
    listcoul.remove('black')
#on enlève blue (je sais pas pourquoi ça marche pas)
if "blue" in listcoul : 
    listcoul.remove('blue')
#print(listcoul)
colors = itertools.cycle(listcoul)

for nomfic in listfic :
    if ("CTRL" not in nomfic) : 
        style_courbe="-"
        largeur_ligne=2.
        petitnom=(nomfic.rsplit('/',1))[1].replace("min.nc","").replace("max.nc","")
        zlabel=(nomfic.rsplit('/',1))[1].replace(".nc", "")
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
              xlabel="LES0"
              nomcoul='k'
            else : 
              xlinewidth=100
              stylcoul='-'
              if("LES1" in nomfic) : 
                  xlabel="LES ensemble"
              else :
                  xlabel=""
            if "LES" in nomfic : 
                ax.scatter(dico_SCM[nomfic],vmin, zorder=20, clip_on=False, s=xlinewidth, color=nomcoul, label=xlabel,marker='x')
            elif "SCM-" in nomfic  : 
                ax.scatter(dico_SCM[nomfic],dico_RAD[nomfic], marker='x', color=next(colors), label=zlabel, zorder=10)

if(list_ens) : 
    ens_shades=['lightgrey','mistyrose','lemonchiffon','palegreen','paleturquoise']
    ens_lines_col=[ 'grey', 'lightcoral', 'orange', 'chartreuse', 'turquoise']
    icol_ens=0
    zorder=10
    for ens in list_ens : 
        #print("ens = ", ens)
        #plot SCM ensemble
        ax.plot([dico_SCM[ens+'/ensmin.nc'], dico_SCM[ens+'/ensmax.nc']], [vmin, vmin], label=ens.split('/')[0], zorder=zorder, clip_on=False, color=ens_lines_col[icol_ens])
        ax.scatter(dico_SCM[ens+'/ensmin.nc'], vmin, clip_on=False, marker="|", color=ens_lines_col[icol_ens], s=200, lw=2)
        ax.scatter(dico_SCM[ens+'/ensmax.nc'], vmin, clip_on=False, marker="|", color=ens_lines_col[icol_ens], s=200, lw=2)
        #plot RAD ensemble
        radname=(list_ens_RAD[icol_ens].rsplit('/',1))[1].rsplit('_',1)[1]
        ax.plot([vmin, vmin], [dico_RAD[ens+'/ensmin_'+radname], dico_RAD[ens+'/ensmax_'+radname]], zorder=zorder, clip_on=False, color=ens_lines_col[icol_ens])
        ax.scatter(vmin, dico_RAD[ens+'/ensmin_'+radname], clip_on=False, marker="_", color=ens_lines_col[icol_ens], s=200, lw=2)
        ax.scatter(vmin, dico_RAD[ens+'/ensmax_'+radname], clip_on=False, marker="_", color=ens_lines_col[icol_ens], s=200, lw=2)
        zorder=zorder+1
        icol_ens+=1

if (opt == 1) :
    ax.scatter(vmin, cc_target, clip_on=False, marker='x', color='k', s=200, lw=2)

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




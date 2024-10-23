#-*- coding:UTF-8 -*-
# fichiers high-tune : draw a vertical profile at a given time of LES, the ensemble of SCM runs and the default SCM run
# Adapted to plot time series (M Coulon--Decorzens - august 2023) :
#   - an automatic test is made on the variable to know if its vertical profile (is_prof=1) or not (is_prof=0)
#   - code specific to vertical profils has not been modified at all, is just executed if is_prof=1
#   - code specific to time series are added if is_prof=0
# Authors: F Favot, F Couvreux
# use module netCDF4 
#####################################################################################################################

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
import matplotlib.dates as mdates
import matplotlib.cm as cm
import itertools
import util_hightune as util
from dicocoul import *

# recup nom image output en argument 
#if len(sys.argv) > 1:
#    nomimg=sys.argv[1]
#else:
#    nomimg='profil_Ayotte_A24SC_14h.png'
#  variables récupérées dans param_tmp :
# DIRDATA : répertoire des fichiers
# listfic : liste des fichiers
# nomvar  : variable à tracer
# dateprof : date du profil 
# axevert  : axe vertical 'z' ou 'p'
# vmin    : valeur min
# vmax    : valeur max
# moyt    : optionnel, pas de temps en heure, pour profil moyen de (dateprof - moyt/2.) à (dateprof + moyt/2.)
# listcoul : liste de couleurs
# dicocoul : dictionnaire de couleur par nom de fichier
# coul1d   : listcoul ou dicocoul ou dicohightune ou ...
list_ens=[]
if len(sys.argv) > 2:
    Case=sys.argv[2]
    SubCase=sys.argv[3]
else:
    nompar='param_new.py'

nompar='param_'+Case+'_'+SubCase+'.py'

case=nompar.split('_')[1].split('.')[0]
subcas=nompar.split('_')[2].split('.')[0]
cas=case+'_'+subcas


dicoglob=globals()
dicosimu=globals()

# print( "NOMPAR", nompar)
exec(open("./"+nompar).read(),dicoglob)
exec(open("./simus.py").read(),dicosimu)
# print( "LLL", nompar)
#vmin=dicoglob.get('vmin',None)
#vmax=dicoglob.get('vmax',None)
#vdelta=dicoglob.get('vdelta',None)
zmin=dicoglob.get('zmin',None)
zmax=dicoglob.get('zmax',None)
moyt=dicoglob.get('moyt',None)
#niv=dicoglob.get('niv',None)
nbfic=len(listfic)
# print( globals())
if len(sys.argv) > 1:
    nomvar=sys.argv[1]
    if ((str(nomvar) not in vmintab) | (str(nomvar) not in vmaxtab)) :
        print("add values for variable "+str(nomvar)+" in "+nompar+ " vmintab et vmaxtab dictionnaries")
        print("stop the programm")
        sys.exit()
    else :
        vmin=vmintab[nomvar]
        vmax=vmaxtab[nomvar]
else:
    print("trace_sens_LES.py needs one argument at least, the variable name")
    exit()


is_prof=1 
bug=0

# print((nomvar))
# init
dicofic={}      # accès à toutes les données en fonction du nom de fichier
dicovar={}      # accès à la variable demandée    "           "       "
dicochamp={}    # champs à tracer 
#diconiv={}                "           "       "
dicoalti={}     # altitudes 
dicodate={}     # dates des données du profil : "datepp" : date la plus proche de dateprof
#               et si profil moyen : "dateinf" et "datesup" : dates les plus proches de dateprof +/- moyt/2
titrefig=False  # booléens pour le titre et les unités du graphique :
unitfig=False   # les éléments sont récupérés dans le 1er fichier qui a les attributs
unitz=False     # recherchés : long_name, units de la variable, units de la variable verticale
time_axes={}    # needed to plot time series only


# Creation d'une liste etendue pour ajouter les min et max des ensembles
listficext=listfic
# print( 'LISTE ETENDUE ',listficext)
for nomfic in list_ens:
    listficext.append(nomfic+'/ensmin.nc')
    listficext.append(nomfic+'/ensmax.nc')

#-----------------------------------
# boucle sur les fichiers de listfic
#-----------------------------------
for nomfic in listficext:
    #print( "nonfic", nomfic )
    # fichier netcdf
    try:
        dicofic[nomfic]= nc4.Dataset(DIRDATA+nomfic,'r')
        ficok=True
    #except RuntimeError:
    except:
        ficok=False
        # print( "<p>WARNING: erreur ouverture fichier %s</p>" % (nomfic))
    # liste des variables du fichier
    # print( dicofic[nomfic].variables.keys())
    if ( ficok ):
        mesg=[]
        if (util.data_pourprofil(dicofic[nomfic],nomvar,axevert,mesg) ):
            # probleme de données pour le tracé du profil
            # print( "<p>WARNING, le fichier %s :  %s</p>" % (nomfic,mesg[0]))
            is_prof=1
            bug=0
        elif (util.data_pourserietempo(dicofic[nomfic],nomvar,axevert,mesg)):
            is_prof=0
            bug=0
        else : 
            is_prof=2
            bug=1
            print("data problem in fic "+nomfic, mesg, )
        if (bug==0) : 
            # donnees ok
            dicovar[nomfic]=dicofic[nomfic].variables[nomvar]

            # titre du champ
            if ( not titrefig ):
                long_name=util.titre_champ(dicofic[nomfic],nomvar)
                titrefig=True
            # unité du champ
            if ( not unitfig ):
                unit_champ=util.unit_champ(dicofic[nomfic],nomvar)
                if unit_champ:
                    unitfig=True

            # time du fichier
            time=dicofic[nomfic].variables['time']
            if hasattr(time,'calendar'):
                calendrier=time.calendar
            else:
                calendrier='standard'
            # dateprof en num dans l'unité du fichier
            timeprof=nc4.date2num(dateprof,time.units,calendar=calendrier)
            # date la plus proche de dateprof
            indtimepp=util.ind_plusproche(time[:],timeprof)
            datepp=nc4.num2date(time[indtimepp],time.units,calendar=calendrier)
            dicodate[nomfic]={"datepp": datepp}

            # warning si time[indtimepp] est éloignée de timeprof (delta_timeprof en secondes)
            delta_timeprof=abs(timeprof-time[indtimepp])
            if delta_timeprof > 3600:
                # print( '<p>WARNING : ',nomfic,' date la plus proche : ',datepp,'</p>')
                bug=1

            if(is_prof==0) :
                time_series=nc4.num2date(time[:],time.units,calendar=calendrier)
                time_bis=[ x for x in time_series if x < datefin ]
                #time_axes[nomfic]=[ x.strftime('%d-%H')+":30" for x in time_bis]
                time_axes[nomfic]=[datetime.strptime(x.strftime('%Y-%m-%d %H:%M:%S'),'%Y-%m-%d %H:%M:%S') for x in time_bis]

            # si moyt initialisé
            moytok=util.is_init(moyt)
            if moytok:
                # dateprof +/- moyt/2 en num dans l'unité du fichier
                timeinf=nc4.date2num(dateprof - timedelta(hours=moyt/2.),time.units,calendar=calendrier)
                timesup=nc4.date2num(dateprof + timedelta(hours=moyt/2.),time.units,calendar=calendrier)
                # print( 'timeinf=',timeinf,' timesup=',timesup)
                # indices les plus proche de timeinf et timesup
                indtimeinfpp=util.ind_plusproche(time[:],timeinf)
                indtimesuppp=util.ind_plusproche(time[:],timesup)
                # print( 'calendrier=',calendrier,' indtimeinfpp=',indtimeinfpp,' indtimepp=',indtimepp,' indtimesuppp=',indtimesuppp)
                # on conserve dans le dictionnaire les dates correspondantes
                dicodate[nomfic]["dateinf"]=nc4.num2date(time[indtimeinfpp],time.units,calendar=calendrier)
                dicodate[nomfic]["datesup"]=nc4.num2date(time[indtimesuppp],time.units,calendar=calendrier)
                # print( 'moyenne entre time=',dicodate[nomfic]["dateinf"],' et',dicodate[nomfic]["datesup"])

                # attention indtimesuppp pas inclu quand on fait tab[indtimeinfpp:indtimesuppp] (donc on fait une variable avec indtimesuppp+1 pour inclure la borne supérieure dans la moyenne)
                indtsup=indtimesuppp+1
                if indtsup > time.shape[0]:
                    indtsup=indtimesuppp
                # print( 'indtsup=',indtsup)


            # ménage
            del time

            # coordonnée verticale de la variable
            #---------------------------------
            # nom des dimensions de la variable
            nomdim=dicovar[nomfic].dimensions
            nomz=nomdim[1]
            # variable verticale : zf ou zh, pf ou ph
            nomvarh=axevert+nomz[-1]
            # print( nomvarh)
            #alti=dicofic[nomfic].variables[nomvarh]
            mesg=[]
            if(is_prof==1) : 
              alti=util.recup_champ(dicofic[nomfic],nomvarh,mesg)
              if ( mesg ):
                  # print( '<p>WARNING : %s</p>' % (mesg))
                  altiok=False

              nbdimalti=alti.ndim
              # print( 'nbdimalti=',nbdimalti)
              if ( nbdimalti == 2 ):
                  if moytok:
                      # altitude moyenne entre les temps indtimeinfpp et indtsup
                      altitempo=np.mean(alti[indtimeinfpp:indtsup,:],axis=0)
                  else:
                      altitempo=alti[indtimepp,:]
              else:
                  altitempo=alti[:]

              if ( util.with_valid(altitempo) ):
                  altiok=True

                  # on fait des sous-tableaux de données si zmin et zmax fournis (pour echelle du graphique en fonction des datas)
                  if (util.is_init(zmin) and util.is_init(zmax)):
                      # indices les plus proches de zmin et zmax
                      indzminpp=util.ind_plusproche(altitempo[:],zmin)
                      indzmaxpp=util.ind_plusproche(altitempo[:],zmax)
                      # print( 'indzminpp=',indzminpp,' z=',altitempo[indzminpp],' indzmaxpp=',indzmaxpp,' z=',altitempo[indzmaxpp])
                      if indzminpp <= indzmaxpp:
                          indzmin=indzminpp
                          indzmax=indzmaxpp
                      else:
                          indzmin=indzmaxpp
                          indzmax=indzminpp
                      # on prend un point de plus en dessous et au dessus pour que le graphique ne soit pas coupé
                      # attention indzmax pas inclu quand on fait tab[indzmin:indzmax] (donc on fait +=2 pour indzmax)
                      indzmin-=1
                      indzmax+=2
                      if indzmin < 0:
                          indzmin=0
                      if indzmax > altitempo.shape[0]:
                          indzmax=altitempo.shape[0]
                  else:
                      indzmin=0
                      indzmax=altitempo.shape[0]

                  dicoalti[nomfic]=altitempo[indzmin:indzmax].copy()
                  # print( 'indzmin=',indzmin,'z=',altitempo[indzmin],' indzmax-1=',indzmax-1,'z=',altitempo[indzmax-1])

                  if ( not unitz ):
                      unit_alti=util.unit_champ(dicofic[nomfic],nomvarh)
                      if unit_alti:
                          unitz=True
              else:
                  altiok=False
                  # print( "<p>WARNING: %s ne contient pas de donnees %s valides</p>" % (nomfic,nomvarh))
              # print( nomvarh,' : ',dicoalti[nomfic])
              # unité nomvarh
              #ménage
              del altitempo


              # champ à la date la plus proche de dateprof ou moyenné sur moyt heures
              #----------------------------------------------------------------------
              if (altiok):
                  #datatempo=dicovar[nomfic][indtimepp,:]
                  mesg=[]
                  if moytok:
                      # champ moyenné entre les temps indtimeinfpp et indtsup 
                      recuptempo=util.recup_champ(dicofic[nomfic],nomvar,mesg)
                      # cas particulier ou le tableau récupéré est 1d
                      if ( recuptempo.ndim == 1 ):
                          # cas où 1 seul temps dans le fichier, donc pas de moyenne
                          datatempo=recuptempo[indzmin:indzmax]
                      else:
                          datatempo=np.mean(recuptempo[indtimeinfpp:indtsup,indzmin:indzmax],axis=0)
                      
                      # print( 'data pour mean:',util.recup_champ(dicofic[nomfic],nomvar,mesg)[indtimeinfpp:indtsup,indzmin:indzmax])
                      # print( 'mean:',datatempo[:])
                  else:
                      # champ au temps le plus proche
                      recuptempo=util.recup_champ(dicofic[nomfic],nomvar,mesg)
                      # cas particulier ou le tableau récupéré est 1d
                      if ( recuptempo.ndim == 1 ):
                          datatempo=recuptempo[indzmin:indzmax]
                      else:
                          datatempo=recuptempo[indtimepp,indzmin:indzmax]
                  if ( mesg ):
                      # print( '<p>WARNING : %s</p>' % (mesg))
                      bug=1
                  if ( util.with_valid(datatempo) ):
                      dicochamp[nomfic]=datatempo[:].copy()
                  else:
                      # print( "<p>WARNING: %s ne contient pas de donnees %s valides</p>" % (nomfic,nomvar))
                      bug=1

                  # print( nomfic,' : ',dicochamp[nomfic])
                  # print( 'nombre de valeurs =',dicochamp[nomfic].size)

                  # ménage
                  del alti,datatempo,recuptempo
            elif(is_prof==0) :
                dicochamp[nomfic]=util.recup_champ(dicofic[nomfic],nomvar,mesg)


if(is_prof==1) : 
  strhhprof=dateprof.strftime('%H')
  nomimg='profil_'+cas+'_'+nomvar+'_'+strhhprof+'.png'
elif(is_prof==0) :
  nomimg='serie_'+cas+'_'+nomvar+'.png'

# nombre de dataset
nbchamp=len(dicochamp)
# print( 'nbdicochamp=',len(dicochamp))
#--------
# plot
#--------

if (nbchamp>=1):
    if(is_prof==1) : 
      if (nbchamp<=24):
          fig=plt.figure(figsize=(8,8)) # défaut (8,6) en pouces 
          fig=plt.figure(figsize=(4,8)) # défaut (8,6) en pouces 
          ax=fig.add_subplot(111)
          fig.subplots_adjust(left=.15,right=.90,top=.9,bottom=0.40)
      else:
          fig=plt.figure(figsize=(8,10)) # défaut (8,6) en pouces 
          ax=fig.add_subplot(111)
          fig.subplots_adjust(left=.15,right=.90,top=.9,bottom=0.50)


      # titre en haut
      strdateprof=dateprof.strftime('%Y-%m-%d %H:%M')
      fig.suptitle(Case+" "+SubCase+" "+strdateprof,fontsize=12.,x=0.52,y=.95,horizontalalignment='center')
      # titre axe y
      #if 'unit_alti' in locals():
      if util.is_init(unit_alti):
          ax.set_ylabel(unit_alti,fontsize=12.)
      # titre axe x
      #if 'long_name' in locals():
      if util.is_init(long_name):
          titx=long_name
      else:
          titx=''
      # pas bon le "in locals()" : se plante si pas d'unité dans le netcdf
      # le 18/05 remplacé par is_init
      #if 'unit_champ' in locals():
      if util.is_init(unit_champ):
          titx=titx+' ('+unit_champ+')'
      ax.set_xlabel(titx,fontsize=12.)

      # label éventuel en haut à gauche, avec la durée moyenne demandée
      if moytok:
          titmoyt='average: '+str(moyt)+' h'
          plt.text(0,1.06,titmoyt,transform=ax.transAxes,fontsize=10.)


    elif(is_prof==0) :
      if (nbchamp<=24):
          fig=plt.figure(figsize=(8,6)) # défaut (8,6) en pouces
          ax=fig.add_subplot(111)
          fig.subplots_adjust(left=.15,right=.90,top=.9,bottom=0.40)
      else:
          fig=plt.figure(figsize=(8,10)) # défaut (8,6) en pouces
          ax=fig.add_subplot(111)
          fig.subplots_adjust(left=.15,right=.90,top=.9,bottom=0.50)


      # titre en haut
      strdateprof=Case+" "+SubCase #dateprof.strftime('%Y-%m-%d %H:%M')
      fig.suptitle(strdateprof,fontsize=12.,x=0.52,y=.95,horizontalalignment='center')
      # titre axe y
      #if 'unit_alti' in locals():
      if util.is_init(long_name):
          titx=long_name
      else:
          titx=''
      # pas bon le "in locals()" : se plante si pas d'unité dans le netcdf
      # le 18/05 remplacé par is_init
      #if 'unit_champ' in locals():
      if util.is_init(unit_champ):
          titx=titx+' ('+unit_champ+')'
      ax.set_ylabel(titx,fontsize=12.)
      ax.set_xlabel("time",fontsize=12.)

      # label éventuel en haut à gauche, avec la durée moyenne demandée
      if moytok:
          titmoyt='average: '+str(moyt)+' h'
          plt.text(0,1.06,titmoyt,transform=ax.transAxes,fontsize=10.)

    # couleurs
    colors = itertools.cycle(listcoul)

    #------------------------
    # boucle sur les champs
    #------------------------
    courbe=1
    #for nomfic in dicochamp:   
    #for nomfic in sorted(list(dicochamp.keys())):   # boucle nom de fichiers triés par ordre alphabétique
    for nomfic in listfic:    # boucle nom de fichiers dans l'ordre des fichiers de la liste

      if nomfic in list(dicochamp.keys()):
    
        # style traits 
        # "-"  : ligne continue
        # ":"  : pointillé
        # "--" : tirets
        # "-." : tirets point.
        if ( courbe <= 7 ):
            style_courbe="-"
            largeur_ligne=2.
        else:
            #style_courbe="o:"
            style_courbe="-"
            largeur_ligne=2.

        # prefixe des noms de fichier
        #champs_nomfic=nomfic.split('_')
        #if (champs_nomfic[2] != 'obs'):
        #    prefix='_'.join(champs_nomfic[:3])
        #else:
        #    prefix='_'.join(champs_nomfic[:2])
        #    # print( "%s est un fichier obs" % (nomfic))

        # label heure du profil pour chaque courbe 
        heurelab=''
        if moytok:
            # label si une moyenne de temps est demandée
            heurelab=' ['+dicodate[nomfic]["dateinf"].strftime('%H:%M')+','+dicodate[nomfic]["datesup"].strftime('%H:%M')+']'
        else:
            heurelab=' ['+dicodate[nomfic]["datepp"].strftime('%H:%M')+']'

        # tracé

        # On transforme nomfic en "ens" pour tester si on a un ensemble ou non
        petitnom=(nomfic.rsplit('/',1))[1].replace("min.nc","").replace("max.nc","")

        # Ajout Frederic pour gerer de facon automatique la labelisation des LES
        zlinewidth=largeur_ligne
        zlabel=util.titre_nomfic(nomfic)+heurelab
        if (coul1d == listcoul):
            ax.plot(dicochamp[nomfic][:],dicoalti[nomfic][:],style_courbe,color=next(colors),markersize=3.,markevery=4,linewidth=zlinewidth,label=zlabel)
        elif petitnom != 'ens' :
            try: 
                #nomcoul=coul1d[nomfic[len(prefix)+1:]]
                #nomcoul=coul1d[nomfic[5:]]
                nomcoul=coul1d[util.basefic(nomfic)]
                stylcoul=styl1d[util.basefic(nomfic)]
            except KeyError:
                # print( "<p>WARNING: couleur non definie pour %s : utilisation du gris</p>" % (nomfic))
                nomcoul='grey'
            # print( 'nomcoul=',nomcoul)
            # print( 'plot de nomfic=',nomfic)
            zstyle=stylcoul
            # print( zstyle, stylcoul)
            if 1 == 1:
                zlabel=util.titre_nomfic(nomfic)
                if "LES" in zlabel:
                    if "LES0" in zlabel:
                        zlinewidth=4
                    else:
                        zlinewidth=0.5
                        stylcoul='-'
                        if "LES1" in zlabel:
                            zlabel="LES ensemble"
                        else:
                            zlabel=""
            if(is_prof==1) : 
              ax.plot(dicochamp[nomfic][:],dicoalti[nomfic],stylcoul,color=nomcoul,markersize=3.,markevery=4,linewidth=zlinewidth,label=zlabel)
            elif(is_prof==0) :
              nb_time=len(time_axes[nomfic])
              ax.plot(time_axes[nomfic], dicochamp[nomfic][0:nb_time],stylcoul,color=nomcoul,markersize=3.,markevery=4,linewidth=zlinewidth,label=zlabel)

        courbe+=1
    # PREMIERE FACON DE GERER LES ENSEMBLES
    # si les fichiers ensmin et ensmax sont dans la liste
    dico_ens=util.test_ficstat(list(dicochamp.keys()))
    if (dico_ens):
        # print( 'dico_ens: ',dico_ens)
        colors_ens=['lightgrey','mistyrose','lemonchiffon','palegreen','paleturquoise']
        icol_ens=0
        for nomens in listens:
            # print( 'nomens: ',nomens)
            nom_ensmin=dico_ens[nomens]["ensmin"]
            nom_ensmax=dico_ens[nomens]["ensmax"]
            if (nom_ensmin and nom_ensmax):
                ax.fill_betweenx(dicoalti[nom_ensmin][:],dicochamp[nom_ensmin][:],dicochamp[nom_ensmax][:],facecolor=colors_ens[icol_ens])
            icol_ens+=1

    # SECONDE FACON DE GERER LES ENSEMBLES
    if (list_ens):
        ens_shades=['lightgrey','mistyrose','lemonchiffon','palegreen','paleturquoise']
        ens_lines_col=[ 'grey', 'lightcoral', 'orange', 'chartreuse', 'turquoise']
        icol_ens=0
        zorder=-100
        for ens in list_ens:
            # Le ensmin et ensmax peuvent ne pas voir exactement le meme nombre de niveaux.
            # Il faut donc imposer le min des deux nombres de niveaux dans les tracers.
            indmax=min(len(dicochamp[ens+'/ensmin.nc'][:]),len(dicochamp[ens+'/ensmax.nc'][:]))-1
            if(is_prof==1) : 
              ax.fill_betweenx(dicoalti[ens+'/ensmin.nc'][0:indmax],dicochamp[ens+'/ensmin.nc'][0:indmax],dicochamp[ens+'/ensmax.nc'][0:indmax],facecolor=ens_shades[icol_ens],label=ens.split('/')[0],zorder=zorder)
              ax.plot(dicochamp[ens+'/ensmin.nc'][0:indmax],dicoalti[ens+'/ensmin.nc'][0:indmax],color=ens_lines_col[icol_ens],linewidth=1,zorder=zorder)
              ax.plot(dicochamp[ens+'/ensmax.nc'][0:indmax],dicoalti[ens+'/ensmin.nc'][0:indmax],color=ens_lines_col[icol_ens],linewidth=1,zorder=zorder)
              zorder=zorder+1
            elif(is_prof==0) : 
              nb_time=len(time_axes[nomfic])
              indmax=min(len(dicochamp[ens+'/ensmin.nc'][:]),len(dicochamp[ens+'/ensmax.nc'][:]), nb_time)
              pasbeau=time_axes[nomfic]
              ax.fill_between(pasbeau, dicochamp[ens+'/ensmin.nc'][0:indmax],dicochamp[ens+'/ensmax.nc'][0:indmax],facecolor=ens_shades[icol_ens],label=ens.split('/')[0],zorder=zorder)
              ax.plot(pasbeau,dicochamp[ens+'/ensmin.nc'][0:indmax],color=ens_lines_col[icol_ens],linewidth=1,zorder=zorder)
              ax.plot(pasbeau, dicochamp[ens+'/ensmax.nc'][0:indmax],color=ens_lines_col[icol_ens],linewidth=1,zorder=zorder)
              zorder=zorder+1
            icol_ens+=1

    #-------------------------------
    # mise en forme du graphique
    #-------------------------------
    # ticks
    #------
    # ticks axe x
    ax.xaxis.set_major_locator(ticker.MaxNLocator())
    ax.xaxis.set_minor_locator(ticker.AutoMinorLocator())
    if(is_prof==1) : 
      x_majorfmt=ticker.ScalarFormatter(useMathText=True)
      ax.xaxis.set_major_formatter(x_majorfmt)
      ax.ticklabel_format(style='sci',axis='x',scilimits=(-2,3))
      ax.xaxis.set_tick_params(which='both',direction='out')
    elif(is_prof==0) : 
      ax.tick_params(axis='x', rotation=30)
      xfmt = mdates.DateFormatter('%H:%M')
      ax.xaxis.set_major_formatter(xfmt)
    # ticks axe y
    #ax.yaxis.set_major_locator(ticker.MaxNLocator(integer=True,min_n_ticks=5))
    ax.yaxis.set_major_locator(ticker.MaxNLocator())
    ax.yaxis.set_minor_locator(ticker.AutoMinorLocator())
    y_majorfmt=ticker.ScalarFormatter(useMathText=True)
    ax.yaxis.set_major_formatter(y_majorfmt)
    ax.yaxis.set_tick_params(which='both',direction='out')

    # grille
    ax.grid(True)
    #ax.grid(which='both')

    # limites d'axe
    if(is_prof==1) : 
      if (util.is_init(zmin) and util.is_init(zmax)):
          ax.set_ylim(zmin,zmax)

      if (util.is_init(vmin) and util.is_init(vmax)):
          ax.set_xlim(vmin,vmax)
    elif(is_prof==0) : 
      if (util.is_init(vmin) and util.is_init(vmax)):
          ax.set_ylim(vmin,vmax)


    # paramètres de la légende
    #-------------------------
    # bbox_to_anchor : position de "loc" de la légende
    # loc  : pour quel coin de la légende 
    # ncol : nombre de colonnes
    # labelspacing : taille de l'espace vertical entre les entrées de la légende
    # columnspacing : taille de l'espace entre les colonnes
    # numpoints : nombre de marqueurs
    if ( nbchamp <= 8 ):
        nbcol=2
    else:
        nbcol=2
    ax.legend(bbox_to_anchor=(-0.13, -0.15),loc='upper left',ncol=nbcol,fontsize=10.,labelspacing=.3,numpoints=2,markerscale=1.,handlelength=2.,frameon=False)

    # inversion axe y si coordonnée pression
    if ( axevert == 'p' ):
        plt.gca().invert_yaxis()

    plt.savefig(nomimg,bbox_inches='tight')

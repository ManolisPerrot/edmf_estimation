# This script plot metric vs metric  
#      + (optional) best simulations or choosen higlighted simulations
#      + (optional) ensembles highlighted in colors
#
# by default plot ensembles from iwavemin to iwavemax (you must specify at the begining of the script)
# you can also specify ensemble files and their corresponding best/highlighted simulation 
#
# Adapted from scatter_plot.py ans scatter_param_metric.py (almost same arguments)
#
# Stuff to be done : 
# - pdfjam by metrics ? -> installer pdfjam sur ricard
#
# Maelle Coulon--Decorzens - Frédéric Hourdin - Najda Villefranque - Mars 2024

import pandas as pd
import re
import matplotlib.pyplot as plt
import os
import argparse
import sys

#------------------------------------------------------------------------------
# Some previous variables the user might change
#------------------------------------------------------------------------------

iwavemin=1
iwavemax=40
path_fig="PDF/metric_vs_metric/" #path where figures are saved (from here)

#------------------------------------------------------------------------------
# Script optional arguments 
#------------------------------------------------------------------------------
parser=argparse.ArgumentParser()
parser.add_argument("-o",help="Observation csv file",metavar='OBS.csv')
parser.add_argument("-e",help='List of ensemble csv files "ENS1[,ENS2[,...]]"',metavar="ENS1.csv[,ENS2.csv[,...]]")
parser.add_argument("-b",help='List of names of best simulations',metavar="sim1[,sim2[,...]]")
parser.add_argument("-l",help='List of ensemble csv files you want to be highlighted in colors',metavar="ENS1.csv[,ENS2.csv[,...]]")
parser.add_argument("-n",help='Number of best simulations to be automatically displayed',metavar="N",default='10')
#parser.add_argument("-c",help='matplotlib colormap : eg, BrBG PuOr RdYlGn Spectral_r bwr coolwarm_r earth_r ocean_r twilight_shifted Accent',metavar="cmap",default='Paired')
args=parser.parse_args()

### Highlighted ensembles ##i#
#wave number or ens file metric name you to be in color

if args.l :
  enstoprint=args.l.split(',')
elif(iwavemax > 3 ) :
  enstoprint=[1,3,iwavemax] #wave number or ens file metric name you to be in color
else :
  enstoprint=[1,iwavemax]

### Obs file ###
if args.o :
  obs_file=args.o
  print('Obs file from arguments : ',obs_file)
else :
  obs_file="WAVE"+str(iwavemin)+"/metrics_REF_"+str(iwavemin)+".csv"
  print('Obs file from WAVE'+str(iwavemin)+' : '+obs_file)

obs=pd.read_csv(obs_file,sep=",")
obs_mean=obs.loc[0]
obs_var=obs.loc[1]


### Metrics and Parameters ensembles ###

if args.e :
  metric_files=args.e.split(",")
  print('Ensemble metrics files from arguments : ',metric_files)
  nwave=len(metric_files)
  file_metrics_ref=metric_files[0]
else :
  metric_files=[]
  for iwave in range(iwavemin,iwavemax+1) : 
    metric_files.append("WAVE"+str(iwave)+"/metrics_WAVE"+str(iwave)+"_"+str(iwave)+".csv")
  file_metrics_ref="WAVE"+str(iwavemin)+"/metrics_WAVE"+str(iwavemin)+"_"+str(iwavemin)+".csv"

metrics_ref=pd.read_csv(file_metrics_ref,sep=",")


### Bests simulations ###
list_bests=[]
nbests_auto=int(args.n)
if args.b :
  list_bests=args.b.split(",")
elif(args.e is None) : #controled by waves
  file_score="score"+str(iwavemin)+"to"+str(iwavemax)+".csv"
  if(os.path.exists(file_score) ==  False) :
    os.system(" head -1 score"+str(iwavemin)+".csv > "+file_score)
    os.system(" for i in $( seq "+str(iwavemin)+" "+str(iwavemax)+") ; do tail -n +2 score$i.csv >> "+file_score+" ; done")

  score=pd.read_csv(file_score, sep=",")
  sorted_score=score.sort_values(by="MAX", ascending=True)
  selected_simu=sorted_score[0:nbests_auto]['SIM']
  for simu in selected_simu :
    list_bests.append(simu)
else :
  print("if you specify ensembles you must specify with option -b the list of simulations you want to highlighted, or it will be none of them")
  list_bests=[]

### Dico bests -> file metrics ###
dico_bests={}
dico_bests["metrics"]={}

imet=0
for fm in metric_files :
  isimu=0
  for simu in list_bests :
    res=os.system("res=`grep "+str(simu)+" "+fm+"`")
    if( res == 0 ) :
      dico_bests["metrics"][simu]=fm
    isimu=isimu+1
  imet=imet+1


### Plot colors ###
#colors_ens=['#d0d0d0', '#3bafba', '#d56a6a', '#cdc25b']
listcoul=['green','fuchsia','blue','lime','darkviolet','cyan','darkorange','slateblue','brown','gold']
#colors_ens=['lightgrey','mistyrose','lemonchiffon','palegreen','paleturquoise']
colors_ens=['lightgrey','#5fb6be', '#d56a6a','#cdc25b','#72BB72','#3bafba']

###
if(os.path.exists(path_fig) ==  False) :
  os.system("mkdir -p "+path_fig)

#------------------------------------------------------------------------------
# Loop on metrics1 and metrics2
#------------------------------------------------------------------------------

list_metric1=[]
for imetric1,metric1_ in enumerate(metrics_ref.columns.values[1:]):
  metric1_split=metric1_.split('_')
  metric1=""
  for x in metric1_split[1:] :
    metric1=metric1+'_'+x
  metric1=metric1[1:]
  metric1_head=metric1_split[0]
  list_metric1.append(metric1)
  print("metric1 = ", metric1)
  for imetric2,metric2_ in enumerate(metrics_ref.columns.values[1:]):
    metric2_split=metric2_.split('_')
    metric2=""
    for x in metric2_split[1:] :
      metric2=metric2+'_'+x
    metric2=metric2[1:]
    metric2_head=metric2_split[0]
    if(metric2 not in list_metric1) : 
      print("plot ", metric1, " vs ", metric2)
      plt.subplots_adjust(left=0.1, right=0.7, top=0.6, bottom=0.1)
      
      #-------------------------------------------------------------------
      # Plotting ensembles
      #-------------------------------------------------------------------
      iens=0
      ii=1
      for file_ens in metric_files :
        metrics=pd.read_csv(file_ens,sep=",",index_col="SIM")
        if "WAVE" in metric1_head :
          iwave=metrics.keys()[imetric1].split('_')[0][4:]
          metric1_head="WAVE"+str(iwave)
          metric2_head="WAVE"+str(iwave)
          label='Wave'+str(iwave)
        else :
          label=metric1_head+" "+str(iens)
        name_metric1=metric1_head+'_'+metric1
        name_metric2=metric2_head+'_'+metric2
        if ( (("WAVE" in metric1_head) & (int(iwave) in enstoprint)) | (file_ens in enstoprint) ) :
          zorder=ii
          color=colors_ens[ii]
          ii=ii+1
        else :
          zorder=-100
          color=colors_ens[0]
        plt.scatter(metrics[name_metric2],metrics[name_metric1],label=label,s=20, marker='x', color=color, zorder=zorder)
        iens=iens+1
      ## end loop on ensembles (or waves)
  
      #-------------------------------------------------------------------
      # Plotting targets and errors
      #-------------------------------------------------------------------
      obs_head1=obs.keys()[imetric1+1].split('_')[0]
      obs_head2=obs.keys()[imetric2+1].split('_')[0]
      name_obs_metric1=obs_head1+"_"+metric1
      name_obs_metric2=obs_head2+"_"+metric2
      #plt.errorbar(obs_mean[name_obs_metric2],obs_mean[name_obs_metric], yerr=obs_var[name_obs_metric]**0.5, xerr=obs_var[name_obs_metric2]**0.5, color='k', lw=0.5)
      plt.axhline(obs_mean[name_obs_metric1],xmin=0,xmax=1,color='k')
      plt.axhline(obs_mean[name_obs_metric1]+(obs_var[name_obs_metric1])**0.5,xmin=0,xmax=1,color='k', ls=':')
      plt.axhline(obs_mean[name_obs_metric1]-(obs_var[name_obs_metric1])**0.5,xmin=0,xmax=1, color='k', ls=':')


      plt.axvline(obs_mean[name_obs_metric2],ymin=0,ymax=1,color='k')
      plt.axvline(obs_mean[name_obs_metric2]+(obs_var[name_obs_metric2])**0.5,ymin=0,ymax=1,color='k', ls=':')
      plt.axvline(obs_mean[name_obs_metric2]-(obs_var[name_obs_metric2])**0.5,ymin=0,ymax=1, color='k', ls=':')
  
  
      #-------------------------------------------------------------------
      # Plotting bests simulations
      #-------------------------------------------------------------------
      isimu=0
      for simu in list_bests :
        file_metrics=dico_bests["metrics"][simu]
        metrics=pd.read_csv(file_metrics,sep=",", index_col='SIM')
        if "SCM" in simu :
          iwave=simu.split('-')[1]
          metric_head1="WAVE"+str(iwave)
          metric_head2="WAVE"+str(iwave)
        name_metric1=metric_head1+'_'+metric1
        name_metric2=metric_head2+'_'+metric2
        met_value1=metrics.loc[simu][name_metric1]
        met_value2=metrics.loc[simu][name_metric2]
        color=listcoul[isimu]
        plt.scatter(met_value2,met_value1,label=simu,s=20, marker='o', edgecolor="k", zorder=100,color=color)
        isimu=isimu+1

      plt.xlabel(metric2)
      plt.ylabel(metric1)
      plt.legend(ncol=2,loc=(1.05,0.),fontsize=6)
      plt.savefig(path_fig+metric1+"_"+metric2+".pdf",bbox_inches='tight')
      plt.close()
  ## end loop on parameters
##end loop on metrics

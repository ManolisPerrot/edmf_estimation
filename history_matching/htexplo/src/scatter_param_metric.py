# This script plot metric vs parameter 
#        + (optional) best simulations or choosen higlighted simulations
#        + (optional) ensembles highlighted in colors
#
# by default plot ensembles from iwavemin to iwavemax (you must specify at the begining of the script)
# you can also specify ensemble files and their corresponding parameters files and highlighted simulations
# with options
#
# Ensemble files must be csv files :
#   - containing an header with metric_name=head_metric+"_"+metric (head_metric can be WAVEX)
#   - the head of the first line must be "SIM"
#   - separated by ","
# 
# Parameters files must be asc files :
#   - containing an header with parameters name 
#   - the head of the first line must be "t_IDs"
#   - separated by " "

# Adapted from CCCma_scripts and scatter_plot.py (almost same arguments)
#
# Stuff to be done : 
# - maybe add an option to plot on log scales (when parameter are explores in log scale ?)
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
iwavemax=30
path_fig="PDF/metric_vs_param/" #path where figures are saved (from here)


#------------------------------------------------------------------------------
# Script optional arguments 
#------------------------------------------------------------------------------
parser=argparse.ArgumentParser()
parser.add_argument("-o",help="Observation csv file",metavar='OBS.csv')
parser.add_argument("-e",help='List of ensemble csv files "ENS1.csv,ENS2.csv,..."',metavar="ENS1.csv,ENS2.csv,...")
parser.add_argument("-p",help='List of param csv files corresponding to ensemble "PARAM1.asc,PARAM2.asc,..."',metavar="PARAM1.asc,PARAM2.asc,...")
parser.add_argument("-l",help='List of ensemble csv files you want to be highlighted in colors ENS1.csv,ENS10.csv,...' ,metavar="ENS1.csv,ENS10.csv,...")
parser.add_argument("-b",help='List of names of best simulations sim1,sim2,...',metavar="sim1,sim2,...")
parser.add_argument("-n",help='Number of best simulations to be automatically displayed',metavar="N",default='10')
#parser.add_argument("-c",help='matplotlib colormap : eg, BrBG PuOr RdYlGn Spectral_r bwr coolwarm_r earth_r ocean_r twilight_shifted Accent',metavar="cmap",default='Paired')
args=parser.parse_args()

### Highlighted ensembles ##i#
#wave number or ens file metric name you want to be in color

if args.l : 
  enstoprint=args.l.split(',')
  print('Highlighted ensemble from arguments : ',enstoprint)
elif(iwavemax > 3 ) : 
  enstoprint=[1,3,iwavemax] #wave number or ens file metric name you to be in color
  print('Highlighted ensemble from WAVES '+str(iwavemin)+' to '+str(iwavemax))
else : 
  enstoprint=[1,iwavemax]
  print('Highlighted ensemble from WAVES '+str(iwavemin)+' to '+str(iwavemax)


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

if ( ((args.e is not None) & (args.p is None)) | ((args.p is not None) & (args.e is None) )) : 
  print("if you give specific ensemble in argument you must give their parameters files with -p option")
  print("Stop the program here")
  sys.exit()

if args.e :
  metric_files=args.e.split(",")
  print('Ensemble metrics files from arguments : ',metric_files)
  nwave=len(metric_files)
  file_metrics_ref=metric_files[0]
  param_files=args.p.split(",")
  file_params_ref=param_files[0]
  print('Ensemble parameter files from arguments : ',param_files)
else :
  metric_files=[]
  param_files=[]
  for iwave in range(iwavemin,iwavemax+1) : 
    metric_files.append("WAVE"+str(iwave)+"/metrics_WAVE"+str(iwave)+"_"+str(iwave)+".csv")
    param_files.append("WAVE"+str(iwave)+"/Par1D_Wave"+str(iwave)+".asc")
  file_metrics_ref="WAVE"+str(iwavemin)+"/metrics_WAVE"+str(iwavemin)+"_"+str(iwavemin)+".csv"
  file_params_ref="WAVE"+str(iwavemin)+"/Par1D_Wave"+str(iwavemin)+".asc"
  print('Ensemble metrics from WAVES : ',metric_files)
  print('Ensemble parameter files from WAVES : ',param_files)

metrics_ref=pd.read_csv(file_metrics_ref,sep=",")
params_ref=pd.read_csv(file_params_ref,sep=' ')

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
  print("if you specify ensembles you must specify with option -b the list of simulations you want to highlight, or it will be none of them")
  list_bests=[]

### Dico bests -> file metrics et bests -> file params ###
dico_bests={}
dico_bests["metrics"]={}
dico_bests["params"]={}

imet=0
for fm in metric_files : 
  isimu=0
  for simu in list_bests : 
    res=os.system("res=`grep "+str(simu)+" "+fm+"`")
    if( res == 0 ) :
      dico_bests["metrics"][simu]=fm
      dico_bests["params"][simu]=param_files[imet]
    isimu=isimu+1
  imet=imet+1
print("list_bests = ", list_bests)

### Plot colors ###
#colors_ens=['#d0d0d0', '#3bafba', '#d56a6a', '#cdc25b']
listcoul=['green','fuchsia','blue','lime','darkviolet','cyan','darkorange','slateblue','brown','gold']
#colors_ens=['lightgrey','mistyrose','lemonchiffon','palegreen','paleturquoise']
colors_ens=['lightgrey','#5fb6be', '#d56a6a','#cdc25b','#72BB72','#3bafba']

if(os.path.exists(path_fig) ==  False) :
  os.system("mkdir -p "+path_fig)
#------------------------------------------------------------------------------
# Loop on metrics and parameters
#------------------------------------------------------------------------------
for imetric,metric_ in enumerate(metrics_ref.columns.values[1:]):
  metric_split=metric_.split('_')
  metric=""
  for x in metric_split[1:] :
    metric=metric+'_'+x
  metric=metric[1:]
  metric_head=metric_split[0]
  print("metric = ", metric)
  
  for iparam,param in enumerate(params_ref.columns.values[1:]) :
    plt.subplots_adjust(left=0.1, right=0.7, top=0.6, bottom=0.1)
    
    #-------------------------------------------------------------------
    # Plotting ensembles
    #-------------------------------------------------------------------
    iens=0
    ii=1
    for file_ens in metric_files :
      metrics=pd.read_csv(file_ens,sep=",",index_col="SIM")
      file_param=param_files[iens]
      params=pd.read_csv(file_param,sep=" ",index_col="t_IDs")
      if "WAVE" in metric_head :
        iwave=metrics.keys()[imetric].split('_')[0][4:]
        metric_head="WAVE"+str(iwave)
        label='Wave'+str(iwave)
      else :
        label=metric_head+" "+str(iens)
      name_metric=metric_head+'_'+metric
      if ( (("WAVE" in metric_head) & (int(iwave) in enstoprint)) | (file_ens in enstoprint) ) :
        zorder=ii
        color=colors_ens[ii]
        ii=ii+1
      else :
        zorder=-100
        color=colors_ens[0]
      plt.scatter(params[param],metrics[name_metric],label=label,s=20, marker='x', color=color, zorder=zorder)
      iens=iens+1
    ## end loop on ensembles (or waves)

    #-------------------------------------------------------------------
    # Plotting targets and errors
    #-------------------------------------------------------------------
    obs_head=obs.keys()[imetric+1].split('_')[0]
    name_obs_metric=obs_head+"_"+metric
    plt.axhline(obs_mean[name_obs_metric],xmin=0,xmax=1,color='k')
    plt.axhline(obs_mean[name_obs_metric]+(obs_var[name_obs_metric])**0.5,xmin=0,xmax=1,color='k', ls=':')
    plt.axhline(obs_mean[name_obs_metric]-(obs_var[name_obs_metric])**0.5,xmin=0,xmax=1, color='k', ls=':')

    #-------------------------------------------------------------------
    # Plotting bests simulations
    #-------------------------------------------------------------------
    isimu=0
    for simu in list_bests :
      file_metrics=dico_bests["metrics"][simu]
      file_params=dico_bests["params"][simu]
      metrics=pd.read_csv(file_metrics,sep=",", index_col='SIM')
      params=pd.read_csv(file_params,sep=" ", index_col="t_IDs")
      if "SCM" in simu :
        iwave=simu.split('-')[1]
        metric_head="WAVE"+str(iwave)
      name_metric=metric_head+'_'+metric
      met_value=metrics.loc[simu][name_metric]
      param_value=params.loc[simu][param]
      color=listcoul[isimu]
      plt.scatter(param_value,met_value,label=simu,s=20, marker='o', edgecolor="k", zorder=100,color=color)
      isimu=isimu+1
    ##end loop on bests simu

    #-------------------------------------------------------------------
    # Closing grpahics
    #-------------------------------------------------------------------
    plt.xlabel(param)
    plt.ylabel(metric)
    plt.legend(ncol=2,loc=(1.05,0.),fontsize=6)
    plt.savefig(path_fig+metric+"_"+param+".pdf",bbox_inches='tight')
    plt.close()
  ## end loop on parameters
  # on regroupe les figures par métrique (idem Plots_Metric.pdf mais avec toutes les vagues)
  #os.system("pdfjam --fitpaper true "+path_fig+metric+"_*.pdf --outfile "+path_fig+metrics+"_vs_param.pdf")
  #print(path_fig+metrics+"_vs_param.pdf")
##end loop on metrics

# on regroupe les figures par paramètres
#for iparam,param in enumerate(params_ref.columns.values[1:]) :
#  os.system("pdfjam --nup 3x3 --landscape "+path_fig+"*"+param+"*.pdf --outfile "+path_fig++param+"_vs_metrics.pdf")
#  print(path_fig+param+"_vs_metrics.pdf")
  

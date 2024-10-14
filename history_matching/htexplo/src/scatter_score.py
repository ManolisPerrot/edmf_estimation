#----------------------------------------------------------------------------
#  Plotting successive waves of multi-metrics ensembles
#----------------------------------------------------------------------------
#
#  Auteur : F. Hourdin, 28 avril 2022
#
#  Concatenation de plusieurs fihciers csv de metriques HighTune
#     metrics_WAVEN_N.csv avec N=iwave1,...,iwavef, avec
#     iwavef=iwave1-1+nwave
#  suivi d'un calcul des scores normalises ( simu - obs ) /sig
#     ou obs et var (=sig^2) sont lus dans metrics_REF_N.csv
#     avec N=iwavef
#
#  Classification suivant un tri sur les max de ces errerurs normalisees
#  Tracer des metriques des vagues et des meilleurs simulations identifiees
#  dans bests
#
#----------------------------------------------------------------------------
# Importating modules
#----------------------------------------------------------------------------

import numpy as np
import matplotlib.pyplot as plt
import matplotlib.dates as dates
import datetime
from matplotlib.dates import date2num
import netCDF4
from pylab import savefig
import sys, getopt
import re
from matplotlib.ticker import ScalarFormatter
import os
import subprocess
import pandas
import argparse
from cycler import cycler
from mycolors import rainbow4 as princesse_colors


#----------------------------------------------------------------------------
#                 To be completed by user
#----------------------------------------------------------------------------

# first wave to be plotted
iwave1=1

# max number of waves to be plot
nwavemax=2000

# "observation" file containing targets and tolerances
obs_file="metrics_REF_"+str(iwave1)+".csv"
print(obs_file)

##########################################################################
#             graphics template
#########################################################################

#----------------------------------------------------------------------------
#  List of metrics files
#----------------------------------------------------------------------------

parser=argparse.ArgumentParser()
parser.add_argument("-o",help="Observation csv file",metavar='OBS.csv')
parser.add_argument("-e",help='List of ensemble csv files "ENS1[,ENS2[,...]]"',metavar="ENS1.csv[,ENS2.csv[,...]]")
parser.add_argument("-b",help='List of names of best simulations',metavar="sim1[,sim2[,...]]")
parser.add_argument("-n",help='Number of best simulations to be automatically displayed',metavar="N",default='10')
parser.add_argument("-c",help='matplotlib colormap : eg, BrBG PuOr RdYlGn Spectral_r bwr coolwarm_r earth_r ocean_r twilight_shifted Accent',metavar="cmap",default='Paired')
parser.add_argument("--log",help='log scale for metrics',action='store_true',default=False)
parser.add_argument("--max",help='Max value for metrics plot',default=10.)
args=parser.parse_args()

max_metrics=float(args.max)

do_log=args.log
if do_log :
    metmin=0.2
    metmax=max_metrics
else :
    metmin=-max_metrics
    metmax=max_metrics

cmap=args.c


if args.o :
   obs_file=args.o
   print('Obs file from arguments : ',obs_file)
else :
   obs_file='WAVE1/metrics_REF_1.csv'
   print('Obs file from WAVE1 : ',obs_file)


nbests_auto=int(args.n)
bests=[]
if args.b :
   bests=args.b.split(",")

obs_=pandas.read_csv(obs_file,sep=',')
obs_mean=obs_.loc[0]
obs_var=obs_.loc[1]


if args.e :
   metric_files=args.e.split(",")
   print('Ensemble files from arguments : ',metric_files)
   nwave=len(metric_files)
else :
   nwave_diag = max([ int(re.sub('WAVE','',f)) for f in os.listdir() if ( os.path.isdir(f) & ( 'WAVE' in f ) & ('_' not in f)) ])
   nwave=min(nwave_diag,nwavemax)
   metric_files=[]
   for iw in range(1,nwave+1) :
       m_='WAVE'+str(iw)+'/metrics_WAVE'+str(iw)+'_'+str(iw)+'.csv'
       if os.path.exists(m_) :
           metric_files=metric_files+[m_]
   print('Ensemble files from WAVES : ',metric_files)

ensemble_names=[ f.split(".")[0].split("/")[0] for f in metric_files ]


#----------------------------------------------------------------------------
#  graphics parameters
#----------------------------------------------------------------------------

#nom de la figure que l'on souhaite enregistrer
name_fig="score_metrics.pdf"
w,h = plt.figaspect(1./2.)
plt.figure(figsize=(w,h))

#----------------------------------------------------------------------------
# Ploting waves
#----------------------------------------------------------------------------

for iw,metric_file in enumerate(metric_files) :
#for iiw in [1,2,4,8,16,32]:
   wave=iw+iwave1
   metrics_=pandas.read_csv(metric_file,sep=',')
   
   #-------------------------------------------------------------------------
   # Creating a new DataFrame to store scores.
   # Two DataFrame are needed, one for relative and the other for absolute
   #    values. The absolute value is used to compute MEAN and MAX scores
   #    even if relative values are used for the plot
   #-------------------------------------------------------------------------
   scores_=pandas.DataFrame(columns=obs_.columns)

   scores_abs=pandas.DataFrame(columns=obs_.columns)
   for ikey,key in enumerate(obs_.keys()[:]) :
      # Key names
      if ikey == 0 :
          scores_[obs_.keys()[0]]=metrics_[metrics_.keys()[0]]
          scores_abs[obs_.keys()[0]]=metrics_[metrics_.keys()[0]]
      # computing scores
      else :
          key_sim=metrics_.keys()[ikey]
          target=obs_mean.get(key)
          tolerance=obs_var.get(key)**0.5
          scores_[key]=(metrics_[key_sim]-target)/tolerance
          scores_abs[key]=np.abs((metrics_[key_sim]-target)/tolerance)

   if do_log :
       scores_=scores_abs

   #-------------------------------------------------------------------------
   # Adding mean and max valus to the DataFrame
   #-------------------------------------------------------------------------

   scores_['MEAN']=scores_abs[scores_abs.keys()[1:]].mean(axis=1)
   scores_['MAX']=scores_abs[scores_abs.keys()[1:]].max(axis=1)
   if iw == 0 :
       all_scores=scores_
   else :
       all_scores = pandas.concat([all_scores,scores_],axis=0)

   #-------------------------------------------------------------------------
   # Cycling marker colors and transparency for ensembles
   #-------------------------------------------------------------------------

   colors = [plt.get_cmap(cmap)(1. * i/(nwave+0.01-1)) for i in range(nwave)]
   plt.rc('axes', prop_cycle=(cycler('markerfacecolor',colors) + cycler('alpha',[0.5]*nwave) ))

   #-------------------------------------------------------------------------
   # Ploting scores for ensembles
   # All the metrics are plotted at once for one ensemble
   #-------------------------------------------------------------------------
   xx=[]
   yy=[]
   xxb=[]
   yyb=[]
   for ikey in range(1,len(scores_.keys())):
       key=scores_.keys()[ikey]
       scores=list(scores_[key])
       xx+=scores
       # On decale legerement  les x des vagues
       yval=ikey+(iw-float(nwave)/2.)*0.7/nwave
       yy+=[yval]*len(scores)
       xxb+=[np.min(scores),np.max(scores)]
       yyb+=[yval,yval]
   ms=200./(len(scores_.keys())*nwave)

   plt.plot(xx,yy,ls='',ms=ms,marker='s',mew=0.,zorder=-5,label=ensemble_names[iw])
   plt.plot(xxb,yyb,ls='',ms=3*ms,marker='+',markerfacecolor='black',mew=0.5*np.sqrt(ms),zorder=-10,mec='black',alpha=1.,label='Min/Max' if ( iw == len(metric_files)-1 ) else None )


#----------------------------------------------------------------------------
# Ploting best simulations
#----------------------------------------------------------------------------

#best_cols=['#1f77b4']*3+['#ff7f0e']*3+['#2ca02c']*3,['#d62728']*3
#best_cols=["darkviolet","blue","darkgreen","orange","red"]*10
#best_markers=['x']*5+['+']*5+['v']*5+['x']*5+['+']*5+['v']*5

best_sizes=[30.]*10+[10.]*15+[5.]*20
best_cols=['red']*3+['blue']*3+['darkorange']*3+['gold']*3
best_cols=['#1f77b4']*3+['#ff7f0e']*3+['#d62728']*3+['gold']*3
best_cols=['#1f77b4','#ff7f0e','#d62728','gold']*4
best_cols=list(princesse_colors)[2:5]*4
best_markers=['o','d','v']*30
best_markers=(['o']*3+['*']*3+['d']*3+['>']*3)*4
best_sizes=([20]*3+[40]*3+[18]*3+[18]*3)*4

#best_markers=['o','*','d']*30
#best_sizes=[16.,30.,18.]*30

sorted_scores=all_scores.drop_duplicates().sort_values('MAX').set_index('TYPE')
print('BESTS=',bests)
if nbests_auto >= 1 :
   bests+=list(sorted_scores.head(n=nbests_auto).index)
print('BESTS=',bests)

for isim,sim_ in enumerate(bests) :
   print('BEST =',sim_)
   yy=sorted_scores.loc[sim_].to_numpy()[:]
   xx=[ p+(isim-len(bests)/2.)*0.7/len(bests)+1. for p in range(len(yy)) ]
   plt.scatter(yy,xx,c=best_cols[isim],marker=best_markers[isim],s=best_sizes[isim],label=sim_,edgecolors='black',lw=0.4)

#----------------------------------------------------------------------------
# Ploting vertical lines at error/tolerance = 1, 2, 3
#----------------------------------------------------------------------------

line_levs=[1,2,3]
line_style=['-','--','-.']
for i,lev in enumerate(line_levs) :
   plt.axvline(lev,ls=line_style[i],color='gray',zorder=-10,label=r'$\epsilon/\sigma='+str(lev)+'$')
if do_log :
   plt.xscale('log')
else :
   for i,lev in enumerate(line_levs) :
      plt.axvline(-lev,ls=line_style[i],color='gray',zorder=-10)

#----------------------------------------------------------------------------
# Closing graph
#----------------------------------------------------------------------------

plt.grid(axis='y',ls='dotted')
plt.xlim(metmin,metmax)
plt.legend(loc=(1.,0.), fontsize=8)
yticks=[ p for p in range(1,len(scores_.keys())) ]

#----------------------------------------------------------------------------
# Adding tolerance to error to the metric name
#----------------------------------------------------------------------------

tolerances=[ np.sqrt(obs_[obs_.keys()[k]][1]) for k in range(1,len(obs_.keys()[:])) ]
accuracy=[ np.max(-int(np.log10(k)),0)+2 for k in tolerances ]
tolerances_=[ f'{tolerances[k]:.3g}' for k in range(len(tolerances)) ]
metrics_names=[ scores_.keys()[k]+', '+r'$\sigma=$'+f'{np.sqrt(obs_[obs_.keys()[k]][1]):.3g}' if ( scores_.keys()[k] in obs_.keys()[:] ) else scores_.keys()[k]  for k in range(1,len(scores_.keys()[:])) ]

#----------------------------------------------------------------------------
# Finalizing script
#----------------------------------------------------------------------------

plt.yticks(yticks,metrics_names)
plt.tight_layout()
plt.xlabel(r'$\epsilon/\sigma$')
#bbox=(0.985, 1.00)
bbox=(0.9, 1.00)
plt.legend(bbox_to_anchor=bbox,loc=2, borderaxespad=0.)
plt.savefig(name_fig)
print("La figure est enregistree dans : "+str(name_fig)) 
#plt.show()

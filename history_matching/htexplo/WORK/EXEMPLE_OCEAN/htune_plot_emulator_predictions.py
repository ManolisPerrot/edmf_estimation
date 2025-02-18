import csv
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import argparse
import glob

parser=argparse.ArgumentParser()
parser.add_argument("-w",help="list of waves to plot (by number)", metavar="wavesList", default="1")
parser.add_argument("-p",help="list of params to plot (by name)", metavar="paramList", default="all")
parser.add_argument("-y",help="ylim of the plots", metavar="ylim", default=None)
parser.add_argument("-n",help="plot every n points", metavar="npoints", default=None)
args=parser.parse_args()

# retrieve args
npoints = int(args.n) if args.n is not None else None
ylim = [float(u) for u in args.y.split(",")] if args.y is not None else None
paramList = args.p.split(",")
wavesList = [int(i) for i in args.w.split(",")]
maxwave = max(wavesList)

# fichiers qui contiennent les données (ref et predictions émulateurs)
f_references  = ["metrics_REF_%i.csv"%nwave for nwave in wavesList]
all_f_predictions = glob.glob("Predictions_Wave*.asc") #%maxwave
if len(all_f_predictions) == 0 : 
  print("error: could not find any Predictions_Wave*asc file.")
  print("Consider running\n  Rscript htune_emulator_predictions.R -wave %i\nand retry"%maxwave)
  exit(1)
all_f_predictions.sort()
for f in all_f_predictions: 
  wave_id = int(f.split("_Wave")[-1].split(".asc")[0])
  if wave_id >= maxwave:f_predictions = f ; break

print("Will plot file %s"%f_predictions)

def read_csv_file(f, sep=",", exclude_first_col=1):
  dat=[]
  with open(f) as csvfile:
    reader = csv.reader(csvfile, delimiter=sep)
    for row in reader: dat+= [row[exclude_first_col:]]
  return dat

# lire les références pour les différentes métriques
met_names  = []
met_values = []
met_uncs   = []
for f in f_references:
  nam,val,unc = read_csv_file(f)
  met_names  += [nam]
  met_values += [val]
  met_uncs   += [unc]

print(met_names, met_values)

# lire le fichier des prédictions
npar, nmet = [int(u) for u in open(f_predictions).readline()[1:].split()]
prediction_df = pd.read_csv(f_predictions, sep=" ", skiprows=1)
tab_parameters = prediction_df.iloc[:,:npar].to_numpy()
tab_metrics    = prediction_df.iloc[:,npar:-1]
vec_iwave_ruled_out = prediction_df.iloc[:,-1].to_numpy()
par_names = prediction_df.columns[:npar]

if "all" in paramList : paramList = par_names
npar_toplot = len(paramList)

fig,axes = plt.subplots(ncols=npar_toplot, figsize=(8*npar_toplot,6))
if npar_toplot == 1 : axes = [axes]

markers = [".","s","d"]
from mycolors import rainbow6 as cols
cols = cols[2:]
from mycolors import basic5 as cols
cols = cols[1:]
cols = plt.rcParams['axes.prop_cycle'].by_key()['color']

for iwave,wave in enumerate(wavesList):
  for imet,metric in enumerate(met_names[iwave]):
    label_mw = "%s_WAVE%i"%(metric,wave)
    expect = prediction_df["E_"+label_mw].to_numpy()
    emul_std = np.sqrt(prediction_df["V_"+label_mw].to_numpy())

    ruled_out_now = vec_iwave_ruled_out==wave
    not_ruled_out_yet = ~((vec_iwave_ruled_out!=0) & (vec_iwave_ruled_out<=wave))

    if npoints is not None :
      expect            = expect[::npoints]
      emul_std          = emul_std[::npoints]
      ruled_out_now     = ruled_out_now[::npoints]
      not_ruled_out_yet = not_ruled_out_yet[::npoints]

    iparam=-1
    for param in par_names:
      if not param in paramList: continue
      iparam += 1

      param_vals = tab_parameters[:,iparam]
      if npoints is not None : param_vals = param_vals[::npoints]

      plt.sca(axes[iparam])

      # les points qui ont été éliminés à cette vague en semi transparence
      l,_,_ = plt.errorbar(param_vals[ruled_out_now],
              expect[ruled_out_now], yerr=3*emul_std[ruled_out_now],
              ls="", marker=markers[imet], elinewidth=1, 
              alpha=.3, color=cols[iwave])

      # les points qui n'ont pas encore été éliminés 
      plt.errorbar(param_vals[not_ruled_out_yet],
              expect[not_ruled_out_yet], yerr=3*emul_std[not_ruled_out_yet],
              ls="", marker=markers[imet], elinewidth=1,
              color=cols[iwave], 
              label=label_mw)

      # la ref et son range d'incertitude
      ref = float(met_values[iwave][imet])
      std = np.sqrt(float(met_uncs[iwave][imet]))
      plt.axhline(ref, color="black", ls="-", lw=1)
      plt.axhline(ref-3*std, color="black", ls="--", lw=.5)
      plt.axhline(ref+3*std, color="black", ls="--", lw=.5)

      plt.ylabel(metric)

      if iwave==0:
        plt.plot([],[], color="black", label="Reference +- 3 std")
        plt.xlabel(param)
        plt.ylim(ylim)
  plt.legend(loc="upper right")
  plt.savefig("predictions_up_to_wave%i.png"%wave, dpi=360)
plt.show()

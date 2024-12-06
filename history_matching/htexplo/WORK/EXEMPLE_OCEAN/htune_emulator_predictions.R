#===============================================================================
#
# Loading emulators and plotting things
#    Authors : HighTune team, 2024
#
#===============================================================================

twd <- getwd()
library("lhs")
source("kLHC.R")
source('htune_convert.R')
library(reticulate)

#===============================================================================
# default values for optional arguments
#===============================================================================
WAVEN=1                     # Wave number of history matching (HM)
sample_size=200             # size of emulated sample (Xp)
print_level=0               # "debug" pour activer des prints diagnostics
n_std=1                     # how many std for error bars ?

#===============================================================================
# Diagnostics functions : size and time
#===============================================================================
htsize <- function(object,name) {
   print(paste(name,", type:",typeof(object),", length:",length(object),", memory:",format(object.size(object), units = "Mb"))) 
}
prev_time <- Sys.time()
httime <- function(where) {
   new_time <- Sys.time()
   print(paste("Time elapses in ",where," : ",new_time-prev_time)) 
}


#===============================================================================
# Reading line args
#===============================================================================
args = commandArgs(trailingOnly=TRUE)
if (length(args)%%2!=0) { print(paste("Bad number of arguments",length(args),"in htune_EmulatingMultiMetric.R")); q("no",1) ; }
if (length(args)>0) {
  for (iarg in seq(1,length(args),by=2)) {
    if (args[iarg]=="-wave") { WAVEN=as.numeric(args[iarg+1]) }
    else if (args[iarg]=="-sample_size") {sample_size=as.numeric(args[iarg+1]) }
    else { print(paste("Bad argument",args[iarg],"in htune_plot_emulators.R")) ; q("no",1) ; } # quit with error code 1 
  }
}


#===============================================================================
# Reading results of a series of SCM simulations
#===============================================================================

print(paste("Arguments : -wave",WAVEN,sep=" "))
source("ModelParam.R")

# load tData (one colum per parameter + Noise + metrics, one line per point)
# = where the model has been executed
load(file=paste("WAVE",WAVEN,"/Wave",WAVEN,"_SCM.Rdata",sep=""))

# load tObs 
# = one reference value per metric
load(file=paste("WAVE",WAVEN,"/Wave",WAVEN,"_REF.Rdata",sep=""))

ParNames <- names(tData)[1:(nparam+1)] # Selects columns with the parameters
MetricNames <- names(tData)[(nparam+2):(nparam+1+nmetrique)] # select columns with the metrics
param_SCM <- DesignConvert(tData[,1:nparam])
logs=array(1:nparam) ; for ( iparam in 1:nparam ) { logs[iparam]<-"" }
logs[which.logs] <- "x"

#===============================================================================
print("   ======   Reading emulators of previous waves  ========   ")
#===============================================================================

# sample sample_size points in parameter space
print(paste("Generating ",sample_size,"samples varying nparam input parameters"))
Xp <- as.data.frame(2*randomLHS(sample_size, nparam)-1)
names(Xp) <- ParNames[1:nparam]
design_true_parameter_space = DesignConvert(Xp)
param_vec_min = param.lows
param_vec_max = param.highs

# save the number of the wave when the point is ruled out
wave_when_ruled_out = rep(0, sample_size)

mogp_dir <- "./mogp_emulator"
source("BuildEmulator/BuildEmulator.R")
source('HistoryMatching/HistoryMatching.R')
source('HistoryMatching_addon.R')

EMULATOR.LIST <- list()
taufile="tau-cutoff.Rdata"

for (i in 1:WAVEN) {
  prefix=paste("WAVE",i,"/EMULATOR_MULT_METRIC_wave",i,sep="")
  if(file.exists(paste(prefix,".RData",sep="")) && file.exists(paste(prefix,"_mogp",sep=""))) {
      EMULATOR.LIST[[i]] = load_ExUQmogp(prefix)
      print(paste("An emulator has been loaded from ",prefix,sep=""))
  } 
}
if (file.exists(taufile)) { load(taufile) }

file = paste("WAVE",WAVEN,"/Plots_Predictions.pdf",sep="")
pdf(file=file)

#==========================================================================
    print(paste("==== Computing Emulator Predictions for wave ",WAVEN," ====="))
#==========================================================================

colors = c("black", "blue", "green", "red", "cyan", "magenta")

nparam_to_plot=1
par(mfrow=c(nmetrique, nparam_to_plot))

table_to_write     = design_true_parameter_space
names_metric_table = c()

for (k_wave in 1:WAVEN) {
  Emulator = EMULATOR.LIST[[k_wave]]
  # init max implausibility vector
  # pour éliminer les points dont le max(implaus)_nmetrique > cutoff
  max_implausibilite = rep(-9999, sample_size)

  # je prends cette fonction dans HistoryMatching/HistoryMatching.R
  # je pense que c'est elle qui fait les prédictions pour les paramètres Xp
  tEmulator <- Emulator$mogp$predict(as.matrix(Xp), deriv=FALSE)

  for (k_metric in 1:Emulator$mogp$n_emulators) {
    # la prédiction contient un champ "mean" et un champ "unc"
    Emul_expectation = tEmulator$mean[k_metric,]
    Emul_variance    = tEmulator$unc[k_metric,]
    Emul_std         = sqrt(Emul_variance)

    # implausibilité pour cette métrique
    Implausibilite = abs(tObs[k_metric] - Emul_expectation)/
      sqrt(Emul_variance + tObsErr[k_metric])

    # max des implausibilités sur les métriques
    for (k_point in 1:sample_size) { max_implausibilite[k_point] = max(max_implausibilite[k_point], Implausibilite[k_point]) }


    # pour le plot : min et max des barres d'erreurs
    Emul_val_min     = Emul_expectation - Emul_std*n_std
    Emul_val_max     = Emul_expectation + Emul_std*n_std

    # concatenate expectation and variance for this metric and this wave
    # to table_to_write, which will be dumped to ascii file
    table_to_write = cbind(table_to_write, Emul_expectation, Emul_variance)

    # concatenate names of expectation and variance of this metric
    label_e = paste("E_",MetricNames[k_metric],"_WAVE",k_wave,sep="")
    label_v = paste("V_",MetricNames[k_metric],"_WAVE",k_wave,sep="")
    names_metric_table = c(names_metric_table, label_e, label_v)
  
    ylim = c(min(Emul_val_min), max(Emul_val_max))
    ylim = c(-0.1,1.1)
    
    for (k_param in 1:nparam_to_plot) {
      vec_param = design_true_parameter_space[,k_param]
      xlim = c(param_vec_min[k_param], param_vec_max[k_param])
  
      par(mfg=c(k_metric,k_param))

      # espérances 
      plot(vec_param, Emul_expectation, 
           xlim = xlim, ylim = ylim, 
           xlab = ParNames[k_param],
           ylab = MetricNames[k_metric],
           col = colors[k_wave])
  
      # barres d'erreur
      arrows(vec_param, Emul_val_min, 
             vec_param, Emul_val_max,
             length=0.05, angle=90, code=3, 
             col=colors[k_wave])
    }
  }
  wave_when_ruled_out[wave_when_ruled_out==0 &
                      max_implausibilite>cutoff_vec[k_wave]] = k_wave
}
dev.off() # fin du plotting

##### ECRITURE DES DONNES DANS UN FICHIER ASCII #####
# nparam premières colonnes = les paramètres
# ensuite, couples de colonnes (Espérance,Variance)
# pour chaque métrique et chaque vague
# une ligne par point échantillonné dans l'espace des paramètres

# nom du fichier où va être dumpée la table
UFILE=paste("Predictions_Wave",WAVEN,".asc",sep="")

# ajoute la colonne qui dit à quelle vague le point a été éliminé
table_to_write = cbind(table_to_write, wave_when_ruled_out)

# affecte des noms aux colonnes de la table qui va être dumpée dans UFILE
names(table_to_write) = c(ParNames[1:nparam], names_metric_table, "nwave_ruled_out")

# dump la table dans le fichier
write(paste("#", nparam, nmetrique, sep=" "), file=UFILE)
write.table(table_to_write, file=UFILE, row.names=FALSE, col.names=TRUE, append=TRUE)

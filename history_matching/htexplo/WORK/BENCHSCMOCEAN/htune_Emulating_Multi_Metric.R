###########################################################################################
# Computing emulators and History Matching using Exeter software
# Central procedure of the HighTune soft
# Developed during coding sprints of the HighTune project
#    Authors : HighTune team, 2017
#
# Main changes :
#    Change from old rstan version of the Exeter R codes to Mogp version based
#    R, python and C and ported on GPU (Daniel Williamson, ~ 2019)
#
###########################################################################################

twd <- getwd()
source('htune_convert.R')

library(reticulate)


#=============================================
# default values for optional arguments
#=============================================
WAVEN=1
tau=0
cutoff=3
sample_size=20000
sample_size_next_design=80

#=============================================
# Reading line args
#=============================================
args = commandArgs(trailingOnly=TRUE)
if (length(args)%%2!=0) { print(paste("Bad number of arguments",length(args),"in htune_EmulatingMultiMetric.R")); q("no",1) ; }
if (length(args)>0) {
  for (iarg in seq(1,length(args),by=2)) {
    if (args[iarg]=="-wave") { WAVEN=as.numeric(args[iarg+1]) }
    else if (args[iarg]=="-tau") {tau=as.numeric(args[iarg+1]) }
    else if (args[iarg]=="-cutoff") {cutoff=as.numeric(args[iarg+1]) }
    else if (args[iarg]=="-sample_size") {sample_size=as.numeric(args[iarg+1]) }
    else if (args[iarg]=="-sample_size_next_design") {sample_size_next_design=as.numeric(args[iarg+1]) }
    else { print(paste("Bad argument",args[iarg],"in htune_EmulatingMultiMetric.R")) ; q("no",1) ; } # quit with error code 1 
  }
}

#===============================================
# Reading results of a series of SCM simulations
#===============================================
print(paste("Arguments : -wave",WAVEN,"-cutoff",cutoff,"-tau",tau,sep=" "))
source("ModelParam.R")
load(file=paste("WAVE",WAVEN,"/Wave",WAVEN,"_SCM.Rdata",sep=""))
load(file=paste("WAVE",WAVEN,"/Wave",WAVEN,"_REF.Rdata",sep=""))

if ( nmetrique == 1) { tau=0 }

cands <- names(tData)[1:(nparam+1)] # Selects columns with the parameters
metric <- names(tData)[(nparam+2):(nparam+1+nmetrique)] # select columns with the metrics
print("History Matching for parameters: ")
print(cands[1:(nparam+1)])
print(c("nmetrique,tau=",nmetrique,tau))

#====================================================================
print("  ========   Scatter plot metrcis=f(param)   ======== ")
#====================================================================
# Ploting for each parameter, the metric as a fuction of parameter values:
# directly from the SCM outputs
# Organizing sub-windows as a fuction of the number of plots
# For ploting with real prameters as axis

file = paste("WAVE",WAVEN,"/Plots_Metrics.pdf",sep="")
pdf(file=file)

param_SCM <- DesignConvert(tData[,1:nparam])
logs=array(1:nparam) ; for ( iparam in 1:nparam ) { logs[iparam]<-"" }
logs[which.logs] <- "x"
if(nparam*nmetrique<2){ par(mfrow = c(1, 1), mar=c(4, 4, 1, 1)) 
} else if(nparam*nmetrique <=4){ par(mfrow = c(2, 2), mar=c(4, 4, 1, 1)) 
} else if(nparam*nmetrique<=9){ par(mfrow = c(3, 3), mar=c(4, 4, 1, 1)) 
} else if(nparam*nmetrique<=16){ par(mfrow = c(4, 4), mar=c(4, 4, 1, 1))
} else if(nparam*nmetrique<=25){ par(mfrow = c(5,5), mar=c(4, 4, 1, 1)) }
for (j in 1:nmetrique) {
        print(paste("Metrique [",j,"]",metric[j],"  obs : ",tObs[j],"   err : ",tObsErr[j]))
}
for ( iparam in 1:nparam ) {
  for (j in 1:nmetrique) {
    ymin=tObs[j]-sqrt(tObsErr[j])
    ymax=tObs[j]+sqrt(tObsErr[j])
    plot(param_SCM[,iparam],tData[,nparam+j+1],col=2,xlab=cands[iparam],ylab=metric[j],log=logs[iparam],ylim=range(tData[,nparam+j+1],ymin,ymax))
    abline(v=param.defaults[iparam],col='blue',lty=2)
    abline(h=c(tObs[j],ymin,ymax ), col = 'blue', lty =2, lwd=c(1,3,3))
  }
}
dev.off()

print(paste("OK0"))
print(paste("Created figure file: ", file, sep=""))

#################################################################
print("   ======   Starting of edits for New UQ codes  =========   ")
#################################################################

#First, must name a string with the directory that mogp_emulator lives in. YOURS IS NECESSARILY DIFFERENT TO MINE SO THIS SHOULD BE PASSED IN THE COMMAND LINE.
# mogp_dir <- "~/Dropbox/BayesExeter/mogp_emulator"
mogp_dir <- "./mogp_emulator"
source("BuildEmulator/BuildEmulator.R")

#################################################################
#DW as normal version for a few lines
EMULATOR.LIST <- list()
tau_vec = c()
cutoff_vec = c()
taufile="tau-cutoff.Rdata"

for (i in 1:WAVEN) {
  prefix=paste("WAVE",i,"/EMULATOR_MULT_METRIC_wave",i,sep="")
  if(file.exists(paste(prefix,".RData",sep="")) && file.exists(paste(prefix,"_mogp",sep=""))) {
      EMULATOR.LIST[[i]] = load_ExUQmogp(prefix)
      print(paste("An emulator has been loaded from ",prefix,sep=""))
  } 
}
if (file.exists(taufile)) { load(taufile) }

if ( length(EMULATOR.LIST) == WAVEN ) {
  # We shall overwrite the cutoff or tau for the last wave
  tau_vec[WAVEN]=tau
  cutoff_vec[WAVEN]=cutoff
} else {
  #DW Back to new codes and explanations
  #################################################################
  # Building emulator for the new WAVE (if not already done)
  #################################################################
  # variables 1:nparam correspond to input parameters
  # additionalVariables can still be specified, see MOGP_documentation.
  #     It can be decided or not to add part or all the other variables
  #     They are then specified in the additionalVariables
  #     if adding x3 to x1 and x2, puting names(tData)[3] or names(tData)[1:3] is equivalent.
  #========================================================
  # First fitting metrics (columns nparam+2:nparam+1+nmetrique of tData from file SCM.Rdata) with a linear model "lm" and then fitting mogp to whole object:
  #========================================================
  # maxOrder is the max number of fourier modes (see new documentation to change this)
  # maxdf : max number of degree of freedom = number of fuctions retained in the linear model (see new documentation to change this.)
  # This should be adapted as a function of the number of simulations
  # Choices a list of choices per emulator. See new documentation for how to change and what the defaults do (some terms e.d. maxdf are as before.) 
  #meanFun defaults to "fitted" which calls our usual lm fits. Can be set to "linear" to give e.g. x1+x2+x3+..x_nparam
  #kernel vector of kernels for each emulator or a single kernel. "Gaussian is the default. We have Matern52 implemented with more coming.
  #################################################################
  
  listnew <-lapply(1:nmetrique,function(k) names(tData[1:nparam])) # Est ce que ça fait vraiment ce qu'on veut ?
  #myem.lm <-InitialBasisEmulators(tData=tData,HowManyEmulators=nmetrique,additionalVariables = listnew)
  # DANNY CHANGE NUMBER 1. THIS IS A DANGEROUS DEFAULT CALL THAT SHOULD BE REPLACE:
  #additionalVariables=listnew means that all parameters are fitted in the Gaussian process, which is generally bad.
  #The default in ExeterUQ (when additionalVariables=NULL) is to include all parameters that
  #were highlighted as active by the stepwise regression, but maybe not included due to limits on 
  #available degrees of freedom. additionalVariables allows variables we think should be important 
  #to be forced into the emulator even if they didn't show up in the regression phase.
  #DW Note different function name with same calling protocol. (Enjoy the speed :) )
  # myem.lm <- BuildNewEmulators(tData=tData,HowManyEmulators=nmetrique,additionalVariables = NULL) #can still change additionalVariables to listnew if wanted.

############################################################################################
print("  ==============      Building emulators    ============== ")
############################################################################################
  # Modif DW: "I am soon pushing a different default here, and it is better for high tune to have the old default."
  myem.lm <- BuildNewEmulators(tData=tData,HowManyEmulators=nmetrique,additionalVariables = NULL, meanFun="fitted")
  
  file = paste("WAVE",WAVEN,"/Plots_LOO.pdf",sep="")
  pdf(file=file)
  #DIAGNOSTICS : verifying that the original SCMdata are well reproduced when eliminating the point from the emulator
  tvars <- rep(NA, nmetrique)
  terrs <- rep(NA, nmetrique)
  for (i in 1:nmetrique) {
############################################################################################
    print(paste("          ====== Computing LOO for metrique ",i,"   ======       "))
############################################################################################
    tLOOs1 <- LOO.plot(Emulators = myem.lm, which.emulator=i, ParamNames=names(tData)[1:nparam], OriginalRanges = TRUE, 
                       RangeFile = "ModelParam.R",
                       Obs=tObs[i], ObsErr = tObsErr[i], ObsRange=FALSE)
    terrs[i] <- (tLOOs1[,1]-tData[,nparam+i+1])^2
    tvars[i] <- ((tLOOs1[,3]-tLOOs1[,1])/2)^2
    print(paste("mean(emulator error/training data set): ",sqrt(mean(terrs[i])),"\t mean (emulator std-deviation for each prediction)",sqrt(mean(tvars[i])),sep=""))
  }
  dev.off()
  
############################################################################################
  print("  ==============      Saving emulators    ============== ")
############################################################################################
  EMULATOR.LIST[[WAVEN]] = myem.lm
  tau_vec[WAVEN] = tau
  #SAVE EMULATOR FOR HISTORY MATCHING
  cutoff_vec[WAVEN] = cutoff
  for (i in 1:WAVEN) {
    prefix=paste("WAVE",i,"/EMULATOR_MULT_METRIC_wave",i,sep="")
    save_ExUQmogp(EMULATOR.LIST[[i]], filename=prefix)
    print(paste("An emulator has been saved under: ",prefix,sep=""))
  }
  save(tau_vec, cutoff_vec, file = taufile)
}

############################################################################################
print("  ==============     Begining history matching     ============== ")
############################################################################################

source('HistoryMatching/HistoryMatching.R')
print(paste("Generating ",sample_size,"samples varying nparam input parameters"))
Xp <- as.data.frame(2*randomLHS(sample_size, nparam)-1)
names(Xp) <- names(tData)[1:nparam]
Disc = rep(0, nmetrique)

totonew<-DesignantiConvert1D(param.defaults)
param.defaults.norm=rep(0,nparam)
nbatches=500
for (i in 1:nparam) {param.defaults.norm[i]=totonew[i,]}

if(WAVEN == 1) {

############################################################################################
  print(paste("========   Computing implausibility for wave ",WAVEN,"    ======="))
############################################################################################

  Timps <- ImplausibilityMOGP(NewData=Xp, Emulator=EMULATOR.LIST[[1]], Discrepancy=Disc, Obs=tObs, ObsErr=tObsErr)
  ImpData_wave1 = cbind(Xp, Timps)
  VarNames <- names(Xp)
  valmax = tau_vec[1] + 1
  ImpListM1 = CreateImpList(whichVars = 1:nparam, VarNames=VarNames, ImpData=ImpData_wave1, nEms=EMULATOR.LIST[[1]]$mogp$n_emulators, whichMax=valmax)
  imp.layoutm11(ImpListM1,VarNames,VariableDensity=FALSE,newPDF=TRUE,the.title=paste("InputSpace_wave",WAVEN,".pdf",sep=""),newPNG=FALSE,newJPEG=FALSE,newEPS=FALSE,Points=matrix(param.defaults.norm,ncol=nparam))
  
  NROY1 <- which(rowSums(Timps <= cutoff_vec[1]) >=EMULATOR.LIST[[1]]$mogp$n_emulators - tau_vec[1])
  TMimpls_wave1 <- apply(Timps, 1,MaxImp,whichMax=valmax)
  XpNext <- Xp[NROY1, ]
  mtext(paste("Remaining space:",length(NROY1)/dim(Xp)[1],sep=""), side=1)
  
  # number of plausible members divided by total size -> fraction of space retained after wave N
############################################################################################
  print(paste("Remaining space after wave 1: ",length(NROY1)/dim(Xp)[1],sep=""))
############################################################################################
  cat(length(NROY1)/dim(Xp)[1],file="Remaining_space_after_wave_1.txt", sep="")
  print("que fait on la")

} else {

  XpNext = Xp
  NROY.list = list()
  Impl.list = list()
  for(i in 1:(length(EMULATOR.LIST))) {

############################################################################################
    print(paste("========   Computing implausibility for wave ",i,"/",WAVEN,"    ======="))
############################################################################################

    Timps = ImplausibilityMOGP(NewData=XpNext, Emulator=EMULATOR.LIST[[i]],
                               Discrepancy=Disc, Obs=tObs, ObsErr=tObsErr)
    valmax = tau_vec[i] + 1
    print(c("cutoff",i,cutoff_vec[i]))
    Impl.list[[i]] = matrix(apply(Timps, 1,MaxImp,whichMax=valmax), ncol = 1)
    NROY.list[[i]] = which(rowSums(Timps <= cutoff_vec[i]) >= EMULATOR.LIST[[i]]$mogp$n_emulators - tau_vec[i])
    XpNext = XpNext[NROY.list[[i]], ]
    print(paste("Remaining space after wave",i,": ",length(NROY.list[[i]])/dim(Xp)[1],sep=""))
    cat(length(NROY.list[[i]])/dim(Xp)[1],file=paste("Remaining_space_after_wave_",i,".txt", sep=""),sep="")
  }
  Impl.list[[length(EMULATOR.LIST)]] = Timps
  ImpData <- ImpDataWaveM(Xp, NROY.list, Impl.list)
  VarNames <- names(Xp)
  ImpList <- CreateImpListWaveM(whichVars = 1:nparam, VarNames=VarNames, ImpData = ImpData,
                                nEms=EMULATOR.LIST[[length(EMULATOR.LIST)]]$mogp$n_emulators, Resolution=c(15,15), whichMax=valmax)
  imp.layoutm11(ImpList,VarNames,VariableDensity=FALSE,newPDF=TRUE,the.title=paste("InputSpace_wave",WAVEN,".pdf",sep=""),newPNG=FALSE,newJPEG=FALSE,newEPS=FALSE,Points=matrix(param.defaults.norm,ncol=nparam))
  mtext(paste("Remaining space:",length(NROY.list[[length(EMULATOR.LIST)]])/dim(Xp)[1],sep=""), side=1)
}

############################################################################################
print(paste("Created figure file: ", "InputSpace_wave",WAVEN,".pdf", sep=""))
############################################################################################


################################################################################
# Creation of Wave WAVEN+1 sample
################################################################################

if (nrow(XpNext)>=sample_size_next_design) { samplesz=sample_size_next_design } else { samplesz=nrow(XpNext)
print(paste("Final Sample size reduced to ",samplesz))
}

design.waveNext <- sample(nrow(XpNext), samplesz, rep = F)
WaveNext <- XpNext[design.waveNext, ]
save(WaveNext,file=paste("Wave",strtoi(WAVEN, base = 0L)+1,".RData",sep=""))
print(paste("Next wave design has been saved under: ","Wave",strtoi(WAVEN, base = 0L)+1,".RData",sep=""))
#} else { print("The NROY space is not large enough to allow resampling for next wave") }

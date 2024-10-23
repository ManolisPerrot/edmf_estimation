twd <- getwd()
source('htune_convert.R')

#=============================================
# default values for optional arguments
#=============================================
WAVEN=1
tau=0
cutoff=3
sample_size=1000000
sample_size=40000000
sample_size=5000000
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
  else if (args[iarg]=="-emulist") {cutoff=as.numeric(args[iarg+1]) }
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
# Scatter plot
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

print(paste("Created figure file: ", file, sep=""))


#################################################################
# Loading emulator for previous waves if it exists
#################################################################
source('BuildEmulator/BuildEmulator.R')
options(mc.cores = parallel::detectCores())
EMULATOR.LIST <- list()
tau_vec = c()
cutoff_vec = c()

if(file.exists("EMULATOR_LIST_MULT_METRIC.RData")) { load("EMULATOR_LIST_MULT_METRIC.RData") }

if ( length(EMULATOR.LIST) == WAVEN ) {
	# We shall ovrewride the cutoff or tau for the last wave
	tau_vec[WAVEN]=tau
	cutoff_vec[WAVEN]=cutoff


} else {
#################################################################
# Building emulator for the new WAVE (if not already done)
#################################################################
# variables 1:nparam correspond to input parameters
# FastVersion = TRUE. Acceletes the following but less reliable.
# nugget : white noise. Variance, square of standard deviation with same unit as SCMdata.
# additionalVariables :
#     The first linear fit may have kept only input parameters x1 and x2 for instance
#     It can be decided or not to add part or all the other variables
#     They are then specified in the additionalVariables
#     if adding x3 to x1 and x2, puting names(tData)[3] or names(tData)[1:3] is equivalent.
#     !!! CAUTION !!! InitialBasisEmulators has linear fit +gpstan
#========================================================
# First fitting metrics (columns nparam+2:nparam+1+nmetrique of tData from file SCM.Rdata) with a linear model "lm" :
#========================================================
# maxOrder is the max number of fourier modes
# maxdf : max number of degree of freedom = number of fuctions retained in the linear model
# This should be adapted as a function of the number of simulations
#################################################################

	listnew <-lapply(1:nmetrique,function(k) names(tData[1:nparam])) # Est ce que ça fait vraiment ce qu'on veut ?
       	myem.lm <-InitialBasisEmulators(tData=tData,HowManyEmulators=nmetrique,additionalVariables = listnew)
	for(i in 1:nmetrique) myem.lm[[i]]$StanModel = NULL
	file = paste("WAVE",WAVEN,"/Plots_LOO.pdf",sep="")
	pdf(file=file)
	#DIAGNOSTICS : verifying that the original SCMdata are well reproduced when eliminating the point from the emulator
	for (i in 1:nmetrique) {
		tLOOs1 <- LOO.plot(StanEmulator = myem.lm[[i]], ParamNames=names(tData)[1:nparam])
	}
	dev.off()

	EMULATOR.LIST[[WAVEN]] = myem.lm
	tau_vec[WAVEN] = tau
	#SAVE EMULATOR FOR HISTORY MATCHING
	cutoff_vec[WAVEN] = cutoff
	save(EMULATOR.LIST, tau_vec, cutoff_vec, file = "EMULATOR_LIST_MULT_METRIC.RData")
	print(paste("A list of emulators has been saved under: ","EMULATOR_LIST_MULT_METRIC.RData",sep=""))
}


#######################################################################################################
# Starting history matching or iterative refocusing
#######################################################################################################

source('HistoryMatching/HistoryMatching.R')
# Generating 10000 samples varying nparam input parameters
Xp <- as.data.frame(2*randomLHS(sample_size, nparam)-1)
names(Xp) <- names(tData)[1:nparam]
Disc = rep(0, nmetrique)

totonew<-DesignantiConvert1D(param.defaults)
param.defaults.norm=rep(0,nparam)
nbatches=500
for (i in 1:nparam) {param.defaults.norm[i]=totonew[i,]}

if(WAVEN == 1) {
  Timps <- ManyImplausibilitiesStan(NewData=Xp, Emulator=EMULATOR.LIST[[1]], Discrepancy=Disc,
                                    Obs=tObs, ObsErr=tObsErr, is.GP=NULL,FastVersion = TRUE, 
                                    multicore=(ceiling(dim(Xp)[1]/nbatches)>1), batches=nbatches) # Multicore only if Xp is large enough
  ImpData_wave1 = cbind(Xp, Timps)
  VarNames <- names(Xp)
  valmax = tau_vec[1] + 1
  ImpListM1 = CreateImpList(whichVars = 1:nparam, VarNames=VarNames, ImpData=ImpData_wave1, nEms=length(EMULATOR.LIST[[1]]), whichMax=valmax)
  imp.layoutm11(ImpListM1,VarNames,VariableDensity=FALSE,newPDF=TRUE,the.title=paste("InputSpace_wave",WAVEN,".pdf",sep=""),newPNG=FALSE,newJPEG=FALSE,newEPS=FALSE,Points=matrix(param.defaults.norm,ncol=nparam))
  
  NROY1 <- which(rowSums(Timps <= cutoff_vec[1]) >=length(EMULATOR.LIST[[1]]) - tau_vec[1])
  TMimpls_wave1 <- apply(Timps, 1,MaxImp,whichMax=valmax)
  XpNext <- Xp[NROY1, ]
  mtext(paste("Remaining space:",length(NROY1)/dim(Xp)[1],sep=""), side=1)
 

  # number of plausible members divided by total size -> fraction of space retained after wave N
  print(paste("Remaining space after wave 1: ",length(NROY1)/dim(Xp)[1],sep=""))
  cat(length(NROY1)/dim(Xp)[1],file="Remaining_space_after_wave_1.txt", sep="")
  print("que fait on la")
  
} else {
  XpNext = Xp
  NROY.list = list()
  Impl.list = list()
  for(i in 1:(length(EMULATOR.LIST))) {
    Timps = ManyImplausibilitiesStan(NewData=XpNext, Emulator=EMULATOR.LIST[[i]], Discrepancy=Disc,
                                     Obs=tObs, ObsErr=tObsErr, is.GP=NULL,FastVersion = TRUE, 
                                     multicore=(ceiling(dim(XpNext)[1]/nbatches)>1), batches=nbatches) # Multicore only if XpNext is large enough
    valmax = tau_vec[i] + 1
  print(c("cutoff",i,cutoff_vec[i]))
    Impl.list[[i]] = matrix(apply(Timps, 1,MaxImp,whichMax=valmax), ncol = 1)
    NROY.list[[i]] = which(rowSums(Timps <= cutoff_vec[i]) >= length(EMULATOR.LIST[[i]]) - tau_vec[i])
    XpNext = XpNext[NROY.list[[i]], ]
    print(paste("Remaining space after wave",i,": ",length(NROY.list[[i]])/dim(Xp)[1],sep=""))
    cat(length(NROY.list[[i]])/dim(Xp)[1],file=paste("Remaining_space_after_wave_",i,".txt", sep=""),sep="")
  }
  Impl.list[[length(EMULATOR.LIST)]] = Timps
  ImpData <- ImpDataWaveM(Xp, NROY.list, Impl.list)
  VarNames <- names(Xp)
  ImpList <- CreateImpListWaveM(whichVars = 1:nparam, VarNames=VarNames, ImpData = ImpData,
                                 nEms=length(EMULATOR.LIST[[length(EMULATOR.LIST)]]), Resolution=c(15,15), whichMax=valmax)
  imp.layoutm11(ImpList,VarNames,VariableDensity=FALSE,newPDF=TRUE,the.title=paste("InputSpace_wave",WAVEN,".pdf",sep=""),newPNG=FALSE,newJPEG=FALSE,newEPS=FALSE,Points=matrix(param.defaults.norm,ncol=nparam))
  mtext(paste("Remaining space:",length(NROY.list[[length(EMULATOR.LIST)]])/dim(Xp)[1],sep=""), side=1)
}

print(paste("Created figure file: ", "InputSpace_wave",WAVEN,".pdf", sep=""))


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

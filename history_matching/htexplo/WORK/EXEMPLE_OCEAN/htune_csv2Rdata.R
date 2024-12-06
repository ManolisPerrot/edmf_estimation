###############################################################################
# Auteurs : Ionela Musat
# Modif 2018/10/04 : F. Couvreux
# Adapted for 1D outputs
# Reads csv file with metrics already computed and stored in Rdata file
###############################################################################


# Old interface where only the wave number was passed as an argument
WAVEN=1
ParFile=""
RefFile=""
SimFile=""
MainDir=""
RdataFile=""

#-----------------------------------------------------------------------------
#  Arguments
#-----------------------------------------------------------------------------
iarg=1
args = commandArgs(trailingOnly=TRUE)
while ( iarg <= length(args) )  {
    print(c("iarg1=",iarg))
         if (args[iarg]=="-ref" ) { RefFile=args[iarg+1]   ; iarg=iarg+2 }
    else if (args[iarg]=="-sim" ) { SimFile=args[iarg+1]   ; iarg=iarg+2 }
    else if (args[iarg]=="-par" ) { ParFile=args[iarg+1]   ; iarg=iarg+2 }
    else if (args[iarg]=="-dir" ) { MainDir=args[iarg+1]   ; iarg=iarg+2 }
    else                          { WAVEN=args[iarg]       ; iarg=iarg+1 }
    print(c("iarg2=",iarg))
}

print(c("WAVEN=",WAVEN))

source("ModelParam.R")


#-----------------------------------------------------------------------------
# Default file names . Alone until svn 342
#-----------------------------------------------------------------------------
if (MainDir=="") { MainDir=paste("WAVE",WAVEN,"/",sep="") } else { MainDir=paste(MainDir,"/",sep="") }
if (SimFile=="") { SimFile=paste("metrics_WAVE",WAVEN,"_",WAVEN,".csv",sep="") }
if (RefFile=="") { RefFile=paste("metrics_REF_",WAVEN,".csv",sep="") }

RefFile=paste(MainDir,RefFile,sep="")
SimFile=paste(MainDir,SimFile,sep="")
print(c("SimFile",SimFile))
print(c("RefFile",RefFile))
print(c("MainDir",MainDir))


#-----------------------------------------------------------------------------
#  Reading parameters
#  Option 1 : from WAVEN/WaveN.RData created automatically by HM
#  Option 2 : from ParFile from option -par
#-----------------------------------------------------------------------------

if (ParFile=="") {
   load(paste(MainDir,"Wave",WAVEN,".RData",sep=""))
} else {
   ParFile=paste(MainDir,ParFile,sep="")
   print(c("ParFile",ParFile))
   source("htune_convert.R")
   PhysicsParams<-read.csv(ParFile,sep=" ")
   # Transforming parameters to [-1,1]
   wave_param_US=cbind(PhysicsParams["t_IDs"],DesignantiConvert(PhysicsParams[,][2:length(PhysicsParams[1,])]))
}
print(wave_param_US)
NRUNS=dim(wave_param_US)[1]
nparam=dim(wave_param_US)[2]-1
print(NRUNS)


#-----------------------------------------------------------------------------
# Read metric file for REF
#-----------------------------------------------------------------------------

metREF <- read.csv(RefFile, header = TRUE, sep=",")
nmetrique=dim(metREF)[2]-1

metric_les_array<-metREF[,1:nmetrique+1]
tObs=matrix(c(rep(0,nmetrique)),ncol=nmetrique)
tObsErr=matrix(c(rep(0,nmetrique)),ncol=nmetrique)


#-----------------------------------------------------------------------------
# Not fully understood problem with array dimensions
# in the case where there is one metric only
#-----------------------------------------------------------------------------

print(metREF)
if (nmetrique==1) {metric_les_array<-metREF[0:nmetrique+1,]
   tObs[1]=metric_les_array[1,2]
   tObsErr[1]=metric_les_array[2,2]
} else {metric_les_array<-metREF[,1:nmetrique+1]
   for (i in 1:nmetrique) {
      tObs[i]=metric_les_array[1,i]
      tObsErr[i]=metric_les_array[2,i]
   }
}
PFILE=paste(MainDir,"Wave",WAVEN,"_REF.Rdata",sep="")
save(tObs,tObsErr,nmetrique,file=PFILE)
head(c('tObs',tObs))
head(c('tObsErr',tObsErr))


#-----------------------------------------------------------------------------
#Read metric file for SCM
#-----------------------------------------------------------------------------

met1D <- read.csv(SimFile, header = TRUE, sep=",")
print(met1D)
# 2.2 add input uncertainty by generating random white noise
std = 0.05
Noise = rnorm(NRUNS,0,std)
print("Test")
print(nrow(wave_param_US[, 1:nparam+1]))
print(length(Noise))
print(nrow(met1D))
tData=cbind(wave_param_US[,1:nparam+1],Noise)
print("Test1")

tData=cbind(tData,met1D[,1:nmetrique+1])
print("Test2")
## later we should be able to put multiple metrics in this array (EOFs coeff)
names(tData)[(1+nparam):(1+nparam+nmetrique)]<-c("Noise",names(met1D[1:nmetrique+1]))  


# 4. Save scaled and unscaled param to data files
print("Save data")

#if (WAVEN == 1) {save(wave_param_US,file=PFILE)}
PFILE=paste(MainDir,"Wave",WAVEN,"_SCM.Rdata",sep="")

save(tData,nparam,NRUNS,nmetrique,file=PFILE)
head(tData)

quit()


#Step 1 Source files and load data
source('BuildEmulator/BuildEmulator.R')
source("BuildEmulator/DannyDevelopment.R")
source("BuildEmulator/Rotation.R")
source("HistoryMatching/HistoryMatchingFast.R")
library("ncdf4") # to manipulate ncdf

#########################
# First settings

case_name="AYOTTE"
subcase_name="24SC"
variable="theta" # qv ou rneb # Don't use "var" which is un R function !!!

WAVEN=1

source('htune_case_setup.R')
file = paste("WAVE",WAVEN,"/Wave",WAVEN,".RData",sep="")
load(file)

casesu <-case_setup(case_name)
NLES=casesu[1]
TimeLES=casesu[2]
TimeSCM=casesu[3]

NRUNS=dim(wave_param_US)[1]
nparam=dim(wave_param_US)[2]-1

#########################
# Get vertical grid to project everything
print("Get vertical grid")

file=paste("WAVE",WAVEN,"/",case_name,"/",subcase_name,"/SCM-",WAVEN,"-001.nc",sep="")
print(file)
nc =  nc_open(file)
zf = ncvar_get(nc,"zf")
zfSCM = zf[,1]
nlev = length(zfSCM)
nc_close(nc)

# Get vertical grid of LES
file = paste("LES/",case_name,"/",subcase_name,"/LES",0,".nc",sep="")
nc =  nc_open(file)
zfLES = ncvar_get(nc,"zf")
nc_close(nc)

# Extract the SCM vertical below the top of the LES
zgrid = rep(0,nlev)
ii = 1
maxzLES = max(zfLES)
minzLES = min(zfLES)
for (k in 1:nlev) {
  if ( zfSCM[k] <= maxzLES & zfSCM[k] >= minzLES ) {
    zgrid[ii] = zfSCM[k]
    ii = ii +1
  }
}
zgrid=zgrid[1:ii-1]
nlevout = length(zgrid)[1]

print("Chosen vertical grid:")
print(zgrid)

#########################
# Interpolate LES data on the chosen vertical grid
print("Interpolate LES data on the chosen vertical grid")

dataLES = matrix(0,ncol=NLES+2,nrow=nlevout)
dataLES[,1] = zgrid

for ( k in 0:(NLES-1) ) {
  file = paste("LES/",case_name,"/",subcase_name,"/LES",k,".nc",sep="")
  nc =  nc_open(file)
  zf = ncvar_get(nc,"zf")
  data = ncvar_get(nc,variable)
  nc_close(nc)

  tempFun <- approxfun(zf,data[,TimeLES],yleft=data[1,TimeLES])
  dataLES[,k+2] <- tempFun(zgrid)  
  
#  if ( k == 0 ) {
#    # Check the interpolation
#    plot(x=dataLES[,k+2],y=dataLES[,1],type='l')
#    lines(x=data[,TimeLES],y=zf,col="red") 
#  }
}

# Compute observation uncertainty
for ( k in 1:nlevout ) {
  dataLES[k,NLES+2] = sd(dataLES[k,2:NLES+1])^2
}

#save(dataLES,file="dataLES.RData")
#load("dataLES.RData")

#########################
# Interpolate SCM data on the chosen vertical grid
print("Interpolate SCM data on the chosen vertical grid")

dataSCM = matrix(0,ncol=NRUNS+1,nrow=nlevout)
dataSCM[,1] = zgrid

for ( k in 1:NRUNS ) {
  i = sprintf("%03i",k)
  file=paste("WAVE",WAVEN,"/",case_name,"/",subcase_name,"/SCM-",WAVEN,"-",i,".nc",sep="")
  nc =  nc_open(file)
  zf = ncvar_get(nc,"zf")
  data = ncvar_get(nc,variable)
  nc_close(nc)
  nlev = dim(zf)[1]
  
  # yright, yleft to constrain what happen at the edge. Not clear yet how to do it properly
  tempFun <- approxfun(zf[,TimeSCM],data[,TimeSCM],yright=data[1,TimeSCM],yleft=data[nlev,TimeSCM])
  dataSCM[,k+1] <- tempFun(zgrid)  
  
#  if ( k == 0 ) {
#    # Check the interpolation
#    plot(x=dataSCM[,k+2],y=dataSCM[,1],type='l')
#    lines(x=data[,TimeSCM],y=zf,col="red") 
#  }
  
}

# Compute SCM ensemble mean
SCMmean = rep(0,nlevout)
for ( k in 1:nlevout ) {
  SCMmean[k] = mean(dataSCM[k,2:NRUNS+1])
}

#save(dataSCM,file="dataSCM.RData")
#load("dataSCM.RData")

# Plotting the ensemble profiles
pdf(file=paste("WAVE",WAVEN,"/EOFs_InputProfiles.pdf",sep=""))
plot(x=dataLES[,2],y=dataLES[,1],type='l',lwd=2,col=2,xlab=variable,ylab="Altitude",xlim=c(min(dataSCM[,2:NRUNS+1]),max(dataSCM[,2:NRUNS+1])))
title(main=paste("WAVE #",WAVEN,"- Profiles",sep=""))
depths <- dataLES[,1]
for(j in 2:NRUNS+1){
  lines(x=dataSCM[,j],y=depths,col=8,lwd=0.5)
}
lines(x=dataLES[,2],y=dataLES[,1],lwd=2,col=2)
dev.off() # Closing the pdf file

# Plotting the ensemble profile errors
pdf(file=paste("WAVE",WAVEN,"/EOFs_InputProfiles_errors.pdf",sep=""))
plot(x=dataLES[,2]-dataLES[,2],y=dataLES[,1],type='l',lwd=2,col=2,xlab=variable,ylab="Altitude",xlim=c(min(dataSCM[,2:NRUNS+1]-dataLES[,2]),max(dataSCM[,2:NRUNS+1]-dataLES[,2])))
title(main=paste("WAVE #",WAVEN,"- Profile errors",sep=""))
depths <- dataLES[,1]
for(j in 2:NRUNS+1){
  lines(x=dataSCM[,j]-dataLES[,2],y=depths,col=8,lwd=0.5)
}
dev.off() # Closing the pdf file

# Plotting the ensemble profile anomalies
pdf(file=paste("WAVE",WAVEN,"/EOFs_InputProfiles_anomalies.pdf",sep=""))
plot(x=SCMmean-SCMmean,y=dataLES[,1],type='l',lwd=2,col=1,xlab=variable,ylab="Altitude",xlim=c(min(dataSCM[,2:NRUNS+1]-SCMmean),max(dataSCM[,2:NRUNS+1]-SCMmean)))
title(main=paste("WAVE #",WAVEN,"- Profile anomalies",sep=""))
depths <- dataLES[,1]
for(j in 2:NRUNS+1){
  lines(x=dataSCM[,j]-SCMmean,y=depths,col=8,lwd=0.5)
}
dev.off() # Closing the pdf file

#Step 2 Extract the fields you want, ie remove the first column which contains the altitude vector
SCMdata <- dataSCM[,-1]

#Step 3: Centre the data and find the Singular vectors (EOFs)
SCMsvd <- CentreAndBasis(SCMdata)
pdf(file=paste("WAVE",WAVEN,"/EOFs.pdf",sep=""))
par(mfrow=c(3,3))
for ( i in 1:9 ) {
  plot(x=SCMsvd$tBasis[,i],y=dataSCM[,1],type='l',xlab=paste("EOF #",i,sep=""),ylab="Altitude")
}
title(main=paste("WAVE #",WAVEN,"- 9 first EOFs",sep=""),outer=TRUE)
dev.off() # Closing the pdf file

#Step 4: Set a discrepancy variance and check the performance of basis reconstructions
Disc <- diag(0.01,nlevout) # To be thought about
DiscInv <- GetInverse(Disc) 
attributes(DiscInv)
ObsDat <- dataLES[,2] - SCMsvd$EnsembleMean
SCMsvd <- CentreAndBasis(SCMdata)
pdf(file=paste("WAVE",WAVEN,"/EOF_ExplainedVariance.pdf",sep=""))
par(mfrow=c(1,2), mar = c(4,4,2,4))
vSVD <- VarMSEplot(SCMsvd, ObsDat, weightinv = DiscInv, ylim = c(0,80), qmax = NULL)
title(main=paste("WAVE #",WAVEN,"- Cumulated explained variance",sep=""),outer=TRUE)
abline(v = which(vSVD[,2] > 0.95)[1])

#Step 5: Rotate the basis for optimal calibration
rotSCM <- RotateBasis(SCMsvd, ObsDat, kmax = 4, weightinv = DiscInv, v = c(0.35,0.15,0.1,0.1,0.1), vtot = 0.95, MaxTime = 10)

#save(rotSCM,file="rotSCM.RData")
#load("rotSCM.RData")

vROT <- VarMSEplot(rotSCM, ObsDat, weightinv = DiscInv, ylim = c(0,80), qmax = NULL)
abline(v = which(vROT[,2] > 0.95)[1])
dev.off() # Closing the pdf file
qROT <- which(vROT[,2] > 0.95)[1]
print(paste("Number of rotated EOFs that are retained: ",qROT,sep=""))

# Plotting rotated EOFs
pdf(file=paste("WAVE",WAVEN,"/rotEOFs.pdf",sep=""))
par(mfrow=c(3,3), mar=c(4,4,1,1))
for (i in 1:9) {
  plot(x=rotSCM$tBasis[,i],y=dataSCM[,1],type='l',xlab=paste("EOF #",sprintf("%i",i),sep=""),ylab="Altitude")
}
title(main=paste("WAVE #",WAVEN,"- 9 first rotated EOFs",sep=""),outer=TRUE)
dev.off() # Closing the pdf file

#Step 6: Emulate the basis coefficients and tune emulators!
tDataSCM <- GetEmulatableDataWeighted(Design = wave_param_US[,-1], EnsembleData = rotSCM, HowManyBasisVectors = qROT, weightinv = DiscInv)
StanEmsSCM <- InitialBasisEmulators(tDataSCM, HowManyEmulators=qROT,TryFouriers=TRUE)
# If it seems not working, relaunch source(*) at the script beginning
# A fast check that it worked  (if NULL, there is a problem...)
names(StanEmsSCM[[1]])

# To remove heavy data, especially if you want to save the emulators
#for ( i in 1:qROT ) {
#  StanEmsSCM[[i]]$StanModel <- NULL
#}
#save(StanEmsSCM,file="StanEmsSCM.RData")
#load("StanEmsSCM.RData")

for ( i in 1:qROT ) {
  pdf(file=paste("WAVE",WAVEN,"/LOO_EOF",sprintf("%2.2i",i),".pdf",sep=""))
  tLOOs1 <- LOO.plot(StanEmulator = StanEmsSCM[[i]], ParamNames = colnames(StanEmsSCM[[i]]$Design))
  title(main=paste("WAVE #",WAVEN,"- LOO - EOF #",i,sep=""),outer=TRUE)
  dev.off() # Closing the pdf file
}

#Step 7: History Matching
###NOTE IF WE WILL RULE OUT ALL OF SPACE, THERE IS A DISCREPANCY SCALING STEP TO AVOID THIS, SEE SPATIALDEMO AND USE CAUTION!
# At this stage no error for the obs
#FieldHM <- PredictAndHM(rotSCM, ObsDat, StanEmsSCM, tDataSCM, ns = 10000, Error = 0*diag(nlevout), Disc = Disc, weightinv = DiscInv)
FieldHM <- PredictAndHM(rotSCM, ObsDat, StanEmsSCM, tDataSCM, ns = 10000, Error = diag(dataLES[,NLES+2]), Disc = Disc, weightinv = DiscInv)
print("Summary of the implausibility:")
summary(FieldHM$impl)
#FieldHM$bound

# Plotting the 10 best emulated profiles (among the 10000) and the best one (in blue)
pdf(file=paste("WAVE",WAVEN,"/EOFs_best.pdf",sep=""))
par(mfrow = c(1,1))
plot(x=dataLES[,2],y=dataLES[,1],type='l',lwd=2,col=2,xlab=variable,ylab="Altitude",xlim=c(min(dataSCM[,2:NRUNS+1]),max(dataSCM[,2:NRUNS+1])))
title(main=paste("WAVE #",WAVEN,"- Best (?) profiles",sep=""))
for(j in 2:NRUNS+1){
  lines(x=dataSCM[,j],y=dataSCM[,1],col=8,lwd=0.5)
}
lines(x=dataLES[,2],y=dataLES[,1],type='l',lwd=2,col=2)

inds <- which(FieldHM$impl <= quantile(FieldHM$impl, probs = 0.001)) # plot 10 profiles with the lowest implausibility
for(k in inds){
  anss <- Reconstruct(FieldHM$Expectation[k,],rotSCM$tBasis[,1:qROT])+rotSCM$EnsembleMean
  lines(x=anss,y=dataSCM[,1],col="green",lwd=1.5)
}
ans <- Reconstruct(FieldHM$Expectation[which.min(FieldHM$impl),],rotSCM$tBasis[,1:qROT])+rotSCM$EnsembleMean
lines(x=ans,y=dataSCM[,1],col="blue",lwd=1.5) # adding best run
dev.off() # Closing the pdf file

# Create density plot
source("HistoryMatching/HistoryMatching.R")
source("HistoryMatching/impLayoutplot.R")
ImpData <- cbind(FieldHM$Design, FieldHM$impl)
# First Version
ImpList <- CreateImpList(whichVars = 1:nparam, VarNames = colnames(tDataSCM)[1:nparam], ImpData, nEms=qROT, Resolution=c(15,15), whichMax=1, Cutoff=FieldHM$bound)
imp.layoutm11(ImpList,VarNames = colnames(tDataSCM)[1:nparam],VariableDensity=TRUE,newPDF=TRUE,the.title=paste("WAVE",WAVEN,"/NROY_v1.pdf",sep=""),newPNG=FALSE,newJPEG=FALSE,newEPS=FALSE,Points=NULL)

# Second Version
ImpList <- CreateImpList(whichVars = 1:nparam, VarNames = colnames(tDataSCM)[1:nparam], ImpData, nEms=1, Resolution=c(15,15), whichMax=1, Cutoff=FieldHM$bound)
tMaxImp <- max(FieldHM$impl)
tbound <- FieldHM$bound
breakVec <- c(ceiling(seq(from=0,to=tbound,len=7)) , tMaxImp+1)
imp.layoutm11(ImpList,VarNames = colnames(tDataSCM)[1:nparam],VariableDensity=FALSE,newPDF=TRUE,the.title=paste("WAVE",WAVEN,"/NROY_v2.pdf",sep=""),newPNG=FALSE,newJPEG=FALSE,newEPS=FALSE,Points=NULL)

# assembling pdf files into just one
# At this time, it seems not to work when launch with Rscript
#system(paste("cd WAVE",WAVEN,"; pdfjoin -o results.pdf EOFs_InputProfiles.pdf EOFs_InputProfiles_errors.pdf EOFs_InputProfiles_anomalies.pdf EOFs.pdf EOF_ExplainedVariance.pdf rotEOFs.pdf LOO_EOF*.pdf EOFs_best.pdf NROY_v1.pdf NROY_v2.pdf",sep=""))
#system(paste("cd WAVE",WAVEN,"; rm -f EOFs_InputProfiles.pdf EOFs_InputProfiles_errors.pdf EOFs_InputProfiles_anomalies.pdf EOFs.pdf EOF_ExplainedVariance.pdf rotEOFs.pdf LOO_EOF*.pdf EOFs_best.pdf NROY_v1.pdf NROY_v2.pdf",sep=""))

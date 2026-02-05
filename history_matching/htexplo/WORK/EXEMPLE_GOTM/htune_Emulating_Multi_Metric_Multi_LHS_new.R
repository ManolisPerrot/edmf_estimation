#===============================================================================
#
# Computing emulators and History Matching using Exeter software
# Central procedure of the HighTune soft
# Developed during coding sprints of the HighTune project
#    Authors : HighTune team, 2017
#
# Main changes :
#  * Change from old rstan version of the Exeter R codes to Mogp version based
#        R, python and C and ported on GPU
#        Daniel Williamson, ~ 2019
#  * Spliting the Xp vector of parameters to allow running with
#        larger sample size
#        Maelle Coulon, Najda Villefranque, Frédéric Hourdin, 10/2022
#
#===============================================================================

twd <- getwd()
source('htune_convert.R')
library(reticulate)

#===============================================================================
# default values for optional arguments
#===============================================================================
WAVEN=1                     # Wave number of history matching (HM)
tau=0                       # number of metrics than can fail in the HM 
cutoff=3                    # cut-off on the Implausibility
sample_size=20000           # size of emulated sample (Xp)
sample_size_next_design=80  # sample size for true simulations for the next wave
max_sample_size=3000000     # Maximum LH size (above this limit, Xp is splitted)
sub_sample_size=300000      # size for splitting Xp for Implausibility computation
maxlLHS=50                  # Maximum number of lLHS
npixels=15                  # number of pixel in x and y for implausibility matrix
print_level=0               # "debug" pour activer des prints diagnostics

# if print = "debug", recommend sample_size=20, sample_size_next_design=5

#===============================================================================
# Diagnostics functions : size and time
#===============================================================================
htsize <- function(object,name) {
   print(paste(name,", type:",typeof(object),", length:",length(object),", memory:",format(object.size(object), units = "Mb"))) }
prev_time <- Sys.time()
httime <- function(where) {
   new_time <- Sys.time()
   print(paste("Time elapses in ",where," : ",new_time-prev_time)) }


#===============================================================================
# Reading line args
#===============================================================================
args = commandArgs(trailingOnly=TRUE)
if (length(args)%%2!=0) { print(paste("Bad number of arguments",length(args),"in htune_EmulatingMultiMetric.R")); q("no",1) ; }
if (length(args)>0) {
  for (iarg in seq(1,length(args),by=2)) {
    if (args[iarg]=="-wave") { WAVEN=as.numeric(args[iarg+1]) }
    else if (args[iarg]=="-tau") {tau=as.numeric(args[iarg+1]) }
    else if (args[iarg]=="-cutoff") {cutoff=as.numeric(args[iarg+1]) }
    else if (args[iarg]=="-sample_size") {sample_size=as.numeric(args[iarg+1]) }
    else if (args[iarg]=="-sample_size_next_design") {sample_size_next_design=as.numeric(args[iarg+1]) }
    else { print(paste("Bad argument",args[iarg],"in htune_Emulating_Multi_Metric_Multi_LHS.R")) ; q("no",1) ; } # quit with error code 1 
  }
}


#===============================================================================
# Reading results of a series of SCM simulations
#===============================================================================

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

#===============================================================================
print("  ========   Scatter plot metrcis=f(param)   ======== ")
#===============================================================================
# Ploting for each parameter, the metric as a fuction of parameter values:
# directly from the SCM outputs
# Organizing sub-windows as a fuction of the number of plots
# For ploting with real prameters as axis
#===============================================================================

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

#===============================================================================
print("   ======   Reading emulators of previous waves  ========   ")
#===============================================================================

mogp_dir <- "./mogp_emulator"
source("BuildEmulator/BuildEmulator.R")

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

#===============================================================================
print(paste("   ======   Computing emulator for wave ",WAVEN," ======== "))
#===============================================================================
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

#===============================================================================
print("  ==============      Building emulators    ============== ")
#===============================================================================

  # Modif DW: "I am soon pushing a different default here, and it is better for high tune to have the old default."
  myem.lm <- BuildNewEmulators(tData=tData,HowManyEmulators=nmetrique,additionalVariables = NULL, meanFun="fitted")
  
  file = paste("WAVE",WAVEN,"/Plots_LOO.pdf",sep="")
  pdf(file=file)
  #DIAGNOSTICS : verifying that the original SCMdata are well reproduced when eliminating the point from the emulator
  tvars <- rep(NA, nmetrique)
  terrs <- rep(NA, nmetrique)
  for (i in 1:nmetrique) {

#===============================================================================
    print(paste("   ====== Computing LOO for metrique ",i,"   ======     "))
#===============================================================================
    tLOOs1 <- LOO.plot(Emulators = myem.lm, which.emulator=i, ParamNames=names(tData)[1:nparam], OriginalRanges = TRUE, 
                       RangeFile = "ModelParam.R",
                       Obs=tObs[i], ObsErr = sqrt(tObsErr[i]), ParRange=TRUE, ObsRange=TRUE)
    terrs[i] <- (tLOOs1[,1]-tData[,nparam+i+1])^2
    tvars[i] <- ((tLOOs1[,3]-tLOOs1[,1])/2)^2
    print(paste("mean(emulator error/training data set): ",sqrt(mean(terrs[i])),"\t mean (emulator std-deviation for each prediction)",sqrt(mean(tvars[i])),sep=""))
  }
  dev.off()
  
#===============================================================================
  print("  ==============      Saving emulators    ============== ")
#===============================================================================

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

#===============================================================================
#===============================================================================
   print("  ==============     Begining history matching     ============== ")
#===============================================================================
#===============================================================================

source('HistoryMatching/HistoryMatching.R')
source('HistoryMatching_addon.R')
print(paste("Generating ",sample_size,"samples varying nparam input parameters"))

#===============================================================================
# sample_size is the number of samples required
#    If sample_size > max_sample_size
#    nbLHS samples Xp of size max_sample_size are created successively
#    each Xp has size sample_size_new
#===============================================================================

max_sample_size <- min(c(sample_size,max_sample_size))
nbLHS=( sample_size - 1 ) %/% max_sample_size + 1
sample_size_new=sample_size%/%nbLHS
print(paste("Dividing sample_zize=",sample_size," in ",nbLHS," pieces"))
dimXP = list()   #stock la taille de Xp = vecteur total dimXP[lLHS]
lLHS=1
dimNROY = matrix(0, nrow=0, ncol=WAVEN)
isImpmatrix=0 #=1 once the implausibility matrix is evaluated
repeat {

     Xp <- as.data.frame(2*randomLHS(sample_size_new, nparam)-1)
     dimXP[lLHS]=dim(Xp)[1]
     names(Xp) <- names(tData)[1:nparam]
     Disc = rep(0, nmetrique)
     totonew<-DesignantiConvert1D(param.defaults)
     param.defaults.norm=rep(0,nparam)
     print(paste("lLHS=",lLHS,"Generating ",sample_size_new,"samples varying nparam input parameters"))
     htsize(Xp,"Xp")
     dimNROY_OneRow = matrix(0, nrow=1, ncol=WAVEN)
     dimNROY = rbind(dimNROY,dimNROY_OneRow)
     htsize(dimNROY,"dimNROY")

     for (i in 1:nparam) {param.defaults.norm[i]=totonew[i,]}
     
     if(WAVEN == 1) {
     
#===============================================================================
         print(paste("==== Computing implausibility for wave ",WAVEN," ====="))
#===============================================================================
   
         Timps <- ImplausibilityMOGP(NewData=Xp, Emulator=EMULATOR.LIST[[1]], Discrepancy=Disc, Obs=tObs, ObsErr=tObsErr)
         ImpData_wave1 = cbind(Xp, Timps)
         VarNames <- names(Xp)
         valmax = tau_vec[1] + 1
         if(lLHS==1) { # we create implausibility matrix only at the first step on nbLHS -> Maelle
           # Prend en entrée ImpData_wave1 = concatenation des valeurs de
           # paramètres et des implausibilities précalculées + le cutoff !!!
           # par défaut = 3 cf ExeterUQ_MOGP/HistoryMatching/HistoryMatching.R
           # ATTENTION, pas du tout pareil à la vague N
           ImpList = CreateImpList(whichVars = 1:nparam, VarNames=VarNames,
                                     ImpData=ImpData_wave1,
                                     nEms=EMULATOR.LIST[[1]]$mogp$n_emulators,
                                     whichMax=valmax)
           # ImpList = une liste 2D correspondant à la matrice de figures
           # dans InputSpace par exemple pour 3 paramètres a,b,c : 
           # ImpList[1,1] = (a,b), ImpList[1,2] = (a,c)
           # ImpList[2,1] = (b,c)
           # Ensuite pour chaque élément de ImpList, 
           # on a une liste de pixels = Resolution[1]*Resolution[2] (par défaut 15x15)
           # pour chaque pixel, 2 valeurs : 1) implaus max sur les métriques et
           # min sur les paramètres pour ce pixel et 2) densité de points dans
           # le NROY pour ce pixel.
           # Exemple pour 3 paramètres et 2x2 pixels par matrice
           # [[1]]
           # [[1]][[1]]
           #             [,1]        [,2]       [,3]        [,4]
           # [1,] 0.004896447 0.002936362 0.01059059 0.005597868
           # [2,] 0.162410215 0.153702219 0.16172146 0.153232243
           # 
           # [[1]][[2]]
           #             [,1]        [,2]       [,3]        [,4]
           # [1,] 0.004896447 0.002936362 0.01059059 0.005597868
           # [2,] 0.164159054 0.151799894 0.16000529 0.155158517
           # 
           # 
           # [[2]]
           # [[2]][[1]]
           #             [,1]       [,2]      [,3]        [,4]
           # [1,] 0.002936362 0.01640741 0.0438230 0.005597868
           # [2,] 0.160752401 0.15511727 0.1553838 0.159818570

         }
         NROY1 <- which(rowSums(Timps <= cutoff_vec[1]) >=EMULATOR.LIST[[1]]$mogp$n_emulators - tau_vec[1])
         dimNROY[lLHS,1]=length(NROY1)
         TMimpls_wave1 <- apply(Timps, 1,MaxImp,whichMax=valmax)
         if(lLHS==1){
           XpNext <- Xp[NROY1, ]
         } else {
           XpNext <- rbind(XpNext, Xp[NROY1, ])
         }
         print(paste("lLHS=",lLHS," : dim(Xp[NROY1, ])[1] ", dim(Xp[NROY1, ])[1], sep=""))
         print(paste("dim(Xp[NROY1, ]) ", dim(Xp[NROY1, ]), sep=""))
         print(paste("dim(Xp) ", dim(Xp), sep=""))
         print(paste("fin vague 1 : dim(XpNext)=", dim(XpNext),"dim(XpNext)[1]=",dim(XpNext)[1], sep=""))
   
     } else { # WAVEN > 1

       XpNextNew = Xp
       NROY.list = list()
       Impl.list = list()

       for(i in 1:(length(EMULATOR.LIST))) {

#===============================================================================
         print(paste("=== Computing implausibility, wave ",i,"/",WAVEN," ==="))
#===============================================================================

         # Computing implausibility for sub samples of Xp of
         # size sub_sample_size (already inside a sub sample lLHS)

         nsub=( nrow(XpNextNew) - 1 ) %/% sub_sample_size + 1
         print(paste("Taille de XpNextNew : ", dim(XpNextNew), sep=""))
         Xp_tmp <- split(XpNextNew,factor(sort(rank(row.names(XpNextNew))%%nsub)))
         if (print_level > 1) 
           htsize(XpNextNew,paste("XpNextNew, splitted in",nsub,"pieces"))

         for(k in 1:nsub) {
           Xp_tmp2 <- as.data.frame(Xp_tmp[k])
           if (print_level > 1) htsize(Xp_tmp2,paste("Xp_tmp2, k=",k))
           Timps_2 = ImplausibilityMOGP(NewData=Xp_tmp2,
                                        Emulator=EMULATOR.LIST[[i]],
                                        Discrepancy=Disc, Obs=tObs,
                                        ObsErr=tObsErr)
           if(k == 1){ # first subsample 
              Timps = Timps_2
           } else {    # concatenate subsamples
              Timps = rbind(Timps,Timps_2)
           }
           if (print_level > 1) htsize(Timps,paste("Timps, k=",k))
         }

         valmax = tau_vec[i] + 1
	       if (length(Timps) == nmetrique){
		       #print("probleme, Timps ne contient plus qu'un vecteur")
		       #when Timps contain just on vector we transform it into a matrix
		       Timps = matrix(Timps, nrow = 1)
         }
	    
         print(c("cutoff",i,cutoff_vec[i]))
         Impl.list[[i]] = matrix(apply(Timps, 1,MaxImp,whichMax=valmax), ncol = 1)
         NROY.list[[i]] = which(rowSums(Timps <= cutoff_vec[i]) >= EMULATOR.LIST[[i]]$mogp$n_emulators - tau_vec[i])
         dimNROY[lLHS,i] = length(NROY.list[[i]]) #Stock pour chaque l et chaque i(=vague) le nombre de vecteur non exclu ce qui permet le calcul du Remaining space pour chaque vague a la fin
         XpNextNew = XpNextNew[NROY.list[[i]], ]
         if (print_level > 1) print("apres3")
         #remaining_sample_size=length(row(XpNextNew))
	       remaining_sample_size=dim(XpNextNew)[1]
         print(paste("Nb of pts in NROY (wave:",i,",lLHS:",lLHS,") =",
                     remaining_sample_size))
	       if( remaining_sample_size == 0){
          print("remaining_sample_size is empty, we leave the loop on emulators")
	        break
	       }
         #print(paste("On ne conserve que les bons vecteurs de paramètres : XpNext a maintenant la taille ", dim(XpNext), sep=""))
         #print(paste("Remaining space after wave",i,": ",length(NROY.list[[i]])/dim(Xp)[1],sep=""))
         #cat(length(NROY.list[[i]])/dim(Xp)[1],file=paste("Remaining_space_after_wave_",i,".txt", sep=""),sep="")

       } # End Loop on Waves

       if (print_level > 1) {
         httime(paste("Implausibility computation, lHLS=",lLHS))
         print("--- fin boucle emulateurs (vagues precedentes et actuelle) ---")
       }

       if(lLHS == 1){
         XpNext = XpNextNew
       } else { # concatenation des XpNextnew sur les l dans XpNext
         XpNext = rbind(XpNext,XpNextNew) 
       }
       print(paste("XpNext final : ", dim(XpNext)[1]) )
	     if (print_level > 1) htsize(XpNext, "XpNext final")

       Impl.list[[length(EMULATOR.LIST)]] = Timps
	 
       #if(dim(XpNextNew)[1] > 0){
       ImpData <- ImpDataWaveM(Xp, NROY.list, Impl.list)
       if (print_level > 2) {
         print("Impl.list")
         print(Impl.list)
         print("NROY.list")
         print(NROY.list)
         print("ImpData")
         print(ImpData)
       }
       VarNames <- names(Xp)
#=========================================================================
       print(paste("== Drawing implausibility matrix, wave ",WAVEN," =="))
#=========================================================================

       if (print_level > 1) httime("Before ImpList_ <- CreateImpListWaveM_ ")
       print("Cumulating information for implausibility matrix")
       n_emulators = EMULATOR.LIST[[length(EMULATOR.LIST)]]$mogp$n_emulators
       # Prend en entrée ImpData qui est une liste de 3 éléments, créée
       # par ImpDataWaveM :
       # $Design = valeurs des paramètres
       # $NROY = matrice 2D (N_sample, N_vagues) avec True si le point i
       # est dans le NROY à la vague j
       # $Impl = liste de N_vagues listes chacune de N_sample éléments,
       # de valeurs d'implausibilité pour chaque sample, et NA si le
       # sample i n'est pas dans le NROY space à la vague j
       ## Produit ImpList la même chose que CreateImpList à la vague 1 (ci dessus)
       ImpList_ <- CreateImpListWaveM_(whichVars=1:nparam,
                                       VarNames=VarNames,
                                       ImpData=ImpData, nEms=n_emulators,
                                       Resolution=c(npixels,npixels),
                                       whichMax=valmax)
       # ImpList = list( list( matrice(3 lignes, length(Xp) colonnes) ) )
       # list ( list ( => sur les lignes / colonnes de l'upper triangle
       # de la matrice InputSpace
       if (isImpmatrix == 0 ) {
         sum_ImpList = ImpList_
	       isImpmatrix=1
       } else {
         i_ligne = 0
         for (list_imp_x in ImpList_) {
           i_ligne = i_ligne + 1
           i_col   = 0
           for (list_imp_y in list_imp_x) {
             i_col = i_col + 1
             for (i_pix in 1:length(list_imp_y[1,])) {
               sum_ImpList[[i_ligne]][[i_col]][1,i_pix] =
                 min(sum_ImpList[[i_ligne]][[i_col]][1,i_pix], list_imp_y[1,i_pix])
             }
             sum_ImpList[[i_ligne]][[i_col]][2,] =
               sum_ImpList[[i_ligne]][[i_col]][2,] + list_imp_y[2,]
             sum_ImpList[[i_ligne]][[i_col]][3,] =
               sum_ImpList[[i_ligne]][[i_col]][3,] + list_imp_y[3,]
         }
           }
       }
       if (print_level > 1) httime("After ImpList_ <- CreateImpListWaveM_ ")
       #} else {
       #  print("XpNextNew est vide, on ne calcule pas ImpData")
	     #}
     } # End If WAVEN > 1

#===============================================================================
# Ending loop on lLHS if reaching nbHLS, except if
# of remaining vectors < sample_size_next_design
#===============================================================================

     remaining_sample_size=nrow(XpNext)
     print(paste("Number of remaining samples ",remaining_sample_size))
     if ( lLHS >= nbLHS ) {
          if ( remaining_sample_size >= sample_size_next_design ) {
             break
          } else if (lLHS >= maxlLHS) {
	     print("!!!! lLHS > maxlLHS !!!!")
	     rspace=colSums(dimNROY)[i]/Reduce('+', dimXP)
	     print(paste("Remaining space after wave",i,": ",rspace,sep=""))
	     print(paste("With ",colSums(dimNROY)[i], "good vectors and ", Reduce('+', dimXP), "samples"))
	     print("!!!! We stop the experiment !!!!")
	     stop()
          } else {
             print(paste("Not enough samples, ",remaining_sample_size,"<",sample_size_next_design," Running a new ",sample_size_new,"sample"))
          }
     }
     lLHS=lLHS+1

#===============================================================================
} # Ending loop on lLHS
#===============================================================================

#===============================================================================
# Plotting implausibility matrix
#===============================================================================

if (WAVEN > 1 ) {
  # plotting Implausibility Matrix for cumulated information throughout lLHS 
  
  # I just need the structure of the ImpList object that goes into layoutm11
  # print(ImpData)
  ImpList <- CreateImpListWaveM(whichVars=1:nparam, VarNames=VarNames,
                                ImpData=ImpData, nEms=n_emulators,
                                Resolution=c(npixels, npixels), whichMax=valmax)
  i_ligne = 0
  for (list_imp_x in sum_ImpList) {
    i_ligne = i_ligne + 1
    i_col   = 0
    for (list_imp_y in list_imp_x) {
      i_col = i_col + 1
      # overwrite min implaus and NROY density
      ImpList[[i_ligne]][[i_col]][1,] = list_imp_y[1,]
      ImpList[[i_ligne]][[i_col]][2,] = list_imp_y[2,]/list_imp_y[3,]
    }
  }
  
}
if (print_level > 1) httime("Implausibility matrix : creating ImpList ")
imp.layoutm11(ImpList, VarNames, VariableDensity=FALSE, newPDF=TRUE,
              the.title=paste("InputSpace_wave", WAVEN, ".pdf", sep=""),
              newPNG=FALSE, newJPEG=FALSE, newEPS=FALSE,
              Points=matrix(param.defaults.norm, ncol=nparam))
if (print_level > 1) httime("Implausibility matrix : creating Graph ")

#===============================================================================
# Storing Normalized Remaining space
#===============================================================================

for(i in 1:(length(EMULATOR.LIST))) {
      rspace=colSums(dimNROY)[i]/Reduce('+', dimXP)
      print(paste("Remaining space after wave",i,": ",rspace,sep=""))
      cat(rspace,file=paste("Remaining_space_after_wave_",i,".txt", sep=""),sep="")
}

if(isImpmatrix==1) { #if implausibility matrix has been evaluated, we create the pdf file
  mtext(paste("Remaining space:", rspace, sep=""), side=1)
  print(paste("Created figure file: ", "InputSpace_wave",WAVEN,".pdf", sep=""))
}
#fin des modifs Maelle

#===============================================================================
# Creation of Wave WAVEN+1 sample
#===============================================================================

print("on regarde les parametres avec lesquels on va lancer la prochaine vague")
print(paste("nombre de vecteurs restant dans XpNext :", nrow(XpNext), sep=""))
if (nrow(XpNext)>=sample_size_next_design) { samplesz=sample_size_next_design } else { samplesz=nrow(XpNext)
print(paste("Final Sample size reduced to ",samplesz))
}

#### 
# Pour utiliser DesignConvert avec un seul argument il faut utiliser la
# fonction redéfinie dans htune_convert.R et pas celle dans HistoryMatching.R
# 
source('htune_convert.R')
param_SCM <- DesignConvert(XpNext[,1:nparam])
UFILE=paste("param_after_wave",WAVEN,sep="")
head(param_SCM)
logs=array(1:nparam) ; for ( iparam in 1:nparam ) { logs[iparam]<-"linear" }
logs[which.logs] <- "log"
for (i in 1:nparam) {
   line<-paste(names(tData)[i], min(param_SCM[,i]), max(param_SCM[,i]),param.defaults[i],logs[i],sep=" ")
   print(line)
   write(line, file=UFILE,append=TRUE)
}
print('OK')
print(which.logs)

design.waveNext <- sample(nrow(XpNext), samplesz, rep = F)
WaveNext <- XpNext[design.waveNext, ]
save(WaveNext,file=paste("Wave",strtoi(WAVEN, base = 0L)+1,".RData",sep=""))
print(paste("Next wave design has been saved under: ","Wave",strtoi(WAVEN, base = 0L)+1,".RData",sep=""))
#} else { print("The NROY space is not large enough to allow resampling for next wave") }

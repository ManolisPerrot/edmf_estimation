==========================================================================
Trying to get a check of what improvements should be done on the tool.
==========================================================================


--------------------------------------------------------------------------
Check while DesignantiConvert1D is needed and what the difference with DesignantiConvert
    It is used to get totonew in htune_Emulating*R scripts. But why ???
    OK. Seen. 1D is for one row in a parameter file. Used for the control simulation.
    Could probably easily be solved.

--------------------------------------------------------------------------
LHSIZE, NLHC and NSCM should be removed from ModelParam.R
    No need to duplicate ModelParam.R in WAVEN
source("WAVE3/ModelParam.R")
source("htune_convert.R")
InFile="WAVE3/Par1D_Wave3.asc"
OutFile="tmp.RData"
PhysicsParams<-read.csv(InFile,sep=" ")
wave_param_US=cbind(PhysicsParams["t_IDs"],DesignantiConvert(PhysicsParams[,][2:length(PhysicsParams[1,])]))
save(wave_param_US,file='tmp.RData')


--------------------------------------------------------------------------
Introduction of option nograph in post_scores.sh to avoid very slowa graph
plots with plot_scores.py, when working remotely from ssh


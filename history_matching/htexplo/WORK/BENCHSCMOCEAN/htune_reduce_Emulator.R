######################################################################
# Reducing emulator list (Rdata)
# F. Hourdin, 2020/02/17
# Either removing the last state or taking from wave 1 to NEW_WAVEN
# when called as
# Rscript htune_reduce_Emulator.R -wave NEW_WAVEN
######################################################################

EMULATOR.LIST <- list()
tau_vec = c()
cutoff_vec = c()

NEW_WAVEN=0

# Reading arguments
args = commandArgs(trailingOnly=TRUE)
if (length(args)%%2!=0) { print(paste("Bad number of arguments",length(args),"in htune_EmulatingMultiMetric.R")); q("no",1) ; }
if (length(args)>0) {
for (iarg in seq(1,length(args),by=2)) {
  if (args[iarg]=="-wave") { NEW_WAVEN=as.numeric(args[iarg+1]) }
  else { print(paste("Bad argument",args[iarg],"in htune_reduce_Emulator.R")) ; q("no",1) ; } # quit with error code 1
}
}

#===============================================
# Reading results of a series of SCM simulations
#===============================================
print(paste("Arguments : -wave",NEW_WAVEN))

load("EMULATOR_LIST_MULT_METRIC.RData")
if ( NEW_WAVEN == 0 ) {
	NEW_WAVEN=length(EMULATOR.LIST)-1
}

# Checking that the NEW_WAVEN is smaller that the length of emulator list
print(c("Length of Emulator list =",length(EMULATOR.LIST)))
if ( length(EMULATOR.LIST) <= NEW_WAVEN ) {
      print(c("Length of Emulator list =",length(EMULATOR.LIST),"<=",NEW_WAVEN))
} else {
        #SAVE EMULATOR FOR HISTORY MATCHING
	EMULATOR.LIST <- lapply(1:NEW_WAVEN, function(k) EMULATOR.LIST[[ k ]])
	tau_vec<- tau_vec[1:NEW_WAVEN]
	cutoff_vec<- cutoff_vec[1:NEW_WAVEN]
        save(EMULATOR.LIST, tau_vec, cutoff_vec, file = "NEW_EMULATOR_LIST_MULT_METRIC.RData")
}

#############################################################################
# Purpose : define the setup of the experiments, i.e.the case, subcase, 
#           target variables and wave number.
#############################################################################
REF="RAD"
case_name="ARMCU"
subcase_name="REF"
targetvar<- c("dnsurf")
plotvar="" # theta, qv ou rneb

# Exemple for multi-target experiment :
#targetvar<- c("theta500","qv500","zhneb","nebmax","nebzmin","nebzmax")
nmetrique=length(targetvar)

# Wave number
WAVEN=1
tau=1
Cutoff=3

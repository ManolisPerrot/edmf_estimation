#############################################################################
# Purpose : define the setup of the experiments, i.e.the case, subcase, 
#           target variables and wave number.
#############################################################################
case_name="csvmm"
subcase_name="thBL"
case_name="ARMCU"
subcase_name="REF"
#if use of compute_metric*sh
#need to define case_name='csvAR79RIBOAY' & subcase_name="thBL"
targetvar=c("theta500")
plotvar="theta" # qv ou rneb

# Exemple for multi-target experiment :
#targetvar= c("theta500","qv500","nebzave","nebmax","nebzmin","nebzmax")
nmetrique=length(targetvar)

# Wave number
WAVEN=1

tau=1

Cutoff=3

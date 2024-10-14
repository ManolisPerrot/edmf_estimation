###############################################################################
# Auteurs : Najda Villefranque
# Modif 2017/12/15 : F. Hourdin
# Reads z-t files from LES and SCM stored in DATA/
#    SMC001.nc, SCM002.nc, ... and same for LES
# tout_tracer plots vertical profiles of a variable N at time  
###############################################################################

library("ncdf4") # to manipulate ncdf

WAVEN=1
case_name="bomex"
plotvar="rneb"
itest=2

source('ModelParam.R')
source('htune_plot.R')
source('htune_case_setup.R')
source('htune_metric.R')
casesu <-case_setup(case_name)
NLES=casesu[1]
TimeLES=casesu[2]
TimeSCM=casesu[3]
print('WARNING, NSCMS WAS ORIGINALLY READ IN ModelParam.R ; untill svn 361')
NSCMS=100
NRUNS=NSCMS
nparam=NPARA

if ( itest == 0 ) {
  file="LES/arm_cu/LES0.nc"
  nc =  nc_open(file)
  var = ncvar_get(nc,"rneb")
  zval = ncvar_get(nc,"zf")
  nebzmax<-compute_zhneb(zval,var,zmax,"nebzmax")
  nebzmin<-compute_zhneb(zval,var,zmax,"nebzmin")
  nebzave<-compute_zhneb(zval,var,zmax,"nebzave")
  plot(nebzmax,type="l")
  lines(nebzmin,col="red")
  lines(nebzave,col="blue")
} else if ( itest == 1 ) {
  trace_serie_s(case_name,"nebzmax")
} else if ( itest == 2 ) {
  pltsu<-plot_setup(case_name,plotvar)
  tout_tracer(plotvar,case_name,TimeSCM,TimeLES)
}

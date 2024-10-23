library("ncdf4") # to manipulate ncdf
source('htune_metric.R')

args = commandArgs(trailingOnly=TRUE)

# Rscript htune_noise_metrics.R $file.nc $var_ $t1R $t2R $z1_ $z2_ 
if (length(args)!=6) { stop("Wrong argument number to htune_netcdf2csvMetrics.R")}

nc =  nc_open(args[1])
var =  args[2]
var=ncvar_get(nc,args[2])
zf=ncvar_get(nc,"zf")
if ( length(c(dim(zf))) == 1 ) { zval=rep(0,dim(zf)) ; zval[] = zf[] } else { zval=rep(0,dim(zf)[1]) ; zval[] = zf[,1]}


lmin=as.numeric(args[3])
lmax=as.numeric(args[4])
zmin=as.numeric(args[5])
zmax=as.numeric(args[6])

metric<-compute_numerical_noise_up(zmin,zmax,lmin,lmax,zf,var)
#metric<-compute_numerical_noise_discret(zmin,zmax,lmin,lmax,zval,var)
print(metric)

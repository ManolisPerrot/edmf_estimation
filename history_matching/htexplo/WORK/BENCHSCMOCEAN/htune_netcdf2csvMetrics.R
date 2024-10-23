library("ncdf4") # to manipulate ncdf
source('htune_metric.R')

args = commandArgs(trailingOnly=TRUE)

if (length(args)!=5) { stop("Wrong argument number to htune_netcdf2csvMetrics.R")}

nc =  nc_open(args[1])
t1=as.numeric(args[3])
t2=as.numeric(args[4])
zmax=as.numeric(args[5])
metric_vector=get_metric(nc,args[2],time,zmax)
metric = mean(metric_vector[t1:t2])
print(metric)

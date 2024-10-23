###############################################################################
# Auteurs : F. Hourdin
# Modif 2017/12/15 : F. Hourdin
# Reads z-t files from LES and SCM stored in DATA/
#    SMC001.nc, SCM002.nc, ... and same for LES
# tout_tracer plots vertical profiles of a variable N at time  
###############################################################################


###############################################################################
# Plots
###############################################################################

tout_tracer <- function(varname,case_name,subcase_name,time_scm,time_les,pltsu) {
  # if les = 1, compute zf accordingly
  # else, it is 1D
  print('debut tout tracer')
  print(c(time_scm,time_les))
  print(c("pltsu=",pltsu))
  first=1
  #pdf(file='myplot.pdf')
  for (k in 1:NSCMS) {
    file= paste("WAVE1/",case_name,"/",subcase_name,"/SCM-1-",sprintf("%3.3i",k),".nc",sep="")
    une_courbe(file,varname,1,time_scm,first,"grey")
    first=0
  }
  print("ON PASSE AU TRACER DES LES")
  for (k in 0:(NLES-1)) {
     file= paste("LES/",case_name,"/",subcase_name,"/LES",print(k),".nc",sep="")
     une_courbe(file,varname,0,time_les,first,"blue")
  }
  #dev.off()
  print("ET ON EN SORT")
}

############################################################################
# Plots vertical profiles at a given time
############################################################################
une_courbe <- function(file,varname,timez,timeval,first,color) { 
       ncid = nc_open(file)
       zval = ncvar_get(ncid,"zf")
       var=ncvar_get(ncid,varname)
       if (timez==0) { zzz<-zval } else { zzz<-zval[,timez]}
       if (first==1) {
        xmin=pltsu[1]
        xmax=pltsu[2]
        zmax=pltsu[3]
        plot(var[,timeval],zzz,col=color,xlim=c(xmin,xmax),ylim=c(0,zmax),type="l",xlab=varname,ylab="z")
       }
       else {
         lines(var[,timeval],zzz,col=color)
       }
       nc_close(ncid)   
     }
#tracer d'une serie temporelle pour une variable donnee (soit un niveau z soit une integrale
trace_serie_s <- function(case_name,subcase_name,varname,targetvar) {
    first=1
    #pdf(file='myplot2.pdf')
    for (k in 1:NSCMS) {
      file= paste("WAVE1/",case_name,"/",subcase_name,"/SCM-1-",sprintf("%3.3i",k),".nc",sep="")
      print(c("fichier SCM",k,file))
      trace_serie(file,varname,first,"grey",targetvar)
      first=0
    }
    print("ON PASSE AU TRACER DES LES")
    for (k in 0:(NLES-1)) {
      first=0
      file= paste("LES/",case_name,"/",subcase_name,"/LES",print(k),".nc",sep="")
      trace_serie(file,varname,first,"blue",targetvar)
    }
    #dev.off()
    print("ET ON EN SORT")
}

trace_serie <- function(file,varname,first,color,targetvar) {
  nc=nc_open(file)
  neb = ncvar_get(nc,varname)
  lm=dim(neb)[2]
  km=dim(neb)[1]
  zval=rep(0,km)
  # rep(x,n) replicates the value x ntimes = une maniere d'initialiser un tableau de 0
  zf = ncvar_get(nc,"zf")
  if ( length(c(dim(zf))) == 1 ) { zval[] = zf[] } else { zval[] = zf[,1] }
  nc_close(nc)
  # la on veut peut etre modifier calcul z pour avoir soit quelque chose d'integrer soit une variable extraite a un niveau donn????
  if ( varname=="rneb"){
     if ( (targetvar == "nebzmin" )| (targetvar == "nebzmax") | (targetvar == "nebzave") ) {
      zmaxint=4000.
      xmin=0.
      xmax=2500.
      varnew<-compute_zhneb(zval,neb,zmaxint,targetvar)
     } else {
      zmaxint=4000.
      xmin=0.
      xmax=1.
      varnew<-compute_zhneb(zval,neb,zmaxint,targetvar)
     }
  } else {
    varnew=rep(0,lm)
    zsel=500.
    if (varname=="theta") {
      xmin=pltsu[1]
      xmax=pltsu[2]
    }
    if (varname=="hur") {
      zsel=6000.
      xmin=0.
      xmax=1.
    }
    if (varname=="qv") {
      xmin=pltsu[1]
      xmax=pltsu[2]
    }
    for (k in 2:(km-1)) {
      if ((zval[k]-zsel)*(zval[k+1]-zsel) <=0.) { ksel = k }
    }      
    for (l in 0:(lm-1)) {
      varnew[l]=neb[ksel,l]
    }
  }
  if ( first == 1 ) {
    plot(varnew,ylim=c(xmin,xmax),type="l",col=color,ylab=varname)
  } else {
    lines(varnew,col=color)
  }
  }

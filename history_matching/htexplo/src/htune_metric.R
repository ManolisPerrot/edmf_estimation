###############################################################################
# Auteurs : Najda Villefranque
# Modif 2017/12/15 : F. Hourdin
#    Reads z-t files from LES and SCM stored in DATA/
#      SMC001.nc, SCM002.nc, ... and same for LES
#    Calcule les metriques. Plusieurs options a completer
# Modif 2018/08/17 : N. Villefranque
#    Added radiation metrics
#    Do not call plot_setup
#    zmax is now an argument of get_metric
###############################################################################


library("ncdf4") # to manipulate ncdf

# I comment this because I think it is better to keep independent modules
# I think zmax should be given as a parameter to get_metric
#pltsu<-plot_setup(case_name,plotvar)
#zmax=pltsu[3]

#############################################################################
# Compute the height of maximum nebulosity
#############################################################################
compute_zhneb <- function(zval,neb,zmax,varname) {
  lm=dim(neb)[2]
  km=dim(neb)[1]
  

  # nebzave, neb2zave, neb4zave
  # Computes the mean altitude of clouds as the integral on the vertical
  # of the altitude times a wheight  f**np where np is a positive integer
  # For large values of np, the altitude is that of the maximum cloud fraction
  if ( ( varname == "nebzave" ) | ( varname == "neb2zave" ) | ( varname == "neb4zave" ) ) {
    if ( varname == "nebzave" ) {pn=1} else { if (varname == "neb2zave") {pn=2} else {pn=4} }

    rm=rep(0,lm)
    hm=rep(0,lm)
    nebzave=rep(0,lm)
    # finding 
    for (k in 2:km-1) { 
      if (zval[k+1]<zmax) {
        rm[]<-rm[]+(zval[k]-zval[k+1])*(neb[k,]+neb[k+1,])**pn*(zval[k]+zval[k+1])*0.5
        hm[]<-hm[]+(zval[k]-zval[k+1])*(neb[k,]+neb[k+1,])**pn
      }}
    for (l in 1:lm) { 
    	if ( hm[l] != 0 ) {
    	nebzave[l]=rm[l]/hm[l]
	  	}} 
    return(nebzave)
  # nebdz : int neb * dz
  # Computes the mean altitude of clouds as the integral on the vertical
  } else if ( varname == "nebdz" ) {
    nebave=rep(0,lm)
    for (k in 2:km-1) { 
      if (zval[k+1]<zmax) {
        nebave[]<-nebave[]+(zval[k+1]-zval[k])*(neb[k,]+neb[k+1,])*0.5
      }}
    return(nebave)
  } else {
    nebmax=rep(0,lm)
    nebzmin=rep(0,lm)
    nebzmax=rep(0,lm)
    eff_ratio=0.05
    for ( l in 1:lm ) {
      nebmax[l]=max(neb[0:km,l])
    }
    if ( varname == "nebmax" ) {
      return(nebmax)
    } else {
      nebzmin=rep(0,lm)
      nebzmax=rep(0,lm)
      eff_ratio=0.05
      for ( l in 1:lm ) {
        nebmax[l]=max(neb[1:km,l])
        nebzmin[l]=99999999.
        nebzmax[l]=-1.
        for (k in 2:km-1) { 
          if (zval[k+1]<zmax) {
            if ( neb[k,l] > eff_ratio*nebmax[l] )  {
              nebzmin[l]=min(nebzmin[l],zval[k])
              nebzmax[l]=max(nebzmax[l],zval[k])
            }
          }
        }
        if ( nebzmin[l] == 99999999. ) { nebzmin[l]=0. }
        if ( nebzmax[l] == -1. ) { nebzmax[l]=0. }
      }
      if ( varname == "nebzmin" ) {
        return(nebzmin)
      } else {
        if ( varname == "nebzmax" ) {
          return(nebzmax)
        } else {
          print(c("variable ",varname," non prevue"))
        }
      }
    }
  }
}

#############################################################################
# Compute liquid water path
#############################################################################
compute_Ay <- function(zval,vvv,zmax,varname) {
  # Computes the mean altitude of clouds
  lm=dim(vvv)[2]
  km=dim(vvv)[1]
  rm=matrix(0.,lm)
  hm=matrix(0.,lm)
  Ay=matrix(0.,lm)
  evol<-matrix(0.,km,lm)

  if ( substr(varname,1,5) == "theta" )  {
   for (l in 1:lm) {
   for (k in 1:km) {
	   evol[k,l]=min(vvv[k,l]-vvv[k,1],0.)
   }
   }
  } else {
   for (l in 1:lm) {
   for (k in 1:km) {
	   evol[k,l]=max(vvv[k,l]-vvv[k,1],0.)
   }
   }
  }

  # finding 
  for (l in 1:lm) {
    rm[l]=0.
    hm[l]=0.
    for (k in 2:km-1) { 
     if (zval[k+1]<zmax) {
        #rm[]<-rm[]+(zval[k]-zval[k+1])*(vvv[k,]+vvv[k+1,])*(rho[k,]+rho[k+1,])*0.25
        #hm[]<-hm[]+(zval[k]-zval[k+1])*(rho[k,]+rho[k+1,])*0.5
        rm[l]<-rm[l]+(zval[k]-zval[k+1])*(evol[k,l]+evol[k+1,l])*0.5
        hm[l]<-hm[l]+(zval[k]-zval[k+1])
    }}
    Ay[l]=rm[l]/hm[l]
    #print(c('rm[l]',rm[l]))
  }
  return(Ay)
}


#############################################################################
# Compute liquid water path
#############################################################################
compute_lwp <- function(zval,ql,zmax,varname) {
  # Computes the mean altitude of clouds
  lm=dim(ql)[2]
  km=dim(ql)[1]
  rm=rep(0,lm)
  hm=rep(0,lm)
  lwp=rep(0,lm)
  # finding 
  for (k in 2:km-1) { 
     if (zval[k+1]<zmax) {
        #rm[]<-rm[]+(zval[k]-zval[k+1])*(ql[k,]+ql[k+1,])*(rho[k,]+rho[k+1,])*0.25
        #hm[]<-hm[]+(zval[k]-zval[k+1])*(rho[k,]+rho[k+1,])*0.5
        rm[]<-rm[]+(zval[k]-zval[k+1])*(ql[k,]+ql[k+1,])*0.5
        hm[]<-hm[]+(zval[k]-zval[k+1])
     }}
    lwp[]=rm[]/hm[]
    return(lwp)
}

###############################################################################
# Quesaco ???
###############################################################################
extract_z <- function(zval,var,zselected) {
   # extract the value of the var at the selected altitude
   lm=dim(var)[2]
   km=dim(var)[1]
   valz=rep(0,lm)
   for (k in 2:km-1) { 
           #interpolation pour estimer la var a zselected
     if ((zval[k+1]-zselected)*(zval[k]-zselected) <= 0.) {
        valz[]=((var[k,]-var[k+1,])*zselected+(var[k+1,]*zval[k]-var[k,]*zval[k+1]))/(zval[k]-zval[k+1])
     } else {
        print('pas de valeur de z proche de zselected') 
     }
   }

  return(valz)
}


###############################################################################
# Choice of metrics
###############################################################################
get_metric <- function(nc_set,metric_name,ind_t,zmax) {
  # print(c('debut get metric',metric_name))
  if (length(nc_set$var$zf)) { 
    zf = ncvar_get(nc_set,"zf")
    if ( length(c(dim(zf))) == 1 ) { zval=rep(0,dim(zf)) ; zval[] = zf[] } else { zval=rep(0,dim(zf)[1]) ; zval[] = zf[,1]}
    km=length(zval)
  } else if (length(nc_set$var$pressure_hl))     { ecrad=T 
  } else if (length(nc_set$dim$vertical_levels)) { ecrad=F 
  } else { print('Unknown nc_set to compute metric in htune_metric.R') }
  
  if (metric_name == "netsurf") {
    varname = "flux_dn_sw"
    vardn = ncvar_get(nc_set,varname)
    varname = "flux_up_sw"
    varup = ncvar_get(nc_set,varname)
    if (ecrad) {ind_z=dim(vardn)[1]} else {ind_z=1}
    metric <- vardn[ind_z,] - varup[ind_z,]    

  } else if (metric_name == "nettoa") {
    varname = "flux_dn_sw"
    vardn = ncvar_get(nc_set,varname)
    varname = "flux_up_sw"
    varup = ncvar_get(nc_set,varname)
    if (ecrad) {ind_z=1} else {ind_z=dim(vardn)[1]}
    metric <- vardn[ind_z,] - varup[ind_z,]    

  } else if (metric_name == "ratio") {
    varname = "flux_dn_sw"
    vardn = ncvar_get(nc_set,varname)
    varname = "flux_dn_direct_sw"
    vardir = ncvar_get(nc_set,varname)
    if (ecrad) {ind_z=dim(vardn)[1]} else {ind_z=1}
    metric <- vardir[ind_z,]/vardn[ind_z,]

  } else if (metric_name=="dnsurf") {
    varname = "flux_dn_sw"
    vardn = ncvar_get(nc_set,varname)
    if (ecrad) {ind_z=dim(vardn)[1]} else {ind_z=1}
    metric <- vardn[ind_z,]

  } else if (metric_name=="transm") {
    varname = "flux_dn_sw"
    vardn = ncvar_get(nc_set,varname)
    if (ecrad) {ind_z1=dim(vardn)[1]} else {ind_z1=1}
    if (ecrad) {ind_z2=1} else {ind_z2=dim(vardn)[1]}
    metric <- vardn[ind_z1,]/vardn[ind_z2,]

  } else if (metric_name=="uptoa")  {
    varname = "flux_up_sw"
    vardn = ncvar_get(nc_set,varname)
    if (ecrad) {ind_z=1} else {ind_z=dim(vardn)[1]}
    metric <- vardn[ind_z,]

  } else if (metric_name == "std_netsurf") {
    varname = "std_flux_dn_sw"
    vardn = 3*ncvar_get(nc_set,varname)
    varname = "std_flux_up_sw"
    varup = 3*ncvar_get(nc_set,varname)
    if (ecrad) {ind_z=dim(vardn)[1]} else {ind_z=1}
    metric <- (vardn[ind_z,] + varup[ind_z,])^2

  } else if (metric_name == "std_nettoa") {
    varname = "std_flux_dn_sw"
    vardn = 3*ncvar_get(nc_set,varname)
    varname = "std_flux_up_sw"
    varup = 3*ncvar_get(nc_set,varname)
    if (ecrad) {ind_z=1} else {ind_z=dim(vardn)[1]}
    metric <- (vardn[ind_z,] + varup[ind_z,])^2    

  } else if (metric_name == "std_ratio") {
    varname = "flux_dn_sw"
    evardn = ncvar_get(nc_set,varname)
    varname = "std_flux_dn_sw"
    vardn = 3*ncvar_get(nc_set,varname)
    varname = "flux_dn_direct_sw"
    evardir = ncvar_get(nc_set,varname)
    varname = "std_flux_dn_direct_sw"
    vardir = 3*ncvar_get(nc_set,varname)
    if (ecrad) {ind_z=dim(vardn)[1]} else {ind_z=1}
    metric <- vardir[ind_z,]^2/vardn[ind_z,]^2 + vardir^2/evardn^2 + evardir^2/evardn^2

  } else if (metric_name=="std_dnsurf") {
    varname = "std_flux_dn_sw"
    vardn = 3*ncvar_get(nc_set,varname)
    if (ecrad) {ind_z=dim(vardn)[1]} else {ind_z=1}
    metric <- vardn[ind_z,]

  } else if (metric_name=="std_transm") {
    varname = "std_flux_dn_sw"
    vardn = 3*ncvar_get(nc_set,varname)
    if (ecrad) {ind_z=dim(vardn)[1]} else {ind_z=1}
    metric <- vardn[ind_z,]

  } else if (metric_name=="std_uptoa")  {
    varname = "std_flux_up_sw"
    vardn = 3*ncvar_get(nc_set,varname)
    if (ecrad) {ind_z=1} else {ind_z=dim(vardn)[1]}
    metric <- vardn[ind_z,]

  } else if (metric_name == "hur6000") {
    zsel=6900.
    varname="hur"
    var = ncvar_get(nc_set,varname)
    for (k in 2:(km-1)) {
      if ((zval[k]-zsel)*(zval[k+1]-zsel) <=0.) { ksel = k }
    }
    metric <- ((var[ksel,]-var[ksel+1,])*zsel+(var[ksel+1,]*zval[ksel]-var[ksel,]*zval[ksel+1]))/(zval[ksel]-zval[ksel+1])
 
  } else if (metric_name == "theta500") {
    zsel=500.
    varname="theta"
    var = ncvar_get(nc_set,varname)
    for (k in 2:(km-1)) {
      if ((zval[k]-zsel)*(zval[k+1]-zsel) <=0.) { ksel = k }
    }
    metric <- ((var[ksel,]-var[ksel+1,])*zsel+(var[ksel+1,]*zval[ksel]-var[ksel,]*zval[ksel+1]))/(zval[ksel]-zval[ksel+1])
 
  } else if (metric_name == "qv500") {
    zsel=500.
    varname="qv"
    var = ncvar_get(nc_set,varname)
    for (k in 2:(km-1)) {
      if ((zval[k]-zsel)*(zval[k+1]-zsel) <=0.) { ksel = k }
    }
    metric <- 1000.*((var[ksel,]-var[ksel+1,])*zsel+(var[ksel+1,]*zval[ksel]-var[ksel,]*zval[ksel+1]))/(zval[ksel]-zval[ksel+1])
 
  } else if ( (substr(metric_name,1,3) == "neb") ) {
    varname="rneb"
    var = ncvar_get(nc_set,varname)
    zhneb<-compute_zhneb(zval,var,zmax,metric_name)
    metric <- zhneb

  } else if ( (substr(metric_name,1,3) == "Ay-") ) {
    local_varname=substr(metric_name,4,nchar(metric_name))
    vvv  = ncvar_get(nc_set,local_varname)
    out <-compute_Ay(zval,vvv,zmax,local_varname)
    metric <- out

  } else if ( (metric_name == "lwp") ) {
    ql  = ncvar_get(nc_set,"ql")
    lwp<-compute_lwp(zval,ql,zmax,metric_name)
    metric <- lwp
  }
  return(metric)
}

#############################################################################
# Compute numerical noise = max second derivative of a variable
#############################################################################
compute_numerical_noise <- function(zmin,zmax,lmin,lmax,zf,var) {
  lm=dim(var)[2]
  km=dim(var)[1]
  dz_var<-matrix(0.,km-1,lm)
  d2z_var_max=0.
  for (l in lmin:lmax) {
      for (k in 1:km-1) {
          dz_var[k,l]=(var[k+1,l]-var[k,l])/(zval[k+1]-zval[k])
      }
      for (k in 2:km-1) {
          if (( zf[k] > zmin ) &  (zf[k]<zmax)) {
             #if ( l==lmin) { print(c(k,zval[k])) }
             d2z_var_<-2.*(dz_var[k,l]-dz_var[k-1,l])/(zval[k]-zval[k-1])
             d2z_var=1e12*d2z_var_*d2z_var_
             if ( d2z_var > d2z_var_max ) {
                  d2z_var_max=d2z_var
             }
          }
      }
  }
  return(d2z_var_max)
}


#############################################################################
# Compute numerical noise = max second derivative of a variable
#############################################################################
compute_numerical_noise_discret <- function(zmin,zmax,lmin,lmax,zf,var) {
  lm=dim(var)[2]
  km=dim(var)[1]
  dz_var<-matrix(0.,km-1,lm)
  d2z_var_max=0.
  for (l in lmin:lmax) {
      for (k in 1:km-1) {
          dz_var[k,l]=(var[k+1,l]-var[k,l])
      }
      for (k in 2:km-1) {
          if (( zf[k] > zmin ) &  (zf[k]<zmax)) {
             #if ( l==lmin) { print(c(k,zval[k])) }
             d2z_var_<-(dz_var[k,l]-dz_var[k-1,l])
             d2z_var=1e6*d2z_var_*d2z_var_
             if ( d2z_var > d2z_var_max ) {
                  d2z_var_max=d2z_var
             }
          }
      }
  }
  return(d2z_var_max)
}


#############################################################################
# Compute numerical noise = max second derivative of a variable
#############################################################################
compute_numerical_noise_up <- function(zmin,zmax,lmin,lmax,zf,var) {
  lm=dim(var)[2]
  km=dim(var)[1]
  dz_var<-matrix(0.,km-1,lm) 
  d2z_var<-matrix(0.,km,lm) 
  d2z_var_ave<-matrix(0.,lm) 
  d2z_var_max=0.
  for (l in lmin:lmax) {
      for (k in 1:km-1) {
          dz_var[k,l]=(var[k+1,l]-var[k,l])/(zval[k+1]-zval[k])
      }
      count<-0.
      for (k in 2:km-1) {
          #if (( zf[k] > zmin ) &  (zf[k]<zmax)) {
          if ( ( var[k,l] < 0.5 * var[1,l] ) & ( zf[k] > zmin ) & ( zf[k] < zmax ) ) {
          #if ( ( zf[k] > zmin ) & ( zf[k] < zmax ) ) {
             #if ( l==lmin) { print(c(k,zval[k])) }
             d2z_var_<-2.*(dz_var[k,l]-dz_var[k-1,l])/(zval[k]-zval[k-1])
             d2z_var[k,l]=1e12*d2z_var_*d2z_var_
             d2z_var_ave[l]<-d2z_var_ave[l]+d2z_var[k,l]*(zval[k]-zval[k-1])
             count=count+(zval[k]-zval[k-1])
          }
      }
      if ( count > 0 ) { d2z_var_ave[l]=d2z_var_ave[l]/count }
  }
  return(1000.*max(d2z_var_ave))
}

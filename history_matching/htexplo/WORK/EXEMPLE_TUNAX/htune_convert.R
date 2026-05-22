#############################################################################
# Auteur(e)s :  F. Hourdin
# Function to convert [-1,1] LHC to above scale
#############################################################################

#---------------------------------------------------------------------------------
# 2. Converting the sample paramter from [-1,1] to the physics world
#---------------------------------------------------------------------------------
  DesignConvert <- function(Xconts){
    conversion <- function(anX,lows,highs){
     ((anX+1)/2)*(highs-lows) +lows
    }
    param.lows.log <- param.lows
    param.highs.log <- param.highs
    param.lows.log[which.logs] <- log10(param.lows[which.logs])
    param.highs.log[which.logs] <- log10(param.highs[which.logs])
    tX <- sapply(1:length(param.lows), function(i) conversion(Xconts[,i],param.lows.log[i],param.highs.log[i]))
    tX[,which.logs] <- 10^tX[,which.logs]
    tX <- as.data.frame(tX)
    names(tX) <- param.names
    tX
  }

#---------------------------------------------------------------------------------
  DesignantiConvert <- function (Xconts){
#---------------------------------------------------------------------------------
#  Converting from physics parameters to [-1,1]
#  Xconts is the list of parameters for N parameters and M simulations without
#  the simulations names
#---------------------------------------------------------------------------------
    anticonversion <- function(newX,lows,highs){
     2*((newX-lows)/(highs-lows))-1
    }
    param.lows.log <- param.lows
    param.highs.log <- param.highs
    param.lows.log[which.logs] <- log10(param.lows[which.logs])
    param.highs.log[which.logs] <- log10(param.highs[which.logs])
    Xconts[,which.logs] <- log10(Xconts[,which.logs])
    tX <- sapply(1:length(param.lows), function(i) anticonversion(Xconts[,i],param.lows.log[i],param.highs.log[i]))
    tX <- as.data.frame(tX)
    names(tX) <- param.names
    tX
  }

#---------------------------------------------------------------------------------
  DesignantiConvert1D <- function (Xconts){
#---------------------------------------------------------------------------------
# Version of DesignantiConvert working for one row alone. Uses for the CTRL simulation
# Example : DesignantiConvert1D(param.defaults)
# where param.defaults comes from ModelParam.R
#---------------------------------------------------------------------------------

    anticonversion <- function(newX,lows,highs){
     2*((newX-lows)/(highs-lows))-1
    }
    param.lows.log <- param.lows
    param.highs.log <- param.highs
    param.lows.log[which.logs] <- log10(param.lows[which.logs])
    param.highs.log[which.logs] <- log10(param.highs[which.logs])
    Xconts[which.logs] <- log10(Xconts[which.logs])
    tX <- sapply(1:length(param.lows), function(i) anticonversion(Xconts[i],param.lows.log[i],param.highs.log[i]))
    tX <- as.data.frame(tX)
    tX
  }

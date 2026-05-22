#This R file can be sourced to provide all of the functions necessary to produce k-extended LHCs. 
#The last two lines in this file can be uncommented out and they will generate the same type of orthogonal maximin LHC used to compare performance against sliced LHCs in section 3.1. For further information on how to use the code, please contact the author.

require(lhs)
require(DoE.wrapper)
require(DiceDesign)
require(parallel)
toInts <- function(LH){
  n <- length(LH[,1])
  ceiling(n*LH)
}

# The correlation component criterion
RhoSq <- function(LH){
  A <- cor(LH)
  m <- dim(LH)[2]
  2*sum(A[upper.tri(A)]^2)/(m*(m-1))
}
# The inter-site distance for column j of MC
oneColDist <- function(LH, whichCol, k){
  D <- dist(LH[,whichCol],method="manhattan")
  D[D==0] <- 1/k
  D
}

# The coverage criterion
newphiP <- function(LH, k, p){
  tD <- oneColDist(LH,1,k)
  for(i in 2:(dim(LH)[2])){
    tD <- tD + oneColDist(LH,i,k)
  }
  sum(tD^(-p))^(1/p)
}

dbar <- function(n,m,k,tc){
  (m*n*tc*(tc*k*(n^2-1) + 3*(tc-1)))/(6*k*choose(tc*n,2))
}

# The coverage criterion lower band
newphiPL <- function(n, k, bard, p){
  choose(k*n,2)^(1/p)/bard
}

# The coverage criterion upper band
newphiPU <- function(n, m, k, p, tc){
  ((n*k^(p)*tc*(tc-1))/(2*m) + sum( tc^2*(n-c(1:(n-1)))/(m*c(1:(n-1))^p)))^(1/p)
}

# The final criterion
objectiveFun <- function(LH, w, p, phiU, phiL, k){
  rho <- RhoSq(LH)
  phiP <- newphiP(LH, k, p)
  w*rho + (1-w)*(phiP - phiL)/(phiU-phiL)
}

newphiL1 <- function(n, bard, p){
  upp <- ceiling(bard)
  low <- floor(bard)
  (choose(n,2)*(((upp - bard)/low^p) + ((bard - low)/upp^p)))^(1/p)
}

Sim.anneal.k <- function(tLHS, tc, k, n, m, w, p, Imax=1000, FAC_t=0.9, t0=NULL){
  Dcurrent <- tLHS
  tbard <- dbar(n=n,m=m,k=k,tc=tc)
  phiU <- newphiPU(n=n, m=m, k=k, p=p, tc=tc)
  if(tc<2)
    phiL <- newphiL1(n=n, bard=tbard, p=p)
  else
    phiL <- newphiPL(n=n, k=k, bard=tbard, p=p)
  # Deriving the initial temperature value
  if(is.null(t0)){
    delta <- 1/k
    rdis <- runif(n=choose(tc*n,2), min = 0.5*tbard, max=1.5*tbard)
    t0curr <- sum(rdis^(-p))^(1/p)
    rdis[which.min(rdis)] <- rdis[which.min(rdis)] - delta
    t0new <- sum(rdis^(-p))^(1/p)
    t0 <- (-1)*(t0new - t0curr)/log(0.99)
  }
  # Calculate the psi criterion value for the current LHC 
  psiDcurrent <- objectiveFun(Dcurrent, w=w, p=p, phiU=phiU, phiL=phiL, k=k)
  Dbest <- Dcurrent
  psiDbest <- psiDcurrent
  FLAG <- 1
  t <- t0
  while(FLAG==1){
    FLAG <- 0
    I <- 1
    while(I < Imax){ # Repeating the simulated annealing algorithm
      Dtry <- Dcurrent
      # Randomly select column in (c-1)n+1,..., cn
      j <- sample(1:m, 1) 
      i12 <- sample(c(((tc-1)*n+1):(tc*n)),2,replace=FALSE)
      # Permute elements of the rows within randomly selected column
      Dtry[i12,j] <- Dcurrent[c(i12[2],i12[1]),j] 
      # Calculate the psi criterion value for the newly generated LHC
      psiDtry <- objectiveFun(Dtry, w=w, p=p, phiU=phiU, phiL=phiL, k=k)
      if(psiDtry < psiDcurrent){
        Dcurrent <- Dtry
        psiDcurrent <- psiDtry
        FLAG <- 1
      }
      # Accept with acceptance probability
      else if((runif(1) < exp(-(psiDtry - psiDcurrent)/t))&(psiDtry!=psiDcurrent)){
        Dcurrent <- Dtry
        psiDcurrent <- psiDtry
        FLAG <- 1
      }
      if(psiDtry < psiDbest){
        Dbest <- Dtry
        psiDbest <- psiDtry
        #print(paste("New Dbest with psi = ", psiDbest, " found, reset I from I = ", I, sep=""))
        I <- 1
      }
      else{
        I <- I + 1
      }
    }
    # Reducing t (temperature)
    t <- t*FAC_t
    #print(t)
  }
  Dbest
}
# Draw a Latin Hypercube Sample from a set of uniform distributions for use in creating a Latin Hypercube
#design. This sample is taken in a random manner without regard to optimization
### Inputs
# n: number of points
# m: number of inputs
# p: (not sure)
# w: weights

### Output
# n by m dimension matrix of integers
FirstRankLHS <- function(n, m, p, w){
  tLHS <- randomLHS(n,m)
  # Provide order of rows in each column
  tLHS <- apply(tLHS, 2, order)
  Sim.anneal.k(tLHS=tLHS, tc=1, k=1, n=n, m=m, w=w, p=p, Imax=1000, FAC_t=0.8, t0=NULL)
}

###Generate a new integer LHC
### Input:
# CurrentBig: the original n-integer LHC
# n: numeber of points
# m: number of inputs
# k: number of extensions

### Output
# n by m dimension matrix of integers
MakeValidNewLHS <- function(CurrentBig, n, m, k){
  if(k*n <= n^m){
    Found <- FALSE
    while(!Found){
      anLHC <- apply(randomLHS(n,m),2,order)
      if(!any(dist(rbind(CurrentBig,anLHC), method="manhattan")==0))
        Found <- TRUE
    }
  }
  else{
    anLHC <- apply(randomLHS(n,m),2,order)
  }
  return(anLHC)
}
### Produce k n-point integer LHC with desirable properties (orthonormal maximin LHC)
### Inputs:
# n: number of points
# m: number of inputs
# k: number of extensions
# w: weights
# p: (?)
# FAC_t: simulated annealing parameter (temperature increment)
# startLHS: first n-point integer LHS 

### Output:
# k n-point integer LHC
MakeRankExtensionCubes <- function(n, m, k, w, p=50, FAC_t=0.8, startLHS=NULL, Imax){
  # Generate n-point integer LHC
  if(is.null(startLHS))
    lhs1 <- FirstRankLHS(n, m, p, w)
  else
    lhs1 <- as.matrix(toInts(startLHS))
  BigExtendedMatrix <- matrix(NA, nrow=k*n, ncol=m)
  # Assign first n-point integer LHC
  BigExtendedMatrix[1:n,] <- lhs1
  # Generate k extension to original n-point integer LHC
  for(i in 2:k){
    print(paste("Current extension = ", i, " of ", k, sep=""))
    newLHC <- MakeValidNewLHS(BigExtendedMatrix[1:((i-1)*n),],n=n,m=m,k=i)
    BigExtendedMatrix[((i-1)*n + 1):(i*n),] <- newLHC
    BigExtendedMatrix[1:(i*n),] <- Sim.anneal.k(tLHS=BigExtendedMatrix[1:(i*n),], tc=i, k=k, n=n, m=m, w=w, p=p, Imax=1000, FAC_t=FAC_t, t0=NULL)
  }
  lapply(1:k, function(e) BigExtendedMatrix[(1+(e-1)*n):(e*n),]) 
}

oneIN <- function(LHcolumn,left,right){
  any(which(LHcolumn>=left)%in%which(LHcolumn<right))
}
manyIN <- Vectorize(oneIN, c("left","right"))

### Produce a list of sub-solid for which the members of current 
### ExtendedLHC falls within this sub-solid
### Inputs:
# rankLHCrow: rectangular solid representation
# currentExtendedLHC: currently constructed cn-point LHC
# n: number of points
# d:number of dimensions
# increment: sub-solid parameter
# k: number of sub-solids

### Output:
# list
getPointers <- function(rankLHCrow,currentExtendedLHC, n, d, increment,k){
  leftmostedges <- (rankLHCrow-1)/n
  tleftmosts <- matrix(leftmostedges,nrow=k+1,ncol=d,byrow=T)
  leftedges <- matrix(rep(0:k,d),nrow=k+1,ncol=d)
  leftedges <- leftedges*increment + tleftmosts
  rightedges <- leftedges+increment
  sapply(1:d, function(j) which(manyIN(currentExtendedLHC[,j],leftedges[,j],rightedges[,j])))
}

### Sample sub-solid at random and return its value
### Inputs
# pointersRow: a list of sub-solid for which the members of current 
# ExtendedLHC falls within this sub-solid
# rankLHCrow: solid of which pointersRow sub-solid is part of
# increment: sub-solid parameter
# n: number of points
# d: number of inputs
# k: number of subsolids

###Output
# a vector of sampled value
sampleNewPoint <- function(pointersRow, rankLHCrow, increment, n, d, k){
  location <- runif(d)
  if(length(pointersRow[,1]) < k)
    newPoint <- sapply(1:d, function(j) sample(c(1:(k+1))[-pointersRow[,j]],1))
  else
    newPoint <- sapply(1:d, function(j) c(1:(k+1))[-pointersRow[,j]])
  (rankLHCrow-1)/n + (newPoint-1)*increment  + increment*location
}

### Function to generate K-extended Latin Hypercube
### Input:
# rankLHClist: a k list of n by m integer LHC
# LHCmaster: n-point LHC

###Output:
# a kn by m matrix, K-extended Latin Hypercube

NewExtendingLHS <- function(rankLHClist, LHCmaster=NULL){
  #there are k+1 rank LHCs in rankLHClist, which can be constructed using MakeRankExtensionCubes
  k <- length(rankLHClist) -1
  tdims <- dim(rankLHClist[[1]])
  n <- tdims[1]
  d <- tdims[2]
  increment=1/(n*(k+1))
  if(is.null(LHCmaster)){
    LHCmaster <- rankLHClist[[1]]
    LHCmaster <- (LHCmaster + runif(n*d) - 1)/n
  }
  pointers <- mclapply(1:n, function(e) {getPointers(rankLHClist[[2]][e,], LHCmaster,n=n,d=d,increment=increment,k=k)})
  pointers <- lapply(pointers, function(e) {dim(e) <- c(1,d);e})
  NewLHC1 <- t(sapply(1:n, function(l) sampleNewPoint(pointers[[l]], rankLHClist[[2]][l,], increment, n, d, k)))
  ExtendedLHC <- matrix(NA, nrow=n*(k+1), ncol=d)
  ExtendedLHC[1:n,] <- LHCmaster
  ExtendedLHC[(n+1):(2*n),] <- NewLHC1
  for(l in 3:(k+1)){
    pointers <- mclapply(1:n, function(e) getPointers(rankLHClist[[l]][e,],na.omit(ExtendedLHC),n=n,d=d,increment=increment,k=k))
    newLHC <- t(sapply(1:n, function(j) sampleNewPoint(pointers[[j]],rankLHClist[[l]][j,], increment, n,d,k)))
    ExtendedLHC[((l-1)*n+1):(l*n),] <- newLHC
  }
  ExtendedLHC
}


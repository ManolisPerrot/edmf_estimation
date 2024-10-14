# Author : 
# Modif 2018/08/17 : N. Villefranque
#     zmax is now defined in case_setup instead of plot_setup
###################

plot_setup <- function(case,var) {
   if ( substr(case,1,5) == "SANDU" ) {
     if (var=="theta") {
       xmin=290
       xmax=310
     }
     if (var=="ql") {
       xmin=0.
       xmax=0.001
     }
     if (var=="qv") {
       xmin=0.
       xmax=0.017
     }
     if (var=="rneb") {
       xmin=0.
       xmax=1.1
     }
   } else  if ( case == "IHOP" ) {
       if (var=="theta") {
         xmin=298
         xmax=312
       }
       if (var=="ql") {
         xmin=0.
         xmax=0.001
         print("PROBLEME CAR CAS SEC DONC PAS DE ql ni qv ni rneb")
       }
       if (var=="qv") {
         xmin=0.
         xmax=0.017
         print("PROBLEME CAR CAS SEC DONC PAS DE ql ni qv ni rneb")
       }
       if (var=="rneb") {
         xmin=0.
         xmax=1.1
         print("PROBLEME CAR CAS SEC DONC PAS DE ql ni qv ni rneb")
       }
   } else if ( substr(case,1,6) == "AYOTTE" ) {
       if (var=="theta") {
         xmin=305
         xmax=312
       }
       if (var=="ql") {
         xmin=0.
         xmax=0.001
         print("PROBLEME CAR CAS SEC DONC PAS DE ql ni qv ni rneb")
       }
       if (var=="qv") {
         xmin=0.
         xmax=0.017
         print("PROBLEME CAR CAS SEC DONC PAS DE ql ni qv ni rneb")
       }
       if (var=="rneb") {
         xmin=0.
         xmax=1.1
         print("PROBLEME CAR CAS SEC DONC PAS DE ql ni qv ni rneb")
       }
   } else if ( ( case == "ARMCU" ) | ( case == "BOMEX" ) | ( case == "SCMS" ) | ( case == "RICO" ) ) {
       if (var=="theta") {
         xmin=295
         xmax=315
       }
       if (var=="ql") {
         xmin=0.
         xmax=0.001
       }
       if (var=="qv") {
         xmin=0.
         xmax=0.018
       }
       if (var=="rneb") {
         xmin=0.
         xmax=0.3
       }
   } else if ( case == "RCE_OCE" ) {
       if (var=="theta") {
         xmin=295
         xmax=315
       }
       if (var=="hur") {
         xmin=0.
         xmax=1.
       }
       if (var=="ql") {
         xmin=0.
         xmax=0.001
       }
       if (var=="qv") {
         xmin=0.
         xmax=0.018
       }
       if (var=="rneb") {
         xmin=0.
         xmax=1.1
       }
   } else if ( substr(case,1,6) == "GABLS4" ) {
       if (var=="theta") {
         xmin=260
         xmax=290
       }
   } else {
       zmax=4000
       xmin=0.
       xmax=1.
   }

  c(xmin,xmax)
}

case_setup <- function(case) {
  if (case=="RADARMCU") { # This is comparison of Monte Carlo vs ECRAD for the ARMCu 8th time step
    NLES=1     # Only one MC output is available and the error is the statistical standard deviation estimated by Monte Carlo
    TimeLES=40 # Time is sza 46 available solar zenith angles
    TimeSCM=TimeLES
    zmax=4000
  }
  if ( substr(case,1,5) == "SANDU" ) {
    NLES=1
    TimeLES=68
    TimeSCM=68
    zmax=2500
  } 
  if ( case == "IHOP" ) {
    NLES=12
    TimeLES=10
    TimeSCM=10
    zmax=3000
  }
  if ( substr(case,1,6) == "AYOTTE" ) {
    NLES=8
    TimeLES=5
    TimeSCM=5
    zmax=2000
  }
  if ( case == "ARMCU" )  {
    NLES=9
    TimeLES=10
    TimeSCM=10
    zmax=3000
  }
  if ( case == "BOMEX" ) {
    NLES=9
    TimeLES=6
    TimeSCM=6
    zmax=3000
  }
  if ( case == "RICO" ) {
    NLES=9
    TimeLES=24
    TimeSCM=24
    zmax=3000
  }
  if ( case == "SCMS" ) {
    NLES=9
    TimeLES=10
    TimeSCM=10
    zmax=3000
  }
  if ( case == "RCE_OCE" ) {
    NLES=2
    TimeLES=400
    TimeSCM=400
    zmax=14000
  }
  if ( substr(case,1,6) == "GABLS4" ) {
    NLES=1
    TimeLES=23
    TimeSCM=23
    zmax=600
  }
  c(NLES,TimeLES,TimeSCM,zmax)
}


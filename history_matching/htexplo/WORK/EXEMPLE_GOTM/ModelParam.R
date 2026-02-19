NPARA=10
param.names=c("cc1","cc2","cc3","cc4","cc6","ct1","ct2","ct3","ct5","ctt")
param.lows=c(2.5000,0.4000,1.0000,0.5360,0.2000,2.9500,0.3000,0.5000,0.1533,0.3000)
param.highs=c(10.000,1.6000,4.0000,2.1360,0.8000,12.500,1.2000,2.0000,0.6633,1.4000)
param.defaults=c(5.0000,0.8000,1.9680,1.1360,0.4000,5.9500,0.6000,1.0000,0.3333,0.7200)
which.logs<-c()
  param.defaults <- param.defaults[1:NPARA]
  param.highs <- param.highs[1:NPARA]
  param.lows <- param.lows[1:NPARA]
  param.names <- param.names[1:NPARA]

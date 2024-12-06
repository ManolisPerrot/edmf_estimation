NPARA=9
param.names=c("Cent","Cdet","wp_a","wp_b","wp_bp","up_c","bc_ap","delta_bkg","wp0")
param.lows=c(0,1,0.01,0.01,0.25,0,0,0.25,1e-8)
param.highs=c(0.99,1.99,1.0,1.0,2.5,1.,0.45,2.5,1e-1)
param.defaults=c(0.9,1.7,0.9,0.9,2.,0.5,0.2,2.,0.5e-7)
which.logs<-c(9)
  param.defaults <- param.defaults[1:NPARA]
  param.highs <- param.highs[1:NPARA]
  param.lows <- param.lows[1:NPARA]
  param.names <- param.names[1:NPARA]

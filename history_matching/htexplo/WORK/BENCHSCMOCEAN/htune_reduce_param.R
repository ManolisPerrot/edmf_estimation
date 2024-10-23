args = commandArgs(trailingOnly=TRUE)
WAVEN=args[1]
file=paste("WAVE",WAVEN,"/Wave",WAVEN,".RData",sep="")
load(file)
NRUNS=dim(wave_param_US)[1]

file_asc=paste("WAVE",WAVEN,"/Par1D_Wave",WAVEN,".asc",sep="")
Par_asc <- read.csv(file_asc,header=TRUE,sep=" ")

inew=1
for ( iorig in 1:NRUNS ) {
	for ( name in Par_asc[,"t_IDs"] ) {
		if ( name == wave_param_US[iorig,1] ) {
		       	wave_param_US[inew,]=wave_param_US[iorig,]
			inew=inew+1
		}
	}
}

NRUNSnew=inew-1
wave_param_US=wave_param_US[1:NRUNSnew,]
save(wave_param_US,file=file)

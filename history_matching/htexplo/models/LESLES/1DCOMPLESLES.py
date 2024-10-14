from netCDF4 import Dataset
import numpy as np
import matplotlib.pyplot as plt
import datetime as dt  # Python standard library datetime  module
import sys

def diagnostLES(cas,typer):
	ifile=Dataset('COMPLESLES/tout'+cas+'.nc')

	print(ifile.dimensions.keys())
	print(ifile.variables.keys())

	ZF=ifile.variables['ZF'][:,:]
	QE=ifile.variables['QE'][:,:]
	QA=ifile.variables['QA'][:,:]
	A=ifile.variables['A'][:,:]
	A2=ifile.variables['A2'][:,:]
	SIG1=ifile.variables['SIG1'][:,:]
	SIG2=ifile.variables['SIG2'][:,:]
	SIG3=ifile.variables['SIG3'][:,:]
	WA=ifile.variables['WA'][:,:]
	WE=ifile.variables['WE'][:,:]
	RHO=ifile.variables['RHO'][:,:]
	EXPTKE=ifile.variables['EXPTKE'][:,:]
	THETA_A=ifile.variables['THETA_A'][:,:]
	THETA_E=ifile.variables['THETA_E'][:,:]

	beta1=0.686171532431566
	a1=0.686171532431566
	bbb=0.00407105690750225
	ccc=0.00821724940649555
	ddd=0.295968884682297
	eddz=0.235825774661526
	seuiltke=0.05
	dim=np.shape(ZF)
	im=1
	jm=1
	km=dim[1]
	lm=dim[0]
	print('lm=',lm,'km=',km)
	print('OK')
	thshf=np.zeros((lm,km))
	time_val=np.zeros((lm))
	fm=np.zeros((lm,km))
	ke=np.zeros((lm,km),dtype='i')
	kd=np.zeros((lm,km),dtype='i')
	deltaz=np.zeros((lm,km))
	delt_e=np.zeros((lm,km))
	delt_d=np.zeros((lm,km))
	detrmod=np.zeros((lm,km))
	entrmod=np.zeros((lm,km))
	zthetae=np.zeros((lm,km))
	zthetad=np.zeros((lm,km))
	entrpy=np.zeros((lm,km))
	detrpy=np.zeros((lm,km))
	dfdz=np.zeros((lm,km))
	dsdz=np.zeros((lm,km))
	flotpe=np.zeros((lm,km))
	flotpd=np.zeros((lm,km))
	xplot=np.zeros((lm,km))

	fm=RHO*A*WA
	print('TEST SHAPE')
	print(np.shape(ZF))
	print(np.shape(deltaz))

	for l in range(lm):
		time_val[l]=l
		for k in range(1,km):
			deltaz[l,k]=ZF[l,k]-ZF[l,k-1]
			dsdz[l,k]=(QA[l,k]-QA[l,k-1])/deltaz[l,k]
			dfdz[l,k]=(fm[l,k]-fm[l,k-1])/deltaz[l,k]
			if ( EXPTKE[l,k] > seuiltke ) :
				entrpy[l,k]=max(dsdz[l,k]/(QE[l,k]-QA[l,k]),0.)
				detrpy[l,k]=max(0,entrpy[l,k]-dfdz[l,k]/fm[l,k])


	for l in range(lm):
		for k in range(1,km):
			delt_e[l,k]=min(max(ZF[l,k]*eddz/deltaz[l,k],0.),400.)
			ke[l,k]=int(delt_e[l,k])
			kkk=min(max(k-ke[l,k],1),km-2)
			#zthetae[l,k]=THETA_E[l,kkk]*(1-delt_e[l,k]+kkk-k)+THETA_E[l,kkk+1]*(delt_e[l,k]-kkk+k)
			print("kkk", type(kkk))
			print("k", type(k),"ke", type(ke[l,k]))
			type(l)
			zthetae[l,k]=THETA_E[l,kkk]

			delt_d[l,k]=min(max(ZF[l,k]*eddz/deltaz[l,k],0.),400.)
			kd[l,k]=int(delt_d[l,k])
			kkk=min(max(k+kd[l,k],1),km-2)
			zthetad[l,k]=THETA_E[l,kkk]*(1-delt_d[l,k]+kkk-k)+THETA_E[l,kkk+1]*(delt_d[l,k]-kkk+k)
			if ( EXPTKE[l,k] > seuiltke ) :
				flotpe[l,k]=9.81*(THETA_A[l,k]-zthetae[l,k])/zthetae[l,k]
				entrmod[l,k]=max(0.0,1./(1.+beta1)*(a1*flotpe[l,k]/WA[l,k]**2-bbb))
				flotpd[l,k]=9.81*(THETA_A[l,k]-zthetad[l,k])/zthetad[l,k]
				detrmod[l,k]=max(0.0,-a1*beta1/(1.+beta1)*flotpd[l,k]/WA[l,k]**2+ccc*(QA[l,k]-QE[l,k])/(QE[l,k]*WA[l,k]**2)**ddd)


	###creation file echREF for LES calculated
	if typer == "echREF":
	   w_nc_rech = Dataset('echREF'+cas+'.nc', 'w', format='NETCDF4')
	   #####################################
	   # Coordonnees
	   #####################################
	   lon = w_nc_rech.createDimension('lon', 1) 
	   lat = w_nc_rech.createDimension('lat', 1)
	   level = w_nc_rech.createDimension('level', km) 
	   time = w_nc_rech.createDimension('time', lm ) 
	   #
	   latitudes=w_nc_rech.createVariable('lat',np.float32,('lat',))
	   longitudes=w_nc_rech.createVariable('lon',np.float32,('lon',))
	   levels=w_nc_rech.createVariable('vlev',np.float32,('level',))
	   times=w_nc_rech.createVariable('time',np.float32,('time',))

	   longitudes.units= 'degree_east'  
	   latitudes.units = 'degree_north'  
	   levels.units = 'm' 
	   times.units = 'hours since 2006-07-15 18:00:00'
	   times.calendar = 'gregorian' 

	   lon_val=np.zeros((1))
	   lat_val=np.zeros((1))
	   w_nc_rech.variables['lon'][:] = lon_val
	   w_nc_rech.variables['lat'][:] = lat_val
	   w_nc_rech.variables['vlev'][:] = ZF[1,:]
	   w_nc_rech.variables['time'][:] = time_val

	   #variable using

	   names=["zf","entr","detr"]
	   units=["m","/m","/m"]

	   for i in range(np.shape(names)[0]):
		    uid=w_nc_rech.createVariable(names[i],np.float32,('time','level','lat','lon'))
		    uid.units = units[i]

	   w_nc_rech.variables['zf'][:,:,:,:] = ZF
	   w_nc_rech.variables['entr'][:,:,:,:] = entrpy
	   w_nc_rech.variables['detr'][:,:,:,:] = detrpy
	   uid.units = '' 
	

	   w_nc_rech.close()#closethenewfile


	print("creation file echREF for LES calculated")
	if typer == "echCAL":
	   w_nc_rech = Dataset('echCAL'+cas+'.nc', 'w', format='NETCDF4')
	   lon = w_nc_rech.createDimension('lon', 1)
	   lat = w_nc_rech.createDimension('lat', 1)
	   level = w_nc_rech.createDimension('level', km)
	   time = w_nc_rech.createDimension('time',  lm )
	   latitudes=w_nc_rech.createVariable('lat',np.float32,('lat',))
	   longitudes=w_nc_rech.createVariable('lon',np.float32,('lon',))
	   levels=w_nc_rech.createVariable('vlev',np.float32,('level',))
	   times=w_nc_rech.createVariable('time',np.float32,('time',))

	   longitudes.units= 'degree_east'
	   latitudes.units = 'degree_north'
	   levels.units = 'm'
	   times.units = 'hours since 2006-07-15 18:00:00'
	   times.calendar = 'gregorian'

	   lon_val=np.zeros((1))
	   lat_val=np.zeros((1))
	   w_nc_rech.variables['lon'][:] = lon_val
	   w_nc_rech.variables['lat'][:] = lat_val
	   w_nc_rech.variables['vlev'][:] = ZF[1,:]
	   w_nc_rech.variables['time'][:] = time_val
	
	   #variable using

	   names=["zf","entr","detr"]
	   units=["m","/m","/m"]

	   for i in range(np.shape(names)[0]):
         	   uid=w_nc_rech.createVariable(names[i],np.float32,('time','level','lat','lon'))
         	   uid.units = units[i]

	   w_nc_rech.variables['zf'][:,:,:,:] = ZF
	   w_nc_rech.variables['entr'][:,:,:,:] = entrmod
	   w_nc_rech.variables['detr'][:,:,:,:] = detrmod
	   uid.units = ''


	   w_nc_rech.close()#closethenewfile

	return 

#pour lancer la fonction
if __name__ == '__main__':
	diagnostLES(sys.argv[1],sys.argv[2])

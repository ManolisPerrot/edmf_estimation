#-*- coding:UTF-8 -*-
Case='BOMEX'
from datetime import datetime

DIRDATA='./'

nomvar='theta'

# couleurs des courbes
#---------------------
# cycle de couleurs
listcoul=['black','red','green','fuchsia','blue','lime','darkviolet','cyan','darkorange','slateblue','brown','gold']

# exemple dictionnaire de couleurs en fonction du nom de fichier (sans le prefixe time_ ou prof_)
#black=reference; blue=bb; violet=turb, orange=pas de temps, Diffusion=vert, resolution=grey, advection=red, resv=brown,domain= microphysique=turquoise
dicocoul={\
'ensmin_SCM.nc' : 'violet',\
'ensmax_SCM.nc' : 'red',\
'ensavg_SCM.nc' : 'pink',\
'Out_klevel.nc' : 'black',\
'LES0.nc' : 'blue',\
'LES1.nc' : 'blue',\
'LES2.nc' : 'blue',\
'LES3.nc' : 'blue',\
'LES4.nc' : 'blue',\
'LES5.nc' : 'blue',\
'LES6.nc' : 'blue',\
'LES7.nc' : 'blue',\
'LES8.nc' : 'blue',\
}

dicostyl={\
'ensmin_SCM.nc' : '-',\
'ensmax_SCM.nc' : '-',\
'ensavg_SCM.nc' : '-',\
'Out_klevel.nc' : '-',\
'LES0.nc' : '-.',\
'LES1.nc' : '-.',\
'LES2.nc' : '-.',\
'LES3.nc' : '-.',\
'LES4.nc' : '-.',\
'LES5.nc' : '-.',\
'LES6.nc' : '-.',\
'LES7.nc' : '-.',\
'LES8.nc' : '-.',\
}

vmintab={\
        'theta' : 299,\
        'wu_shcon' : 0,\
        'alphau_shcon':0,\
        'mu_shcon':0,\
        'u':4,\
        'v':0,\
        'wth':-0.1,\
        'tke':0,\
        'th2':0,\
        'thu_shcon':299,\
        'ql':0,\
        'qlu_shcon':0,\
        'qt':0,\
        'qv':0,\
        'qtu_shcon':0,\
        'rneb':0,\
        'thvu_shcon':299,\
}

vmaxtab={\
        'theta' : 319,\
        'wu_shcon' : 3,\
        'alphau_shcon':0.5,\
        'mu_shcon':1.,\
        'u':16,\
        'v':7,\
        'wth':0.3,\
        'tke':5,\
        'th2':1.5,\
        'thu_shcon':319,\
        'ql':0.00005,\
        'qlu_shcon':0.005,\
        'qt':0.020,\
        'qv':0.020,\
        'qtu_shcon':0.020,\
        'rneb':1.,\
        'thvu_shcon':319,\
}
# listcoul ou dicocoul ou dicohightune ou ...
#coul1d=listcoul
styl1d=dicostyl
coul1d=dicocoul

# liste des fichiers sélectionnés
listfic=[\
'LES/BOMEX/REF/LES0.nc',\
'LES/BOMEX/REF/LES1.nc',\
'LES/BOMEX/REF/LES2.nc',\
'LES/BOMEX/REF/LES3.nc',\
'LES/BOMEX/REF/LES4.nc',\
'LES/BOMEX/REF/LES5.nc',\
'LES/BOMEX/REF/LES6.nc',\
'LES/BOMEX/REF/LES7.nc',\
'LES/BOMEX/REF/LES8.nc',\
'WAVE1/BOMEX/REF/ensmin_SCM.nc',\
'WAVE1/BOMEX/REF/ensavg_SCM.nc',\
'WAVE1/BOMEX/REF/ensmax_SCM.nc',\
'../../../../MUSC/simulations/arp631/CMIP6/L91_300s/BOMEX/REF/Output/netcdf/Out_klevel.nc',\
]
#'ensmin_A24SC.nc',\
#'ensmax_A24SC.nc'


# date de la forme : datetime(YYYY,MM,DD,H,M,S) sans 0 à gauche dans les nombres
dateprof=datetime(1969,6,24,5,30,0)
datedeb=datetime(1969,6,24,0,0,0)
datefin=datetime(1969,6,24,6,0,0)

# axe vertical altitude ou pression : 'z' ou 'p'
axevert='z'
zmin=0
zmax=3000
niv=500.

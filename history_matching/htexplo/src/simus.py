#-*- coding:UTF-8 -*-
# files that define the lists of the simulations you want to draw and also define information of the profiles
# time of the profile, color/style of the lines, xmin/xmax, ymin/ymax ranges)
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
'SCM.nc' : 'black',\
'LES0.nc' : 'slateblue',\
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
'SCM.nc' : '-',\
'LES0.nc' : '-',\
'LES1.nc' : '-.',\
'LES2.nc' : '-.',\
'LES3.nc' : '-.',\
'LES4.nc' : '-.',\
'LES5.nc' : '-.',\
'LES6.nc' : '-.',\
'LES7.nc' : '-.',\
'LES8.nc' : '-.',\
}

# listcoul ou dicocoul ou dicohightune ou ...
#coul1d=listcoul
styl1d=dicostyl
coul1d=dicocoul

# liste des fichiers sélectionnés
listfic=[\
'LES/'+Case+'/'+SubCase+'/LES0.nc',\
'LES/'+Case+'/'+SubCase+'/LES1.nc',\
'LES/'+Case+'/'+SubCase+'/LES2.nc',\
'LES/'+Case+'/'+SubCase+'/LES3.nc',\
'LES/'+Case+'/'+SubCase+'/LES4.nc',\
'LES/'+Case+'/'+SubCase+'/LES6.nc',\
'LES/'+Case+'/'+SubCase+'/LES7.nc',\
'LES/'+Case+'/'+SubCase+'/LES8.nc',\
'CTRL/'+Case+'/'+SubCase+'/SCM.nc',\
]
list_ens=[\
'WAVE1/'+Case+'/'+SubCase,\
]

Case='GABLS1'

vmintab={\
        'theta' : 262.5,\
        'WND' : 0,\
        'wu_shcon' : 0,\
        'alphau_shcon':0,\
        'mu_shcon':0,\
        'u':0,\
        'v':0,\
        'wth':-0.1,\
        'tke':0,\
        'th2':0,\
        'thu_shcon':265,\
        'ql':0,\
        'qlu_shcon':0,\
        'qt':0,\
        'qv':0,\
        'qtu_shcon':0,\
        'rneb':0,\
        'thvu_shcon':265,\
        'qi':0, \
        'rhl':50, \
        'rhi':50, \
}

vmaxtab={\
        'theta' : 268,\
        'WND' : 11,\
        'wu_shcon' : 3,\
        'alphau_shcon':0.5,\
        'mu_shcon':1.,\
        'u':11,\
        'v':5,\
        'wth':0.3,\
        'tke':0.9,\
        'th2':1.5,\
        'thu_shcon':285,\
        'ql':0.0007,\
        'qlu_shcon':0.005,\
        'qt':0.0030,\
        'qv':0.0030,\
        'qtu_shcon':0.0020,\
        'rneb':1.0,\
        'thvu_shcon':285,\
        'qi':0.0007, \
        'rhl':120, \
        'rhi':120, \
}

# date de la forme : datetime(YYYY,MM,DD,H,M,S) sans 0 à gauche dans les nombres
dateprof=datetime(2000,1,1,19,0,0)
datedeb=datetime(2000,1,1,10,0,0)
datefin=datetime(2000,1,1,19,0,0)

# axe vertical altitude ou pression : 'z' ou 'p'
axevert='z'
zmin=0
zmax=300.

niv=500.

# limites valeurs
#pour Theta
vmin=262
vmax=270


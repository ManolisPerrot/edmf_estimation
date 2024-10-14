Case='GABLS4'

vmintab={\
        'theta' : 260,\
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
        'theta' : 280,\
        'WND' : 7,\
        'wu_shcon' : 3,\
        'alphau_shcon':0.5,\
        'mu_shcon':1.,\
        'u':7,\
        'v':7,\
        'wth':0.3,\
        'tke':0.1,\
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
dateprof=datetime(2009,12,11,17,0,0)
datedeb=datetime(2009,12,11,0,0,0)
datefin=datetime(2009,12,12,12,0,0)

# axe vertical altitude ou pression : 'z' ou 'p'
axevert='z'
zmin=0
zmax=80.

niv=500.

# limites valeurs
#pour Theta
vmin=260
vmax=280


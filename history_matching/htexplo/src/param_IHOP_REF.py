Case='IHOP'

vmintab={\
        'theta' : 299,\
        'wu_shcon' : 0,\
        'alphau_shcon':0,\
        'mu_shcon':0,\
        'u':-15,\
        'v':-15,\
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
        'cc':0,\
}

vmaxtab={\
        'theta' : 319,\
        'wu_shcon' : 3,\
        'alphau_shcon':0.5,\
        'mu_shcon':1.,\
        'u':15,\
        'v':5,\
        'wth':0.3,\
        'tke':5,\
        'th2':1.5,\
        'thu_shcon':312,\
        'ql':0.00005,\
        'qlu_shcon':0.005,\
        'qt':0.013,\
        'qv':0.013,\
        'qtu_shcon':0.020,\
        'rneb':1.,\
        'thvu_shcon':319,\
        'cc':0.1,\
}

# date de la forme : datetime(YYYY,MM,DD,H,M,S) sans 0 à gauche dans les nombres
dateprof=datetime(2002,6,14,13,30,0)
datedeb=datetime(2002,6,14,6,0,0)
datefin=datetime(2002,6,14,18,0,0)

# axe vertical altitude ou pression : 'z' ou 'p'
axevert='z'
zmin=0
zmax=2600
niv=500.

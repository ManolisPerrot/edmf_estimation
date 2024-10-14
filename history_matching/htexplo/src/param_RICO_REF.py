Case='RICO'

vmintab={\
        'theta' : 297,\
        'wu_shcon' : 0,\
        'alphau_shcon':0,\
        'mu_shcon':0,\
        'u':-10,\
        'v':-5,\
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
        'thvu_shcon':297,\
        'fm':0,\
        'hur':0,\
        'qc':0,\
        'qcin':0,\
        'qi':0,\
        'wa':-0.5,\
        'temp':290,\
        'cc' :0,\
        'cldt' :0,\
        'cldl' :0,\
}

vmaxtab={\
        'theta' : 319,\
        'wu_shcon' : 3,\
        'alphau_shcon':0.5,\
        'mu_shcon':1.,\
        'u':0,\
        'v':5,\
        'wth':0.3,\
        'tke':5,\
        'th2':1.5,\
        'thu_shcon':319,\
        'ql':0.00005,\
        'qlu_shcon':0.005,\
        'qt':0.020,\
        'qv':0.020,\
        'qtu_shcon':0.020,\
        'rneb':0.5,\
        'thvu_shcon':319,\
        'fm':1,\
        'hur':1,\
        'qc':0.0001,\
        'qcin':0.01,\
        'qi':0.0001,\
        'temp':310,\
        'wa':7,\
        'cc':0.4,\
        'cldt':0.2,\
        'cldl':0.2,\
}


# date de la forme : datetime(YYYY,MM,DD,H,M,S) sans 0 à gauche dans les nombres
dateprof=datetime(2004,12,27,21,30,0)
datedeb=datetime(2004,12,27,0,0,0)
datefin=datetime(2004,12,28,0,0,0)

# axe vertical altitude ou pression : 'z' ou 'p'
axevert='z'
zmin=0
zmax=3300
niv=500.

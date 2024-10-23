import numpy as np
import xarray as xr
import os

def maketkeonzf(fichier):
 
    newfichier='tkezf_' + fichier
    cmd='cp '+ fichier +' ' + new_fichier
    os.system(cmd)
    ds=xr.Dataset(newfichier)
    zf=ds.variables('zf')[:]
    zh=ds.variables('zh')[:]
    tke=ds.variables('tke')[:]


    tkezf=






list_file=['gabls1_UIB_2m_allvar_hourmean.nc','gabls1_IMUK_1m_allvar_hourmean.nc','gabls1_MO_2m_allvar_hourmean.nc','gabls1_IMUK_2m_allvar_hourmean.nc','gabls1_UIB_2m_allvar_hourmean.nc']

for fichier in list_file:
    maketkeonzf(fichier)




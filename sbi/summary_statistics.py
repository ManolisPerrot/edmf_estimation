
#!/usr/bin/env python
# coding: utf-8

###########################################
# Imports
###########################################

import sys  # to put the SCM into the PYTHONPATH
sys.path.append('../edmf_ocean/library/F2PY/')
sys.path.append('../')
from sys import exit
import time as TIME
import xarray as xr
from scipy.interpolate import interp1d
import scipy.signal
from scm_class import SCM
from netCDF4 import Dataset
import matplotlib.pyplot as plt
import numpy as np
from case_configs import case_params, default_params
from multiprocess import Pool #multiprocessING cannot handle locally defined functions, multiprocess can
import subprocess

from edmf_simulator import simulator
from joblib import Parallel, delayed
from tqdm import tqdm
from tqdm_joblib import tqdm_joblib
import torch


#TODO fix check version path bug
# from test_version_edmf_ocean import check_edmf_ocean_version
# check_edmf_ocean_version()


edmf_params_names=[     'Cent',
                        'wp_a',
                        'Cdet',
                        'wp_b',
                        'wp_bp',
                        'vp_c',
                        'up_c',
                        'bc_ap',
                        'delta_bkg',
                        'wp0' ]

#------------------------------------
# Functions from Garanaik et al  
#------------------------------------

# Constants  
g = 9.81  
rho = 1026.0  
alphaT = 2e-4  
betaS = 8e-4  
  
  
# Functions from Garanaik et al  
def density_eos(t, s):  
    """Density calculation from given temp and salinity"""  
    density = rho * (1.0 - alphaT * (t - 20) + betaS * (s - 35))  
    return density  
  
  
def bld(t, s, z):  
    """OSBL depth corresponding to max N2"""  
    density = density_eos(t, s).T
    N2 = np.gradient(-density, z, axis=1)  
    bld_vals = np.zeros(len(N2[:, 0]))  
    dz = z[1] - z[0]  
      
    for t_idx in np.arange(len(N2[:, 0])):  
        i = N2[t_idx, :].argmax()  
          
        # quadratic interpolation  
        f_1, f0, f1 = N2[t_idx, i - 1], N2[t_idx, i], N2[t_idx, i + 1]  
        delta = (f_1 - f1) / (2.0 * (f_1 - 2.0 * f0 + f1))  
        bld_vals[t_idx] = z[i] + delta * dz  
      
    return np.nanmean(bld_vals)  # depth corresponding to max N2 averaged over time  

def mld_12_h (theta):
    x = simulator(theta,verbosity=False)
    mld = np.empty(len(x))
    for i,sim in enumerate(x):
        t = sim.t_history
        s = np.ones_like(t)*32.6
        z=sim.z_r
        mld[i] = (bld(t[:,-12:],s[:,-12:],z))
    return mld

def mld_12_h_batched(theta):
    # theta = np.atleast_2d(theta)
    outputs = np.empty((theta[0].shape,2))
    for i, th in enumerate(theta):
        outputs[i] = mld_12_h(theta[i])
    return outputs

param_default = np.array([0.99,1.99,    1.3,  1.3,   0.003*250,    0.5, 0.5,0.2,    0.009*250,   -0.5e-08])


def mld_12_h_reduced(theta):
    theta = np.atleast_2d(theta)
    outputs = np.empty((theta.shape[0], 2))
    for i, th in enumerate(theta):
        params = param_default.copy()
        params[0]  = th[0]    # Cent
        params[-3] = th[1]    # bc_ap
        outputs[i] = mld_12_h(params)
    return outputs

def my_simulator_for_sbi(simulator,proposal,num_simulations):
    theta =proposal.sample((num_simulations,))
    with tqdm_joblib(tqdm(total=num_simulations)) as progress_bar:
        x_np = Parallel(n_jobs=-1,batch_size='auto')(delayed(simulator)(theta[i]) for i in range(theta.shape[0]))
    #convert to torch
    x = torch.from_numpy(np.array(x_np).astype(np.float32)).squeeze()
    return theta,x

if "__name__"=="__main__":
    theta=[
        0.99,
        1.99,       # 'Cdet': 2.5,
        1.3,   #1
        1.3,     #1.
        0.003*250,    
        0.5, 
        0.5,
        0.2,    #0.3,
        0.009*250,   # 0.005,
        -0.5e-08]
    print (mld_12_h(theta))


# theta=[
#     0.99,
#     1.99,       # 'Cdet': 2.5,
#     1.3,   #1
#     1.3,     #1.
#     0.003*250,    
#     0.5, 
#     0.5,
#     0.2,    #0.3,
#     0.009*250,   # 0.005,
#     -0.5e-08]
# print (mld_12_h(theta))

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
# from scm_class import SCM
# from netCDF4 import Dataset
import matplotlib.pyplot as plt
import numpy as np
from case_configs import case_params, default_params
from multiprocess import Pool #multiprocessING cannot handle locally defined functions, multiprocess can
import subprocess

from joblib import Parallel, delayed
from tqdm import tqdm
from tqdm_joblib import tqdm_joblib
import time

# sbi-related imports
from sbi.inference import NPE, simulate_for_sbi  
from torch.func import vmap
import torch
from sbi import utils as utils  
from sbi import analysis as analysis  
from sbi.utils.user_input_checks import (  
    check_sbi_inputs,  
    process_prior,  
    process_simulator,  
)  

#my simulator imports
from summary_statistics import bld,density_eos,mld_12_h,mld_12_h_reduced,mld_12_h_batched,my_simulator_for_sbi
from edmf_simulator import simulator




param_default = np.array([0.99,1.99,    1.3,  1.3,   0.003*250,    0.5, 0.5,0.2,    0.009*250,   -0.5e-08])
param_names = [     
'Cent',
'wp_a',
'Cdet',
'wp_b',
'wp_bp',
'vp_c',
'up_c',
'bc_ap',
'delta_bkg',
'wp0' ] 

prior_min = np.array([0.,1.,0., 0., 0.,0.,0.,0.,-1e-8])
prior_max = np.array([1.,2.,1.,1.,3.,1.,0.45,3.,-0.1])


# prior_min = np.array([0.,0.])
# prior_max = np.array([1.,1.])


print(f"Parameters to calibrate: {param_names}")  
# print(f"Default values: {dict(zip(param_names, param_guess))}")  
print(f"Prior bounds: {dict(zip(param_names, zip(prior_min, prior_max)))}") 
# Step 5: Set up SBI  
print("\n" + "="*60)  
print("Setting up Simulation-Based Inference")  
print("="*60) 

prior = utils.torchutils.BoxUniform(  
    low=torch.as_tensor(prior_min),   
    high=torch.as_tensor(prior_max)  
)  

num_samples = 1000
num_rounds = 5
x_o = torch.tensor( [-320,-320]) #fake obseverd mld_12_h

# # Ensure compliance with sbi's requirements.
# prior, num_parameters, prior_returns_numpy = process_prior(prior)
# simulator = process_simulator(mld_12_h, prior, prior_returns_numpy)
# check_sbi_inputs(simulator, prior)

#SNPE inference

inference = NPE(prior)
posteriors = []
proposal = prior
simulator=mld_12_h



for _ in range(num_rounds):
    theta, x = my_simulator_for_sbi(simulator,proposal,num_simulations=num_samples)
    # In `SNLE` and `SNRE`, you should not pass the `proposal` to
    # `.append_simulations()`
    x.nan_to_num_(nan=0.0)
    theta = torch.nan_to_num(theta, nan=0.0)
    density_estimator = inference.append_simulations(
        theta, x, proposal=proposal
    ).train()
    posterior = inference.build_posterior(density_estimator)
    posteriors.append(posterior)
    proposal = posterior.set_default_x(x_o)

#sampling and plotting
samples = posterior.sample((10_000,), x=x_o)  

# Step 9: Visualize results  
print("\n" + "="*60)  
print("Step 9: Generating results")  
print("="*60)  

# Reference parameters 
true_params = 1.0*param_default
  
fig, axes = analysis.pairplot(  
    samples,  
    limits=(np.array([prior_min, prior_max]).T).tolist(),  
    figsize=(5, 5),  
    points=true_params,  
    labels=param_names,  
)
saving_name = 'SNPE_posterior_pairplot.png'
plt.savefig( saving_name, dpi=150, bbox_inches='tight')  
print(f"Saved posterior plot to: {saving_name}")   
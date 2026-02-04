
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

cases = ['FC500', 'W005_C500_NO_COR']
    
def run_one_case(params_to_estimate,case_index,verbosity):
    # Load the case specific parameters
    # ATTENTION, any parameter entered in case params will 
    # OVERWRITE default params. Double-check case_configs before running
    case=cases[case_index]
    # ====================================Run the SCM cases=======================================
    params = default_params.copy()  # Create a copy of default_params
    params.update(case_params[case])  # Update with the specific case hyperparameters in case_params[case]
    params.update(params_to_estimate) # Update with the parameters to estimate 
    #print(params)
    if verbosity: 
        print(f'Running EDMF for case {case} with configurations and parameters {params_to_estimate}')
        print(f'Full configuration hyperparameters')
        print(params)
    scm = SCM(**params)
    scm.run_direct()            # Run the SCM
    if verbosity:
        print('EDMF simulation terminated, case',case+": zinv =", scm.zinv)
    return scm



def simulator(theta,verbosity=False):
    params_to_estimate = {name: val for name,val in zip (edmf_params_names,theta)}
    if verbosity: print(params_to_estimate)
    # parrallelized for-loop
    # 
    def run_one_case_wrapped(case_index):
        #wrap run_one_case to use parrallelized loop
        return run_one_case(params_to_estimate, case_index,verbosity)
    # with Pool() as p:
    #     scm = p.map(run_one_case_wrapped, range(len(cases)))
    scm = [run_one_case_wrapped(i) for i in range(len(cases))]
         
    return scm
       



####################
#  test
####################
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
    x = simulator(theta,verbosity=True)
# params_to_estimate = {name: val for name,val in zip (edmf_params_names,theta)}
# scm = run_one_case(params_to_estimate,0,verbosity=True)

    print(x)





#TODO prompt/doiscard errors 
    # if ret_log_likelihood:
    #     if np.isnan(tot_log_likelihood) or np.isnan(tot_likelihood):
    #         return -10000.0
    #         #write parameters leading to Nan is a file
    #         with open(nan_file, "a") as file:
    #             file.write("\n")
    #             for key, value in params_to_estimate.items():
    #                 file.write(f"{key}: {value}\n")
    #             file.write("\n")
    #         #fix estimation crash by putting 0. for NaN
    #         return 0.
    #     return tot_log_likelihood
    
    # if np.isnan(tot_likelihood):
    #     #write parameters leading to Nan is a file
    #     with open(nan_file, "a") as file:
    #         file.write("\n")
    #         for key, value in params_to_estimate.items():
    #             file.write(f"{key}: {value}\n")
    #         file.write("\n")
    #     #fix estimation crash by putting 0. for NaN
    #     return 0.
    # else:
    #     return tot_likelihood




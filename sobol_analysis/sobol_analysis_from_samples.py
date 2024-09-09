###########################################
# Imports
###########################################
import sys #to put the SCM into the PYTHONPATH
sys.path.append('../edmf_ocean/library/F2PY/')
from sys import exit
import sys 
sys.path.append('../')
from sys import exit
import numpy as np
import matplotlib.pyplot as plt
# from scm_oce import direct_scmoce
#from scipy.io import netcdf
from netCDF4 import Dataset
from scm_class import SCM
from scipy.interpolate import interp1d
import scipy as sci
import netCDF4 as nc
import xarray as xr
#from cost_function_HIRES10 import cost_function
import itertools
import scipy.stats.qmc as qmc
from multiprocessing import Pool
import pickle
from case_configs import case_params, default_params
import time as TIME
start = TIME.time() #monitor duration of execution 
###########################################

### WARNING: small_ap = False causes many divergent values (theta > 10^50) or NaNs

N = 512
# cases=['FC500','W005_C500_NO_COR']
cases=['FC500']
case = cases[0] 
fields = ['temp']

samples={}

with open('outputs/samples_FC500_'+str(N), 'rb') as handle:
    # with open('outputs/sobol_'+nsample, 'rb') as handle:
    samples = pickle.load(handle)

saving_name = 'sobol_'+cases[0]+'_'+str(N)
print(saving_name)

nvar = len(samples['variables_range'])
time = {case: samples[case]['coordinates']['time'][case] for case in cases}
variables = samples['variables_range']
    
### Define a L2 inner product because output of the model are functions    
def product (T1,T2, z_r, time):
    # T1 and T2 must be (z_r,time) arrays
    return np.trapz( np.trapz( T1 * T2, z_r, axis=0) , time)  

### Compute L2 enumerators of 1st Sobol and total indices 
def l2_enumerators(Y,Y_prime,Y_tilde,meanY,meanY_tilde, denominator_l2, discarded_samples,discarded_samples_prime,discarded_samples_tilde,z_r,time):
    MeanSquaredL2 = product(meanY,meanY_tilde,z_r,time) 
    # MeanSquaredL2 = product(meanY,meanY,z_r,time) 

    
    enumerator_l2 = 1/(N-discarded_samples_tilde-discarded_samples) * sum( product(Y[i],Y_tilde[i],z_r,time) for i in range(N) ) - MeanSquaredL2
    # enumerator_total_l2 = denominator_l2 - 1/(N-discarded_samples_tilde-discarded_samples_prime) * sum( product(Y_prime[i],Y_tilde[i],z_r,time) for i in range(N) ) + MeanSquaredL2   
    enumerator_total_l2 =  1/(N-discarded_samples_tilde-discarded_samples_prime) * sum( product(Y_prime[i],Y_tilde[i],z_r,time) for i in range(N) ) - MeanSquaredL2   


    return enumerator_l2, enumerator_total_l2      

### Compute (z,t=endtime) enumerators of 1st Sobol and total indices
def z_enumerators(Y,Y_prime,Y_tilde,meanY,meanY_tilde,denominator_z, discarded_samples,discarded_samples_prime,discarded_samples_tilde):
    MeanSquared_z= meanY[:,-1] * meanY_tilde[:,-1]

    enumerator_z =  1/(N-discarded_samples_tilde-discarded_samples) * sum( (Y[i][:,-1] * Y_tilde[i][:,-1]) for i in range(N) ) - MeanSquared_z
    enumerator_total_z = denominator_z - 1/(N-discarded_samples_tilde-discarded_samples_prime) * sum( (Y_prime[i][:,-1] * Y_tilde[i][:,-1]) for i in range(N) ) + MeanSquared_z
    return enumerator_z, enumerator_total_z    

def discard_NaNs(Y):
    where_are_NaNs = np.isnan(Y)
    # limiter = np.abs(Y)>10
    epsilon=1e-8
    Y[where_are_NaNs]=epsilon #replace Nans by 0
    discarded_samples = np.any(where_are_NaNs, axis=(1, 2)).sum() 
    return Y, discarded_samples

#============================ MAIN LOOP =========================================

# initialize output
output={'variables_range': variables}

for case in cases:
    z_r = samples[case]['coordinates']['z_r']
    for field in fields:
        print('Analysis of the case '+case)
        Y = samples[case]['variables'][field]['Y']
        Y, discarded_samples = discard_NaNs(Y)
        #
        Y_prime = samples[case]['variables'][field]['Y_prime']
        Y_prime, discarded_samples_prime = discard_NaNs(Y_prime)


        meanY = 1/(N-discarded_samples) *sum(Y[i] for i in range(N))
        denominator_l2 = 1/(N-discarded_samples) * sum( product(Y[i],Y[i],z_r,time[case]) for i in range(N) ) - product(meanY,meanY,z_r,time[case])
        denominator_z = 1/(N-discarded_samples) * sum( (Y[i][:,-1])**2 for i in range(N) ) - (meanY[:,-1])**2

        S = {'sobol_indices':{}, 'z_r': z_r}

        for parameter in samples['X_tilde']:

            Y_tilde = samples[case]['variables'][field]['Y_tilde'][parameter]

            Y_tilde, discarded_samples_tilde = discard_NaNs(Y_tilde) 
            meanY_tilde =   1/(N-discarded_samples_tilde) *sum(Y_tilde[i] for i in range(N))

            enumerator_l2, enumerator_total_l2 = l2_enumerators(Y,Y_prime,Y_tilde,meanY,meanY_tilde,denominator_l2, discarded_samples,discarded_samples_prime,discarded_samples_tilde,z_r,time[case])

            enumerator_z, enumerator_total_z = z_enumerators(Y,Y_prime,Y_tilde,meanY,meanY_tilde, denominator_z, discarded_samples,discarded_samples_prime,discarded_samples_tilde)


            S['sobol_indices'][parameter] = {field: 
                                        {'l2 index': enumerator_l2/denominator_l2,
                                        'enumerator_l2': enumerator_l2,
                                        'denominator_l2': denominator_l2,
                                        'enumerator_total_l2':enumerator_total_l2,
                                        # 'total l2 index': enumerator_total_l2/denominator_l2,
                                        'total l2 index': 1 - enumerator_total_l2/denominator_l2,

                                        'z index': enumerator_z/denominator_z,
                                        'enumerator_z':enumerator_z,
                                        'denominator_z': denominator_z,
                                        'enumerator_total_z': enumerator_total_z,
                                        'total z index': enumerator_total_z/denominator_z,
                                        'discarded_samples': discarded_samples,
                                        'discarded_samples_tilde': discarded_samples_tilde,
                                        'discarded_samples_prime': discarded_samples_prime    
                                        }
                                        }

    output[case] = S

#==========================
# Save output
with open('outputs/'+saving_name, 'wb') as handle:
    pickle.dump(output, handle, protocol=pickle.HIGHEST_PROTOCOL)
print('Done! Output saved at '+'outputs/'+saving_name)
stop = TIME.time()
print('duration of execution', stop-start)
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

### Choose physical cases on which to perform analysis
cases = ['FC500', 'W005_C500_NO_COR']
variables =  [['Cent',[0., 1.]],
              ['Cdet',[1., 2.]],
              ['wp_a',[0.01, 1.]],
              ['wp_b',[0.01, 1.]],
              ['wp_bp',[0., 10.]],
              ['up_c',[0., 0.99]],
              ['vp_c',[0., 0.99]],
              ['bc_ap',[0., 1.]],
              ['delta_bkg',[0., 10.]],
              ['wp0',[-1e-3,-1e-2]]
             ]


N = 2**4 ### Set number of samples 
nvar = len(variables)
time={ case: np.arange(start=0, stop=case_params[case]['nbhours'], step=default_params['outfreq']) for case in cases}
saving_name = 'sobol_'+str(N)


#### SAMPLING twice the parameters and a copy (choose either Uniform or Latin Hyper Cube) 
    
    
#Uniform Sampling
#X_samples = np.zeros((nvar,N))       #('names' index, sample index)
#X_prime_samples = np.zeros((nvar,N)) #('names' index, sample index)
#    
#
#for i in range(nvar):  
#    X_samples[i] = np.random.uniform(low=variables[i][1][0],high=variables[i][1][1],size=N)
#    X_prime_samples[i] = np.random.uniform(low=variables[i][1][0],high=variables[i][1][1],size=N)    

# Latin Hyper cube sampling
print('Initial sampling of parameter space, number of samples:', N)
X_samples = qmc.LatinHypercube(nvar).random(N).T  #LHC is between 0 and 1, so ling is needed
X_prime_samples = qmc.LatinHypercube(nvar).random(N).T


for i in range(nvar):#LHC is between 0 and 1, so rescaling is needed
    X_samples[i,:] =  variables[i][1][0] + X_samples[i,:] * (variables[i][1][1] - variables[i][1][0])
    X_prime_samples[i,:] = variables[i][1][0] + X_prime_samples[i,:] * (variables[i][1][1] - variables[i][1][0])
    

###DEFINE Projectors for higher order indices 
# P['order of interaction']['name of variables interacting'] is a np.array of shape (nvars), with 1. 
# at the position of the indices at zero elsewhere
P={}
for order in range(1, nvar):
    P[str(order) + 'th'] = {}
    for indices in itertools.combinations(range(nvar), order):
        #key = ','.join(map(str, indices))
        key = ''
        for i in range(0,order-1):
            key = key+variables[indices[i]][0]+' '
        key = key+variables[indices[-1]][0]
        P[str(order) + 'th'][key] = np.zeros(nvar)
        for i in indices:
            P[str(order) + 'th'][key][i] = int(1)

#=========================================
#============= FUNCTIONS =================
#=========================================

def scm_temp(X, case, return_z_r = False):
    # ====================================Run the SCM cases=======================================
    params = default_params.copy()  # Create a copy of default_params
    params.update(case_params[case])  # Update with the specific case hyperparameters in case_params[case]

    # unpack X values in the form of a dictionary. 
    params_to_estimate = { variables[i][0]: X[i] for i in range(len(variables))} 
    params.update(params_to_estimate) # Update with the parameters to estimate

    scm = SCM(**params)
    scm.run_direct()            # Run the SCM

    # if return_z_r:
    #     return scm.t_history,scm.u_history,scm.v_history, scm.z_r
    # else:
    #     return scm.t_history,scm.u_history,scm.v_history 
    if return_z_r:
        return scm.t_history, scm.z_r
    else:
        return scm.t_history
    
### Define a L2 inner product because output of the model are functions    
def product (T1,T2, z_r, time):
    # T1 and T2 must be (z_r,time) arrays
    return np.trapz( np.trapz( T1 * T2, z_r, axis=0) , time)  

#============================ MAIN LOOP =========================================

# initialize output
output={'variables_range': variables}

for case in cases:
    print('Analysis of the case '+case)
    ### Compute Y = f(X)    
    Y = [0]*N

    # Do a first evaluation to get z_r
    Y[0], z_r = scm_temp(X_samples[:,0], case, return_z_r=True)

    # wrap scm_temp
    def scm_temp_wrapped(X):
        return scm_temp(X,case,return_z_r=False)

    # parrallel evaluation of the model
    if __name__ == '__main__':
        with Pool() as p:
            Y[1:] = p.map(scm_temp_wrapped, X_samples.T[1:])

    meanY = 1/N *sum(Y[i] for i in range(N))
    denominator_l2 = 1/N * sum( product(Y[i],Y[i],z_r,time[case]) for i in range(N) ) - product(meanY,meanY,z_r,time[case])

    denominator_z = 1/N * sum( (Y[i][:,-1])**2 for i in range(N) ) - (meanY[:,-1])**2

    S = {'sobol_indices':{}, 'z_r': z_r}

    for key in P['1th']:
        projector=P['1th'][key]
        #compute Y_prime = f(X_tilde)
        Y_prime, X_tilde = [0]*N, np.zeros((N,nvar))
        for i in range(0,N):
            X_tilde[i] = projector * X_samples [:,i] + (1-projector) * X_prime_samples [:,i]

        if __name__ == '__main__':
            with Pool() as p:
                Y_prime = p.map(scm_temp_wrapped, X_tilde)
            
        meanY_prime = 1/N *sum(Y_prime[i] for i in range(N))
        enumerator_l2 = 1/N * sum( product(Y[i],Y_prime[i],z_r,time[case]) for i in range(N) ) - product(meanY,meanY_prime,z_r,time[case])
        enumerator_z = 1/N * sum( (Y[i][:,-1] * Y_prime[i][:,-1]) for i in range(N) ) - meanY[:,-1] * meanY_prime[:,-1]

        S['sobol_indices'][key] = { 'l2 index': enumerator_l2/denominator_l2,
                                    'enumerator_l2': enumerator_l2,
                                    'denominator_l2': denominator_l2,
                                    'z index': enumerator_z/denominator_z,
                                    'enumerator_z':enumerator_z,
                                    'denominator_z': denominator_z }

    output[case] = S

#==========================
# Save output
with open('outputs/'+saving_name, 'wb') as handle:
    pickle.dump(output, handle, protocol=pickle.HIGHEST_PROTOCOL)
print('Done! Output saved at '+'outputs/'+saving_name)
stop = TIME.time()
print('duration of execution', stop-start)
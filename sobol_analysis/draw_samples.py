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
# cases = ['FC500', 'W005_C500_NO_COR']
cases = ['FC500']
### Set number of samples 
N = 1024
print(N)
# saving_name = 'sobol_beta1_ap0_'+str(N)
saving_name = 'samples_'+cases[0]+'_'+str(N)
print(saving_name)

# cases = ['W005_C500_NO_COR']

variables =  [
              ['Cent',[0., 0.99]],
              ['Cdet',[1., 1.99]],
              ['wp_a',[0.01, 1.]],
              ['wp_b',[0.01, 1.]],
              ['wp_bp',[0.25, 2.5]],
              ['up_c',[0., 0.9]],
              ['bc_ap',[0., 0.45]],
              ['delta_bkg',[0.25, 2.5]],
              ['wp0',[-1e-8,-1e-7]]
             ]


nvar = len(variables)
time={ case: np.arange(start=0, stop=case_params[case]['nbhours'], step=default_params['outfreq']) for case in cases}


#### SAMPLING twice the parameters and a copy (choose either Uniform or Latin Hyper Cube) 

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

def scm_model(X, case, return_z_r = False, velocities=False):
    # ====================================Run the SCM cases=======================================
    params = default_params.copy()  # Create a copy of default_params
    params.update(case_params[case])  # Update with the specific case hyperparameters in case_params[case]

    # unpack X values in the form of a dictionary. 
    params_to_estimate = { variables[i][0]: X[i] for i in range(len(variables))} 
    params_to_estimate['vp_c'] = params_to_estimate['up_c']
    params.update(params_to_estimate) # Update with the parameters to estimate

    scm = SCM(**params)
    scm.run_direct()            # Run the SCM 
    if return_z_r:
        if velocities:
            return scm.t_history, scm.u_history,scm.v_history, scm.z_r
        else:
            return scm.t_history, scm.z_r
    else:
        if velocities:
            return [scm.t_history, scm.u_history, scm.v_history]
        else:
            return scm.t_history
    


#============================ MAIN LOOP =========================================

# initialize output
output={'variables_range': variables, 'X_samples': X_samples,'X_prime_samples':X_prime_samples, 'X_tilde': {}}


for key in P['1th']:
    projector=P['1th'][key]
    #compute Y_tilde = f(X_tilde)
    # X_tilde = [0]*N, np.zeros((N,nvar))
    # print(key)
    output['X_tilde'][key] = [0]*N
    for i in range(0,N):
        output['X_tilde'][key][i] = projector * X_samples [:,i] + (1-projector) * X_prime_samples [:,i]


for case in cases:
    #======================== temperature only analysis
    print('Drawing samples of the case '+case)
    ### Compute Y = f(X)    
    Y = [0]*N
    Y_prime = [0]*N


    # Do a first evaluation to get z_r
    a,b,c, z_r = scm_model(X_samples[:,0], case, return_z_r=True,velocities=True)

    # wrap scm_model
    def scm_model_wrapped(X):
        return scm_model(X,case,return_z_r=False,velocities=True)

    # parrallel evaluation of the model
    print('Computing Y...')
    if __name__ == '__main__':
        with Pool() as p:
            Y = p.map(scm_model_wrapped, X_samples.T)

    # parrallel evaluation of the model
    print('Computing Y prime...')
    if __name__ == '__main__':
        with Pool() as p:
            Y_prime = p.map(scm_model_wrapped, X_prime_samples.T)


    Y, Y_prime = np.array(Y), np.array(Y_prime)
    output[case] = {'variables': {
                                'temp':{'Y': Y[:,0,:,:],
                                        'Y_prime': Y_prime[:,0,:,:],
                                        'Y_tilde':{} },
                                        
                                'u':{'Y': Y[:,1,:,:],
                                     'Y_prime': Y_prime[:,1,:,:],
                                     'Y_tilde':{} }, 
                                     
                                'v':{'Y': Y[:,2,:,:],
                                     'Y_prime': Y_prime[:,2,:,:],
                                     'Y_tilde':{} },
                                            },
                    'coordinates': {'z_r': z_r, 'time':time}}

    for key in P['1th']:
        print('Computing Y tilde for '+key+' fixed...')
        if __name__ == '__main__':
            with Pool() as p:
                Y_tilde = p.map(scm_model_wrapped, output['X_tilde'][key])
        Y_tilde = np.array(Y_tilde)
        for k,var in enumerate(output[case]['variables']):
            output[case]['variables'][var]['Y_tilde'][key] = Y_tilde[:,k,:,:] 

#==========================
# Save output
print('Saving')
with open('outputs/'+saving_name, 'wb') as handle:
    pickle.dump(output, handle, protocol=pickle.HIGHEST_PROTOCOL)
print('Done! Output saved at '+'outputs/'+saving_name)
stop = TIME.time()
print('duration of execution', stop-start)



output[case]['variables']
















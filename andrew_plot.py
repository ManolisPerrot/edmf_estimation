import numpy as np
import arviz as az
import matplotlib.pyplot as plt
# from likelihood_mesonh import likelihood_mesonh
import sys  # to put the SCM into the PYTHONPATH
sys.path.append('edmf_ocean/library/F2PY')
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
from test_version_edmf_ocean import check_edmf_ocean_version
check_edmf_ocean_version()
# from interpolate_LES_on_SCM_grids import regrid_and_save
from concurrent.futures import ProcessPoolExecutor
import concurrent.futures

## Load the data
data = az.from_netcdf('MCMC_output/MAP_error_run.nc')

## convert to xarray dataset
ds = az.convert_to_dataset(data)

slicer = ds['likelihood'][0] > 0.1 * ds['likelihood'][0].max() 
ds['likelihood'][0][slicer]
ds_sliced = { key: ds[key][0, slicer] for key in ds.data_vars.keys() }

nsubsample = len(ds_sliced['likelihood'])
number_of_draws = 10
subsample_indices = np.random.choice(nsubsample, number_of_draws, replace=False)
ds_subsampled = {key: ds_sliced[key][subsample_indices] for key in ds_sliced.keys()}

# ds_sliced['likelihood'][subsample_indices]
ds_subsampled

def run_scm(params_to_estimate,case,draw):
    # ====================================Run the SCM cases=======================================
    params = default_params.copy()  # Create a copy of default_params
    params.update(case_params[case])  # Update with the specific case hyperparameters in case_params[case]
    params.update(params_to_estimate) # Update with the parameters to estimate 
    params.update( {'output_filename': 'plotting_outputs/'+case+str(draw)+'.nc','write_netcdf': True})
    # print('Running SCM with the following parameters:', params)
    # print('run')
    scm = SCM(**params)
    scm.run_direct()            # Run the SCM

### Rerun the SCM on the subsampled points, 100 draws --> ~7mn   
cases = ['FC500','W005_C500_NO_COR']

from concurrent.futures import ProcessPoolExecutor, as_completed

def run_simulation(draw, ds_subsampled, case):
    # Prepare the parameters for the current draw
    params_to_estimate = {
        key: ds_subsampled[key][draw] 
        for key in ds_subsampled.keys() 
        if key not in {'likelihood', 'log_likelihood', 'log_wp_0'}
    }
    params_to_estimate['wp0'] = params_to_estimate.pop('wp_0')  # Rename key

    # Run the simulation
    run_scm(params_to_estimate=params_to_estimate, case=case, draw=draw)
    return draw  # Return draw number to confirm completion

def main(number_of_draws, ds_subsampled, case):
    # Use ProcessPoolExecutor to parallelize the loop
    with ProcessPoolExecutor() as executor:
        # Submit each draw as a separate task
        futures = {
            executor.submit(run_simulation, draw, ds_subsampled, case): draw 
            for draw in range(number_of_draws)
        }
        
        # Wait for all tasks to complete and print the results
        for future in as_completed(futures):
            draw = futures[future]
            try:
                result = future.result()  # Raise any exceptions encountered in the task
                print(f"Completed simulation for draw {result}")
            except Exception as e:
                print(f"Error in simulation for draw {draw}: {e}")


# 
re_run = False
if re_run == True:
    for case in cases:
        main(number_of_draws, ds_subsampled, case)

# ====================================Plot the SCM outputs=======================================
cases = ['FC500','W005_C500_NO_COR']

profiles = {}
for case in cases:
    profiles[case] = [None]*number_of_draws
    for draw in range(number_of_draws):
        profiles[case][draw] = xr.open_dataset('plotting_outputs/'+case+str(draw)+'.nc')

mean_temp = 1/number_of_draws* sum(profiles['FC500'][i]['temp'] for i in range(number_of_draws))
var_temp  = 1/number_of_draws* sum((profiles['FC500'][i]['temp']-mean_temp)**2 for i in range(number_of_draws)) 

plt.plot(mean_temp[-1], profiles['FC500'][0]['z_r'], label='mean')
plt.plot(mean_temp[-1] + np.sqrt(var_temp [-1]), profiles['FC500'][0]['z_r'], label='mean')
plt.plot(mean_temp[-1] - np.sqrt(var_temp [-1]), profiles['FC500'][0]['z_r'], label='mean')
plt.show()
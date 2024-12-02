###########################################
# Imports
###########################################
import sys #to put the SCM into the PYTHONPATH
sys.path.append('../../../../edmf_ocean/library/F2PY/')
sys.path.append('../../../../')
from scm_class import SCM
from case_configs import case_params, default_params
from concurrent.futures import ProcessPoolExecutor

import time as TIME
start = TIME.time() #monitor duration of execution 

debug=False
if debug:
    # Interactive testing: Set default values for `waven` and `cas`
    waven = "1"
    cas = "FC500"
else:
    # If running as a script, capture arguments
    #----- Input arguments
    waven = sys.argv[2]  # First argument   
    cas = sys.argv[1]    # Second argument  

print("WAVEN:", waven)
print("cas:", cas)
###########################################
# Initialize an empty dictionary
data = {}
dir = f'../../WORK/BENCHSCMOCEAN/WAVE{waven}/'
param_file =f'Par1D_Wave{waven}.asc'
# Initialize an empty dictionary
data_dict = {}

# Open the file and read lines
with open(dir+param_file, "r") as file:
    # Read the first line (header) and strip quotes
    header_line = file.readline().strip()
    headers = [header.strip('"') for header in header_line.split()]
    
    # Store the headers as the first entry in the dictionary
    data_dict["t_IDs"] = headers[1:]  # Skip the first header entry, "t_IDs"
    
    # Read the remaining lines for data entries
    for line in file:
        # Split line into identifier and data values
        parts = line.strip().split()
        key = parts[0].strip('"')  # First item is the identifier, without quotes
        values = [float(value) for value in parts[1:]]  # Convert remaining values to floats
        
        # Add to dictionary
        data_dict[key] = values


#--------------------------------------------

def scm_model(X, case, run_id):
    # ====================================Run the SCM cases=======================================
    params = default_params.copy()  # Create a copy of default_params
    params.update(case_params[case])  # Update with the specific case hyperparameters in case_params[case]
    params.update({'write_netcdf': True,'output_filename': dir+f'{case}/'+run_id+'.nc'})  
    # unpack X values in the form of a dictionary. 
    params_to_estimate = { key: X[i] for i, key in enumerate(data_dict["t_IDs"])} 
    params_to_estimate['vp_c'] = params_to_estimate['up_c']
    params.update(params_to_estimate) # Update with the parameters to estimate

    scm = SCM(**params)
    scm.run_direct()            # Run the SCM 
case = cas
# Define the task for each run
def run_scm_model(run_id):
    if run_id != 't_IDs':
        print(f"Running {case} for {run_id}")
        scm_model(X=data_dict[run_id], case=case, run_id=run_id)

# Run in parallel
with ProcessPoolExecutor() as executor:
    # Submit all tasks to the executor
    executor.map(run_scm_model, data_dict.keys())

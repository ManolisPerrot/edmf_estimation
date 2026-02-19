#!/usr/bin/env python  
"""  
K-epsilon model calibration using multiple LES cases from oMLDb  
"""  
  
import numpy as np  
import matplotlib.pyplot as plt  
from scipy.io import netcdf_file  
import yaml  
import glob, os, re  
import subprocess  
import sys  
from pathlib import Path  
import shutil  
from multiprocess import Pool #multiprocessING cannot handle locally defined functions, multiprocess can
import csv

  
# # Import oMLDb  
# import omldb  
  
plt.ion()  

waven   = sys.argv[1]  # First argument   
metrics_names = sys.argv[2:]  # Other arguments=metrics name with the format case-ids_metric-type
case_ids = [arg.split('_')[0] for arg in metrics_names] #extract case_ids on which to run GOTM

# #testing
# metrics_names=['perfect_mld4h']
# waven=1

# Constants  
g = 9.81  
rho = 1026.0  
alphaT = 2e-4  
betaS = 8e-4  
  
# Time step range for averaging  
nt1 = 96  # final time step for plots  
nt0 = nt1 - 12  # range of time for averaging in hr  

#tttest
case_ids = ['test']
test_value = -100.
mynan = -1e6

# Functions from Garanaik et al  
def density_eos(t, s):  
    """Density calculation from given temp and salinity"""  
    density = rho * (1.0 - alphaT * (t - 20) + betaS * (s - 35))  
    return density  
  
  
def bld(t, s, z):  
    """OSBL depth corresponding to max N2"""  
    density = density_eos(t, s)  
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
  




  
def get_gotm_config_for_case(case_id):  
    """  
    Get the GOTM configuration file path for a given LES case  
      
    Parameters  
    ----------  
    case_id : str  
        Case ID from oMLDb  
          
    Returns  
    -------  
    Path  
        Path to the GOTM yaml configuration file  
    """  
    if case_id=='test':
        case_path = Path('GOTM/cases/garanaik/')

    else:# Get case metadata  
        metadata = omldb.load_case_metadata(case_id)  
        case_path = omldb.get_case_path(case_id)   
      
    # Look for GOTM yaml file in the case directory  
    # Assuming it's named gotm.yaml or gotm_{case_id}.yaml  
    yaml_files = list(case_path.glob("gotm_v7.yaml"))  
      
    if not yaml_files:  
        raise FileNotFoundError(f"No GOTM yaml file found for case {case_id} in {case_path}")  
      
    return yaml_files[0]  
  
  
def modif_config_file(in_file, out_file, new_params):  
    """Modify configuration file with new sets of parameters"""  
    with open(in_file, "r") as sources:  
        lines = sources.readlines()  
      
    with open(out_file, "w") as sources:  
        for line in lines:  
            for key, value in new_params.items():  
                pattern = rf'^(\s*{re.escape(key)}\s*:\s*).*$'  
                line = re.sub(pattern, r'\g<1>' + str(value), line)  
            sources.write(line)  
  
  
def run_gotm(config, run_dir):  
    """  
    Run GOTM simulation in a specific directory  
      
    Parameters  
    ----------  
    config : str or Path  
        Path to GOTM configuration file  
    run_dir : str or Path  
        Directory to run GOTM in  
    """  
    # run_dir = Path(run_dir)  
    # run_dir.mkdir(parents=True, exist_ok=True)  
      
    # # Copy config to run directory  
    # config_copy = run_dir / Path(config).name  
    # shutil.copy(config, config_copy)  

    # Create log files  
    stdout_log = run_dir / "gotm_stdout.log"  
    stderr_log = run_dir / "gotm_stderr.log"  
    command = ["gotm", config]  
      
    try:  
        with open(stdout_log, "w") as fout, open(stderr_log, "w") as ferr:  
            subprocess.run(  
                command,   
                check=True,   
                stdout=fout,  
                stderr=ferr,  
                cwd=str(run_dir)  
            )  
    except subprocess.CalledProcessError as e:  
        print(f"An error occurred while running gotm: {e}", file=sys.stderr)  
        print(f"Check logs in {run_dir}:")  
        print(f"  - {stdout_log}")  
        print(f"  - {stderr_log}")  
  
  
def write_it_number(it):  
    """Write iteration number to file"""  
    with open("it_file.dat", "w") as it_file:  
        it_file.write(f'{it}')  
  
  
def read_it_number():  
    """Read iteration number from file"""  
    if not Path("it_file.dat").exists():  
        return 0  
    with open("it_file.dat", "r") as it_file:  
        it = int(it_file.read())  
    return it  
  
  
def write_iteration(params, res):  
    """Callback function to write iteration info"""  
    it = read_it_number()  
    print('--------------------------')  
    print(f'----iteration {it} ------')  
    print('--------------------------')  
    it += 1  
    write_it_number(it)  
  
  
def simulation_wrapper(params, case_configs, param_list, runs_dir, keep_every=None):  
    """  
    Run GOTM simulation for each LES case and compute metric 
      
    Parameters  
    ----------  
    params : array-like  
        Parameter values to test  
    case_configs : dict  
        Dictionary mapping case_id to original GOTM config file path  
    param_list : list of str  
        List of parameter names  
    runs_dir : str or Path  
        Base directory for GOTM runs  
          
    Returns  
    -------  
    dict  
    """  
    params = np.asarray(params)  
    runs_dir = Path(runs_dir)  
    runs_dir.mkdir(parents=True, exist_ok=True)  
      
    # Create parameter dictionary  
    new_params = {}  
    for idx, p in enumerate(params):  
        new_params[param_list[idx]] = p  
      
    # # Get iteration number for organizing runs  
    # it = read_it_number()  

    # # Create run directory for this iteration  
    # iter_dir = runs_dir / f"iter_{it:04d}"  
      
    # Run GOTM for each case  
    errors = []  
    gotm_blds = {}  
      
    for case_id in case_ids :  
        print(f"\n  Running GOTM for {case_id}...")  
          
        # Create run directory for this case and iteration  
        case_run_dir = runs_dir / case_id  
        case_run_dir.mkdir(parents=True, exist_ok=True)  
          
        # Get original config for this case  
        original_config = case_configs[case_id]  
          
        # Create modified config  
        modified_config = case_run_dir / "gotm_modified.yaml"  
        modif_config_file(original_config, modified_config, new_params)  

        # Run GOTM  
        try:  
            run_gotm("gotm_modified.yaml" , case_run_dir)  
        except Exception as e:  
            print(f"  Error running GOTM for {case_id}: {e}")  
            # Assign large penalty for failed runs  
            errors.append(mynan)  
            gotm_blds[case_id] = mynan 
            continue  
          
        # Read GOTM output  
        with open(modified_config) as f:  
            config = yaml.safe_load(f)  
          
        output_file = list(config['output'].keys())[0] + '.nc'  
        output_path = case_run_dir / output_file  
          
        if not output_path.exists():  
            print(f"  Warning: Output file not found for {case_id}")  
            errors.append(mynan)  
            gotm_blds[case_id] = mynan 
            continue  
          
        # Read variables  
        try:  
            f = netcdf_file(str(output_path), 'r')  
            z = f.variables['z'][0, :, 0, 0].copy().squeeze()  
            temp = f.variables['temp'][:, :, 0, 0].copy()  
            salt = f.variables['salt'][:, :, 0, 0].copy()  
            f.close()  
              
            # Compute BLD from GOTM  
            h_gotm = bld(temp[nt0:nt1], salt[nt0:nt1], z)  
            if np.isnan(h_gotm):
                h_gotm = mynan
            gotm_blds[case_id] = h_gotm  
              
            # # Compute relative error for this case  
            # rel_error = ((h_gotm - h_les) / h_les) ** 2  
            # errors.append(rel_error)  
              
            # print(f"    LES BLD: {h_les:.2f} m, GOTM BLD: {h_gotm:.2f} m, Error: {rel_error:.6e}")  

            print(f"GOTM BLD: {h_gotm:.2f} m")              
        except Exception as e:  
            print(f"  Error reading output for {case_id}: {e}")  
            errors.append(mynan)  
            gotm_blds[case_id] = mynan
            continue  
      
    # Log results  
    with open("optim.log", "a") as log_file:  
        log_file.write(f'Params: {dict(zip(param_list, params))}\n')  
        for case_id in case_ids:  
            h_gotm = gotm_blds.get(case_id, np.nan)  
            log_file.write(f'  {case_id}: , GOTM={h_gotm:.2f}\n')   
    return gotm_blds
  
###############  
# Main script  
###############  
  
#if __name__ == "__main__":  
      
# Configuration  
runs_dir = Path(f'WAVE{waven}/runs')  
runs_dir.mkdir(parents=True, exist_ok=True)  
  

# 
# TODO in a separate compute_les_metrics.py # Step 1: Compute LES metrics from oMLDb  
# print("="*60)  
# print("Step 1: Computing LES metrics")  
# print("="*60)  
  
# Option A: Use specific cases  
# case_ids = [  
#     'LES_IDEAL_GARANAIK2023_C01',  # cooling  
#     'LES_IDEAL_GARANAIK2023_C02',  # stratification  
#     'LES_IDEAL_GARANAIK2023_C04',  # stratification  
#     # Add more cases as needed  
# ]  
  
# Option B: Use all available LES cases (uncomment to use)  
# case_ids = None  
  
# Option C: Use "obs" metrics from GOTM outputs with given parameters (perfect model test)

case_ids = ['test']

# les_metrics = compute_les_metrics(case_ids=case_ids)  
  
# print("\nLES Metrics:")  
# for case_id, bld_val in les_metrics.items():  
#     print(f"  {case_id}: BLD = {bld_val:.2f} m")  
  
# Step 2: Get GOTM config files for each case  
print("\n" + "="*60)  
print("Step 2: Loading GOTM configurations")  
print("="*60)  
  
case_configs = {}  
for case_id in case_ids:  
    # try:  
    config_path = get_gotm_config_for_case(case_id)  
    case_configs[case_id] = config_path  
    print(f"  {case_id}: {config_path}")  
    # except FileNotFoundError as e:  
    #     print(f"  Warning: {e}")  
    #     # Remove case from metrics if no config found  
    #     del les_metrics[case_id]  
  
if not case_configs:  
    raise ValueError("No GOTM configuration files found for any cases")  
  
# Step 3: Define parameters to calibrate  
print("\n" + "="*60)  
print("Step 3: Setting up calibration parameters")  
print("="*60)  


#--------------------------------------------
# TODO: wrap this into a function
# read parameters ascii file and return a dictionnary {params_id: params_list}
param_file =f'Par1D_Wave{waven}.asc'
# Initialize an empty dictionary
param_dict = {}
# Open the file and read lines
with open(param_file, "r") as file:
    # Read the first line (header) and strip quotes
    header_line = file.readline().strip()
    headers = [header.strip('"') for header in header_line.split()]
    
    # Store the headers as the first entry in the dictionary
    param_dict["t_IDs"] = headers[1:]  # Skip the first header entry, "t_IDs"
    
    # Read the remaining lines for data entries
    for line in file:
        # Split line into identifier and data values
        parts = line.strip().split()
        key = parts[0].strip('"')  # First item is the identifier, without quotes
        values = [float(value) for value in parts[1:]]  # Convert remaining values to floats
        
        # Add to dictionary
        param_dict[key] = values


# run cases in parrallel
metrics={}

# Define the task to parallelize for each run
def task(run_id):
    return simulation_wrapper(param_dict[run_id], case_configs, param_dict["t_IDs"], runs_dir/run_id)


L = list(param_dict.keys())[1:]

# run in parallel
with Pool() as p:
    out = p.map(task, list(param_dict.keys())[1:])
    # out = out[1:] #remove 't_IDs' from the list
    #     # metrics_all.update(out)

metrics['perfect'+'_mld4h'] = [o['test'] for o in out]

run_id = list(param_dict.keys())[1:]
output_file = "Metrics.csv"
with open(output_file, mode="w", newline="") as file:
    writer = csv.writer(file, quoting=csv.QUOTE_NONE, escapechar=' ')  # No quotes
    writer.writerow(["SIM"] + metrics_names)  # Write header row

    vals_inline = [metrics[key] for key in metrics]  

    for i in range(len(run_id)):
        row = [run_id[i]] + [float(vals_inline[k][i]) for k in range(len(vals_inline))]  # Exclude repeated run_id
        writer.writerow(row)

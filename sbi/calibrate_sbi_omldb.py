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
  
import torch  
from sbi import analysis as analysis  
from sbi import utils as utils  
from sbi.inference import NPE, simulate_for_sbi  
from sbi.utils.user_input_checks import (  
    check_sbi_inputs,  
    process_prior,  
    process_simulator,  
)  
  
# Import oMLDb  
import omldb  
  
plt.ion()  
  
# Constants  
g = 9.81  
rho = 1026.0  
alphaT = 2e-4  
betaS = 8e-4  
  
# Time step range for averaging  
nt1 = 96  # final time step for plots  
nt0 = nt1 - 12  # range of time for averaging in hr  
  
  
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
  
  
def compute_les_metrics(case_ids=None):  
    """  
    Compute BLD metrics from LES cases in oMLDb  
      
    Parameters  
    ----------  
    case_ids : list of str, optional  
        List of case IDs to use. If None, uses all available cases.  
          
    Returns  
    -------  
    dict  
        Dictionary mapping case_id to BLD value  
    """  
    print("Computing LES metrics from oMLDb...")  
      
    # Load catalog  
    catalog = omldb.load_catalog()  
      
    # Filter for LES cases  
    les_catalog = catalog[catalog['data_type'] == 'LES']  
      
    if case_ids is None:  
        # Use all available LES cases  
        case_ids = les_catalog['case_id'].tolist()  
    else:  
        # Validate requested cases exist  
        available = set(les_catalog['case_id'])  
        case_ids = [cid for cid in case_ids if cid in available]  
        if not case_ids:  
            raise ValueError("None of the requested case_ids found in database")  
      
    print(f"Processing {len(case_ids)} LES cases...")  
      
    metrics = {}  
    for case_id in case_ids:  
        try:  
            print(f"  Loading {case_id}...")  
            ds = omldb.load_case(case_id)  
              
            # Extract variables (adjust variable names based on your data)  
            z = ds['z'].values
            temp = ds['temp'].values
            salt = ds['salt'].values
              
            # Compute BLD for this case  
            bld_val = bld(temp[nt0:nt1], salt[nt0:nt1], z)  
            metrics[case_id] = bld_val  
              
            print(f"    BLD = {bld_val:.2f} m")  
              
        except Exception as e:  
            print(f"  Warning: Could not process {case_id}: {e}")  
            continue  
      
    if not metrics:  
        raise ValueError("No LES cases could be processed successfully")  
      
    print(f"\nSuccessfully computed metrics for {len(metrics)} cases")  
    return metrics  
  
  
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
    # Get case metadata  
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
  
  
def simulation_wrapper(params, les_metrics, case_configs, param_list, runs_dir='../runs', keep_every=None):  
    """  
    Run GOTM simulation for each LES case and compute cost function  
      
    Parameters  
    ----------  
    params : array-like  
        Parameter values to test  
    les_metrics : dict  
        Dictionary of LES BLD values for each case  
    case_configs : dict  
        Dictionary mapping case_id to original GOTM config file path  
    param_list : list of str  
        List of parameter names  
    runs_dir : str or Path  
        Base directory for GOTM runs  
          
    Returns  
    -------  
    torch.Tensor  
        Cost function value (mean squared relative error across all cases)  
    """  
    params = np.asarray(params)  
    runs_dir = Path(runs_dir)  
    runs_dir.mkdir(parents=True, exist_ok=True)  
      
    # Create parameter dictionary  
    new_params = {}  
    for idx, p in enumerate(params):  
        new_params[param_list[idx]] = p  
      
    # Get iteration number for organizing runs  
    it = read_it_number()  

    # Create run directory for this iteration  
    iter_dir = runs_dir / f"iter_{it:04d}"  
      
    # Run GOTM for each case  
    errors = []  
    gotm_blds = {}  
      
    for case_id, h_les in les_metrics.items():  
        print(f"\n  Running GOTM for {case_id}...")  
          
        # Create run directory for this case and iteration  
        case_run_dir = iter_dir / case_id  
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
            errors.append(1e6)  
            gotm_blds[case_id] = np.nan  
            continue  
          
        # Read GOTM output  
        with open(modified_config) as f:  
            config = yaml.safe_load(f)  
          
        output_file = list(config['output'].keys())[0] + '.nc'  
        output_path = case_run_dir / output_file  
          
        if not output_path.exists():  
            print(f"  Warning: Output file not found for {case_id}")  
            errors.append(1e6)  
            gotm_blds[case_id] = np.nan  
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
            gotm_blds[case_id] = h_gotm  
              
            # Compute relative error for this case  
            rel_error = ((h_gotm - h_les) / h_les) ** 2  
            errors.append(rel_error)  
              
            print(f"    LES BLD: {h_les:.2f} m, GOTM BLD: {h_gotm:.2f} m, Error: {rel_error:.6e}")  
              
        except Exception as e:  
            print(f"  Error reading output for {case_id}: {e}")  
            errors.append(1e6)  
            gotm_blds[case_id] = np.nan  
            continue  
      
    # Compute mean cost function across all cases  
    J = errors
      
    # Log results  
    with open("optim.log", "a") as log_file:  
        log_file.write(f'\nIteration {it}\n')  
        log_file.write(f'Params: {dict(zip(param_list, params))}\n')  
        for case_id in les_metrics.keys():  
            h_les = les_metrics[case_id]  
            h_gotm = gotm_blds.get(case_id, np.nan)  
            log_file.write(f'  {case_id}: LES={h_les:.2f}, GOTM={h_gotm:.2f}\n')  
        log_file.write(f'Cost function J = {J}\n')  
      
    print(f'\n  Overall cost function: {np.nanmean(J):.6e}')  
      
    # Clean up old iterations (keep every Nth iteration)  
    if keep_every is not None and it > 0:  
        if it % keep_every != 0:  
            # Remove this iteration directory after we're done  
            print(f"  Cleaning up iteration {it} (keeping every {keep_every})")  
            try:  
                shutil.rmtree(iter_dir)  
            except Exception as e:  
                print(f"  Warning: Could not remove {iter_dir}: {e}")  
      


    # Increment iteration counter  
    write_it_number(it + 1)  
      
    return torch.as_tensor(J)  
  
  
###############  
# Main script  
###############  
  
#if __name__ == "__main__":  
      
# Configuration  
runs_dir = Path('../runs')  
runs_dir.mkdir(parents=True, exist_ok=True)  
  
# Step 1: Compute LES metrics from oMLDb  
print("="*60)  
print("Step 1: Computing LES metrics")  
print("="*60)  
  
# Option A: Use specific cases  
case_ids = [  
    'LES_IDEAL_GARANAIK2023_C01',  # cooling  
    'LES_IDEAL_GARANAIK2023_C02',  # stratification  
    'LES_IDEAL_GARANAIK2023_C04',  # stratification  
    # Add more cases as needed  
]  
  
# Option B: Use all available LES cases (uncomment to use)  
# case_ids = None  
  
les_metrics = compute_les_metrics(case_ids=case_ids)  
  
print("\nLES Metrics:")  
for case_id, bld_val in les_metrics.items():  
    print(f"  {case_id}: BLD = {bld_val:.2f} m")  
  
# Step 2: Get GOTM config files for each case  
print("\n" + "="*60)  
print("Step 2: Loading GOTM configurations")  
print("="*60)  
  
case_configs = {}  
for case_id in les_metrics.keys():  
    try:  
        config_path = get_gotm_config_for_case(case_id)  
        case_configs[case_id] = config_path  
        print(f"  {case_id}: {config_path}")  
    except FileNotFoundError as e:  
        print(f"  Warning: {e}")  
        # Remove case from metrics if no config found  
        del les_metrics[case_id]  
  
if not case_configs:  
    raise ValueError("No GOTM configuration files found for any cases")  
  
# Step 3: Define parameters to calibrate  
print("\n" + "="*60)  
print("Step 3: Setting up calibration parameters")  
print("="*60)  

# cc1CHCD01A  =  5.0000
# cc2CHCD01A  =  0.8000
# cc3CHCD01A  =  1.9680
# cc4CHCD01A  =  1.1360
# cc5CHCD01A  =  0.0000
# cc6CHCD01A  =  0.4000
# ct1CHCD01A  =  5.9500
# ct2CHCD01A  =  0.6000
# ct3CHCD01A  =  1.0000
# ct4CHCD01A  =  0.0000
# ct5CHCD01A  =  0.3333
# cttCHCD01A  =  0.7200



# param_canutoA = np.array([5.0000, 0.8000, 1.9680, 1.1360, 0.0000, 0.4000, 5.9500, 0.6000, 1.0000, 0.0000, 0.3333, 0.7200])

# param_list = ["cc1", "cc2", "cc3", "cc4", "cc5", "cc6", "ct1", "ct2", "ct3", "ct4", "ct5", "ctt"]  
# param_guess = 1.*param_canutoA
# prior_min = 0.5*param_canutoA
# prior_max = 2*param_canutoA



param_canutoA = np.array([5.0000, 0.8000, 1.9680, 1.1360, 0.4000, 5.9500, 0.6000, 1.0000, 0.3333, 0.7200])
param_list = ["cc1", "cc2", "cc3", "cc4", "cc6", "ct1", "ct2", "ct3", "ct5", "ctt"]  
N_param = 3
param_canutoA = param_canutoA[:N_param]
param_list = param_list[:N_param]

param_guess = 1.*param_canutoA
prior_min = 0.5*param_canutoA
prior_max = 4*param_canutoA


print(f"Parameters to calibrate: {param_list}")  
print(f"Initial guess: {dict(zip(param_list, param_guess))}")  
print(f"Prior bounds: {dict(zip(param_list, zip(prior_min, prior_max)))}")  
  
# Initialize optimization log  
with open("optim.log", "w") as log_file:  
    log_file.write(f'# K-epsilon calibration using {len(les_metrics)} LES cases\n')  
    log_file.write(f'# Cases: {", ".join(les_metrics.keys())}\n')  
    log_file.write(f'# Parameters: {", ".join(param_list)}\n')  
    log_file.write(f'# Prior bounds: {dict(zip(param_list, zip(prior_min, prior_max)))}\n')  
    log_file.write(f'#\n')  
  
write_it_number(0)  
  
# Test initial guess  
print("\n" + "="*60)  
print("Step 4: Testing initial parameter guess")  
print("="*60)  
  
J_init = simulation_wrapper(param_guess, les_metrics, case_configs, param_list, runs_dir)  
print(f"\nInitial cost function: {J_init}")  
  
# Step 5: Set up SBI  
print("\n" + "="*60)  
print("Step 5: Setting up Simulation-Based Inference")  
print("="*60)  
  
prior = utils.torchutils.BoxUniform(  
    low=torch.as_tensor(prior_min),   
    high=torch.as_tensor(prior_max)  
)  

keep_every = 5 #- keeps all iterations
#keep_every = None #- keeps all iterations

# Create wrapper that includes les_metrics and case_configs  
def sim_wrapper_sbi(params):  
    return simulation_wrapper(params, les_metrics, case_configs, param_list, runs_dir, keep_every=keep_every)  
  
# Check prior, simulator, consistency  
prior, num_parameters, prior_returns_numpy = process_prior(prior)  
sim_wrapper_sbi = process_simulator(sim_wrapper_sbi, prior, prior_returns_numpy)  
#check_sbi_inputs(sim_wrapper_sbi, prior)  
  
# Step 6: Generate simulations  
print("\n" + "="*60)  
print("Step 6: Generating simulations for inference")  
print("="*60)  
  
num_simulations = 1000 
print(f"Running {num_simulations} simulations...")  
print(f"Total GOTM runs: {num_simulations * len(les_metrics)}")  
  
theta, x = simulate_for_sbi(  
    sim_wrapper_sbi,   
    proposal=prior,   
    num_simulations=num_simulations,   
    num_workers=1 
)  
  
# Step 7: Train density estimator  
print("\n" + "="*60)  
print("Step 7: Training density estimator")  
print("="*60)  
  
inference = NPE(prior=prior)  
inference = inference.append_simulations(theta, x)  
density_estimator = inference.train()  
posterior = inference.build_posterior(density_estimator)  
  
# Step 8: Sample posterior  
print("\n" + "="*60)  
print("Step 8: Sampling posterior distribution")  
print("="*60)  
  
# Use small cost function value as observation  
#x_obs = torch.as_tensor([1e-8, 1e-8])  
x_obs = 0*J_init + 1e-8
samples = posterior.sample((10_000_000,), x=x_obs)  
  
# Step 9: Visualize results  
print("\n" + "="*60)  
print("Step 9: Generating results")  
print("="*60)  

# True/reference parameters (from standard k-epsilon)  
true_params = 1.0*param_canutoA
  
fig, axes = analysis.pairplot(  
    samples,  
    limits=(np.array([prior_min, prior_max]).T).tolist(),  
    figsize=(5, 5),  
    points=true_params,  
    labels=param_list,  
)  
  
plt.savefig('posterior_pairplot.png', dpi=150, bbox_inches='tight')  
print("Saved posterior plot to: posterior_pairplot.png")  
  
# Print summary statistics  
print("\nPosterior Summary:")  
for i, param_name in enumerate(param_list):  
    mean = samples[:, i].mean().item()  
    std = samples[:, i].std().item()  
    median = samples[:, i].median().item()  
    print(f"  {param_name}:")  
    print(f"    Mean:   {mean:.3f}")  
    print(f"    Median: {median:.3f}")  
    print(f"    Std:    {std:.3f}")  


# Step 10: Evaluate optimal parameters  
print("\n" + "="*60)  
print("Step 10: Evaluating optimal parameters")  
print("="*60)  
  
# Get mean of posterior as optimal parameters  
optimal_params = samples.mean(dim=0).numpy()  
  
print("\nOptimal parameters (posterior mean):")  
for i, param_name in enumerate(param_list):  
    print(f"  {param_name}: {optimal_params[i]:.4f}")  
  
# Run simulation with optimal parameters  
print("\nRunning GOTM with optimal parameters...")  
J_optimal = simulation_wrapper(  
    optimal_params,   
    les_metrics,   
    case_configs,   
    param_list,   
    runs_dir
)  
  
print(f"\nOptimal cost function: {J_optimal}")  
print(f"Initial cost function: {J_init}")  
  
# Compare with initial guess and true parameters  
print("\nParameter comparison:")  
print(f"{'Parameter':<15} {'Initial':<12} {'Optimal':<12} {'Reference':<12}")  
print("-" * 51)  
for i, param_name in enumerate(param_list):  
    print(f"{param_name:<15} {param_guess[i]:<12.4f} {optimal_params[i]:<12.4f} {true_params[i]:<12.4f}")  


print("\n" + "="*60)  
print("Calibration complete!")  
print("="*60)  
print(f"Results saved to:")  
print(f"  - optim.log (detailed log)")  
print(f"  - posterior_pairplot.png (visualization)")  
print(f"  - {runs_dir}/ (all GOTM runs)")  


# for i in range(0,100):
#   ccc1_1 = 5
#   ccc1_2 = 10
#   x = i*1./99
#   optimal_params[0] = ccc1_1*(1-x) + ccc1_2*x

#   print(f'c1 = {optimal_params[0]}')
#   J_optimal = simulation_wrapper(optimal_params,les_metrics,case_configs,param_list,runs_dir)

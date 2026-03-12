import numpy as np  
import matplotlib.pyplot as plt  
from scipy.io import netcdf_file  
import yaml  
import glob, os, re  
import subprocess  
import sys  
from pathlib import Path  
import shutil  
import csv

  

  
# # Import oMLDb  
import omldb  
  
plt.ion()  

# waven   = sys.argv[1]  # First argument   
metrics_names = sys.argv[1:-1]  # Arguments= list of metrics name with the format case-ids_metric-type
tolerance = sys.argv[-1]
# case_ids = [arg.split('_')[0] for arg in metrics_names] #extract case_ids on which to run GOTM

# Constants  
#TODO : read constants from toml/yml file!
g = 9.81  
rho = 1026.0  
alphaT = 2e-4  
betaS = 8e-4  


# Functions from Garanaik et al  
def density_eos(t, s):  
    """Density calculation from given temp and salinity"""  
    density = rho * (1.0 - alphaT * (t - 20) + betaS * (s - 35))  
    return density  
  
  
def bld_averaged(t, s, z):  
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

def mld4h(ds):
    hours = 4
    # last time
    last_time = ds.time.max().values
    # target time
    target = last_time - np.timedelta64(hours, "h")
    # index of closest time
    idx = abs(ds.time.values - target).argmin()
    # corresponding time
    closest_time = ds.time.values[idx]
    # actual offset in hours
    actual_hours = (last_time - closest_time) / np.timedelta64(1, "h")
    print(f"Requested average: {hours} h")
    print(f"Due to dataset structure, average is performed in pratice on: {actual_hours:.3f} h")
    # Extract variables from the dataset  
    z = ds['z'].values
    temp = ds['temp'].values
    salt = ds['salt'].values

    # Compute metric 
    return bld_averaged(temp[idx:-1], salt[idx:-1], z)  


def mld12h(ds):
    hours = 12
    # last time
    last_time = ds.time.max().values
    # target time
    target = last_time - np.timedelta64(hours, "h")
    # index of closest time
    idx = abs(ds.time.values - target).argmin()
    # corresponding time
    closest_time = ds.time.values[idx]
    # actual offset in hours
    actual_hours = (last_time - closest_time) / np.timedelta64(1, "h")
    print(f"Requested average: {hours} h")
    print(f"Due to dataset structure, average is performed in pratice on: {actual_hours:.3f} h")
    # Extract variables from the dataset  
    z = ds['z'].values
    temp = ds['temp'].values
    salt = ds['salt'].values

    # Compute metric 
    return bld_averaged(temp[idx:-1], salt[idx:-1], z)

metric_types = {'mld4h':mld4h,
                'mld12h':mld12h}

def compute_metrics(metrics_names):  
    """  
    Compute metrics from LES cases in oMLDb  
      
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
    
    #Extract case_ids (reminder: metrics_names is a list of caseID_MetricType)
    case_ids = [arg.rsplit("_", 1)[0] for arg in metrics_names]

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
    for i,metric_name in enumerate(metrics_names): 
        case_id, metric_type = metric_name.rsplit("_", 1)
        try:  
            print(f"  Loading {case_id}...")  
            ds = omldb.load_case(case_id)  
            metrics[metric_name] = metric_types[metric_type](ds)
              
        except Exception as e:  
            print(f"  Warning: Could not process {case_id}: {e}")  
            continue  
      
    if not metrics:  
        raise ValueError("No LES cases could be processed successfully")  
      
    print(f"\nSuccessfully computed metrics for {len(metrics)} cases")  
    return metrics


output_file = "cibles.csv"
# output_file = "cibles_all.csv"
metrics = compute_metrics(metrics_names)

with open(output_file, mode="w", newline="") as file:
    writer = csv.writer(file, quoting=csv.QUOTE_NONE, escapechar=' ')  # No quotes
    writer.writerow(["TYPE"] + metrics_names)  # Write header row
    writer.writerow(["MEAN"] + [metrics[name] for name in metrics_names])  
    writer.writerow(["VAR"] + [tolerance]*len(metrics_names))  




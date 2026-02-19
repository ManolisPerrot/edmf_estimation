import numpy as np  
import matplotlib.pyplot as plt  
from scipy.io import netcdf_file  
import yaml  
import glob, os, re  
import subprocess  
import sys  
from pathlib import Path  
import shutil  
  

  
# # Import oMLDb  
# import omldb  
  
plt.ion()  

waven   = sys.argv[1]  # First argument   
args = sys.argv[2:]  # Other arguments=metrics name with the format case-ids_metric-type
case_ids = [arg.split('_')[0] for arg in args] #extract case_ids on which to run GOTM

# Constants  
g = 9.81  
rho = 1026.0  
alphaT = 2e-4  
betaS = 8e-4  
  
# Time step range for averaging  
nt1 = 96  # final time step for plots  
nt0 = nt1 - 12  # range of time for averaging in hr  

#tttest
test_value = -100.

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
  
def compute_mld4h(case_ids=None):  
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

#===== test with predefined values
    if case_ids==['test']:
        return {'test': -100.0}
#===========

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

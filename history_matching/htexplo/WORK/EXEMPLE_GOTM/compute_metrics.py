###########################################
# Imports
###########################################
import sys  # to put the SCM into the PYTHONPATH
base_path='../../../../' #path of /edmf_estimation
sys.path.append(base_path+'edmf_ocean/library/F2PY/')
sys.path.append(base_path)
from sys import exit
import time as TIME
import xarray as xr
from scipy.interpolate import interp1d
from scm_class import SCM
import matplotlib.pyplot as plt
import numpy as np
from case_configs import case_params, default_params
from multiprocess import Pool #multiprocessING cannot handle locally defined functions, multiprocess can
# from test_version_edmf_ocean import check_edmf_ocean_version
# check_edmf_ocean_version()
from interpolate_LES_on_SCM_grids import regrid_and_save
from concurrent.futures import ProcessPoolExecutor
import time as TIME
start = TIME.time() #monitor duration of execution 
import csv

# debug=False
# if debug:
#     # Interactive testing: Set default values for 'metrics'
#     waven = '1'
#     cas = "FC500"
# else:
#     # If running as a script, capture arguments
#     #----- Input arguments
#     waven = sys.argv[2]  # First argument   
#     cas = sys.argv[1]    # Second argument  
# waven = '1'
waven   = sys.argv[1]  # First argument   
metrics = sys.argv[2:]  # Other arguments # print("WAVEN:", waven)

cases_longnames = {'FC': 'FC500','WC':'W005_C500_NO_COR'}
cases_shortnames= {'FC500':'FC','W005_C500_NO_COR':'WC'}

cases = [m[:2] for m in metrics]
cases = list(dict.fromkeys(cases))
cases = [cases_longnames[case] for case in cases]

#--------------------------------------------
param_file =f'Par1D_Wave{waven}.asc'
# Initialize an empty dictionary
data_dict = {}
# Open the file and read lines
with open(param_file, "r") as file:
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
# ===================================Load LES========================================
# regrid_and_save(cases)
TH_les = {}
U_les  = {}
V_les  = {}
time = {}
z_r = {}
z_w = {}
z_r_boolean_filter = {}
z_w_boolean_filter = {}
dz_TH_les= {}
dz_U_les = {}
dz_V_les = {}
for case in cases:
    #------ Opening LES
    path= base_path+'data/'+case+'/'
    les = xr.open_dataset(path+case+'_interpolated_on_SCM.nc')
    print('opening', path+case+'_interpolated_on_SCM.nc')
    
    
    TH_les[case] = les['TH_les'].data.transpose() #transpose to have coordinates as level then time,                                #as in the SCM  
    U_les[case]=les['U_les'].data.transpose()
    V_les[case]=les['U_les'].data.transpose()

    dz_TH_les[case] = les['dz_TH_les'].data.transpose() #transpose to have coordinates as level then time,                                #as in the SCM  
    dz_U_les[case]  = les['dz_U_les'].data.transpose()
    dz_V_les[case]  = les['dz_U_les'].data.transpose()

        #booleans that has been used to filter LES data
    z_r_boolean_filter[case] = les['z_r_boolean_filter'].data
    z_w_boolean_filter[case] = les['z_w_boolean_filter'].data

    time_les = les.time
    time[case] = ((time_les - time_les[0]) / np.timedelta64(1, 'h')).data.astype(int) + 1 #numpy array of integer hours, starting at inital time + 1h
    
    z_r[case] = les['z_r'].data
    z_w[case] = les['z_w'].data
    
#----------------------FUNCTIONS----------------------


def scm_model(X, case):
    # ====================================Run the SCM cases=======================================
    params = default_params.copy()  # Create a copy of default_params
    params.update(case_params[case])  # Update with the specific case hyperparameters in case_params[case]
    params_to_estimate = { key: X[i] for i, key in enumerate(data_dict["t_IDs"])} 
    params_to_estimate['vp_c'] = params_to_estimate['up_c']
    params_to_estimate['wp0'] = -params_to_estimate['wp0']
    params.update(params_to_estimate) # Update with the parameters to estimate
    scm = SCM(**params)
    scm.run_direct()            # Run the SCM 
    return scm

def compute_metrics(scm,case):
    # filter scm outputs
    TH_scm = scm.t_history[z_r_boolean_filter[case]]
    U_scm  = scm.u_history[z_r_boolean_filter[case]]
    V_scm  = scm.v_history[z_r_boolean_filter[case]]
    
    # compute the space-time L2 average,
    # divided by total depth and duration
    #trapz is a trapezoidal integral 

    metric_t = np.trapz( np.trapz( (TH_scm - TH_les[case])**2, z_r[case], axis=0) , time[case]) * 1/(z_r[case][-1] - z_r[case][0]) * 1 / (time[case][-1] - time[case][0]) 
    metric_u = np.trapz( np.trapz( (U_scm - U_les[case])**2, z_r[case], axis=0) , time[case]) * 1/(z_r[case][-1] - z_r[case][0]) * 1 / (time[case][-1] - time[case][0]) 
    metric_v = np.trapz( np.trapz( (V_scm - V_les[case])**2, z_r[case], axis=0) , time[case]) * 1/(z_r[case][-1] - z_r[case][0]) * 1 / (time[case][-1] - time[case][0]) 


    dz_TH_scm_tempo = np.divide( (scm.t_history[1:] - scm.t_history[:-1]).T ,  scm.z_r[1:]-scm.z_r[:-1]  ).T
    dz_U_scm_tempo  = np.divide( (scm.u_history[1:] - scm.u_history[:-1]).T ,  scm.z_r[1:]-scm.z_r[:-1]  ).T
    dz_V_scm_tempo  = np.divide( (scm.v_history[1:] - scm.v_history[:-1]).T ,  scm.z_r[1:]-scm.z_r[:-1]  ).T

    dz_TH_scm = dz_TH_scm_tempo[z_w_boolean_filter[case]]
    dz_U_scm  = dz_U_scm_tempo[z_w_boolean_filter[case]]
    dz_V_scm  = dz_V_scm_tempo[z_w_boolean_filter[case]]
    #  compute h1 metrics, ie metrics on dzX
    # (z_w[case] is already filtered)
    metric_t_h1 = np.trapz( np.trapz( (dz_TH_scm - dz_TH_les[case])**2, z_w[case], axis=0) , time[case]) * 1/(z_w[case][-1] - z_w[case][0]) * 1 / (time[case][-1] - time[case][0])  

    metric_u_h1 = np.trapz( np.trapz( (dz_U_scm - dz_U_les[case])**2, z_w[case], axis=0) , time[case]) * 1/(z_w[case][-1] - z_w[case][0]) * 1 / (time[case][-1] - time[case][0])  
    
    metric_v_h1 = np.trapz( np.trapz( (dz_V_scm - dz_V_les[case])**2, z_w[case], axis=0) , time[case]) * 1/(z_w[case][-1] - z_w[case][0]) * 1 / (time[case][-1] - time[case][0])  
    return np.array([metric_t,metric_u,metric_v, metric_t_h1,metric_u_h1, metric_v_h1])

    # return {cases_shortnames[case]+'_TH':metric_t, cases_shortnames[case]+'_U':metric_u, cases_shortnames[case]+'_V':metric_v, cases_shortnames[case]+'_dzTH':metric_t_h1, cases_shortnames[case]+'_dzU':metric_u_h1, cases_shortnames[case]+'_dzV':metric_v_h1} 
# ===========================================================================
metrics_all={}
for case in cases:
    # Define the task to parallelize for each run
    def task(run_id):
        if run_id != 't_IDs':
            print(f"Running {case} for {run_id}")
            scm=scm_model(X=data_dict[run_id], case=case)
            # metrics.append([run_id, compute_metrics(scm,case)])
            return compute_metrics(scm,case)

    # run in parallel
    with Pool() as p:
        out = p.map(task, data_dict.keys())
        out = out[1:] #remove 't_IDs' from the list
        # metrics_all.update(out)
    metrics_all[cases_shortnames[case]+'_TH'] = [o[0] for o in out]
    metrics_all[cases_shortnames[case]+'_U'] = [o[1] for o in out]
    metrics_all[cases_shortnames[case]+'_V'] = [o[2] for o in out]
    metrics_all[cases_shortnames[case]+'_dzTH'] = [o[3] for o in out]
    metrics_all[cases_shortnames[case]+'_dzU'] = [o[4] for o in out]
    metrics_all[cases_shortnames[case]+'_dzV'] = [o[5] for o in out]


#save to CSV
run_id = list(data_dict.keys())[1:]

# print(metrics_all)
# print(metrics)
metrics_selected = {key: metrics_all[key] for key in metrics}
print(metrics_selected)



output_file = "Metrics.csv"
with open(output_file, mode="w", newline="") as file:
    writer = csv.writer(file, quoting=csv.QUOTE_NONE, escapechar=' ')  # No quotes
    writer.writerow(["SIM"] + metrics)  # Write header row

    vals_inline = [metrics_selected[key] for key in metrics_selected]  

    for i in range(len(run_id)):
        row = [run_id[i]] + [float(vals_inline[k][i]) for k in range(len(vals_inline))]  # Exclude repeated run_id
        writer.writerow(row)



# output_file = "Metrics.csv"
# with open(output_file, mode="w", newline="") as file:
#     writer = csv.writer(file, quoting=csv.QUOTE_NONE, escapechar=' ')  # Prevents quotes
#     writer.writerow(["SIM"]+metrics)
#     vals_inline = [metrics_selected[key] for key in metrics_selected]
#     print(vals_inline)
#     for i in range(len(run_id)):
#         writer.writerow([run_id[i]+','+str(float(vals_inline[k][i])) for k in range(len(vals_inline))])
        


        
        # writer.writerow([rid]+val)
#     for rid, val in zip(run_id, metric_t):
#         writer.writerow([rid, val])


#!/usr/bin/env python
# coding: utf-8

###########################################
# Imports
###########################################

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
from interpolate_LES_on_SCM_grids import regrid_and_save




# ===================================Choose hyperparameters of the calibration===========
# dimensional error tolerance for L2 norm 
model_error_t,data_error_t=0.01,0.01 #°C
model_error_u,data_error_u=0.01,0.01 #ms-1 
model_error_v,data_error_v=0.01,0.01 #ms-1
# importance of each field in the cost function (non-dimensional)
weight_t=1.
weight_u=1.
weight_v=1.
# Bayesian beta hyperparameter
beta_t = weight_t / (model_error_t**2 + data_error_t**2) 
beta_u = weight_u / (model_error_u**2 + data_error_u**2) 
beta_v = weight_v / (model_error_v**2 + data_error_v**2) 

# use H1 Sobolev norm
sobolev=False
#If sobolev=True, the following hyperparameters are
# dimensional error tolerance for H1 norm
model_error_dz_t,data_error_dz_t=0.005,0.005 #°Cm-1
model_error_dz_u,data_error_dz_u=0.005,0.005 #s-1
model_error_dz_v,data_error_dz_v=0.005,0.005 #s-1
# importance of each field in the cost function (non-dimensional)
weight_dzt=1.
weight_dzu=1.
weight_dzv=1.
#TODO find the form of beta for H1
beta_t_h1 = weight_dzt / (model_error_dz_t**2 + data_error_dz_t**2) 
beta_u_h1 = weight_dzu / (model_error_dz_u**2 + data_error_dz_u**2) 
beta_v_h1 = weight_dzv / (model_error_dz_v**2 + data_error_dz_v**2) 
# ===================================Choose cases/datasets========================================
#cases = ['FC500', 'W005_C500_NO_COR','WANG1_FR']
cases = ['FC500', 'W005_C500_NO_COR']

# ===================================Interpolate LES on SCM grid========================================
regrid_and_save(cases=cases)

# ===================================Load LES========================================

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
    path= './data/'+case+'/'
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
    

def likelihood_mesonh(    
    Cent      = 0.99,
    Cdet      = 1.99,
    wp_a      = 1.,
    wp_b      = 1.0,
    wp_bp     = 0.005*250,
    up_c      = 0.5, #we take up_c=vp_c
    bc_ap     = 0.2,
    delta_bkg = 0.0025*250,
    wp0     = -1.e-08,
    sobolev=False,
    nan_file='nan_parameters.txt'
    ):

    # Load the case specific parameters
    # ATTENTION, any parameter entered in case params will 
    # OVERWRITE default params. Double-check case_configs before running

    params_to_estimate = {
                        'Cent': Cent, #0=< Cent =< 1
                        'Cdet': Cdet, #1=< Cdet =< 2?
                        'wp_a': wp_a, #0=< wp_a =< 1
                        'wp_b': wp_b, #0=< wp_b =< 1
                        'wp_bp': wp_bp,#0=< wp_bp =< 10?
                        'up_c': up_c, #0=< up_c < 1
                        'vp_c': up_c, 
                        'bc_ap': bc_ap, #0=< bc_ap =< 1
                        'delta_bkg': delta_bkg, #0=< delta_bkg =< 10?
                        'wp0' : wp0} # wp0 < -0.1?  /!\ negative !!

    scm = {}

    def likelihood_of_one_case(case_index):
        case=cases[case_index]
        # ====================================Run the SCM cases=======================================
        params = default_params.copy()  # Create a copy of default_params
        params.update(case_params[case])  # Update with the specific case hyperparameters in case_params[case]
        params.update(params_to_estimate) # Update with the parameters to estimate 
        #print(params)
        print(          'Cent', Cent, #0=< Cent =< 1
                        'Cdet', Cdet, #1=< Cdet =< 2?
                        'wp_a', wp_a, #0=< wp_a =< 1
                        'wp_b', wp_b, #0=< wp_b =< 1
                        'wp_bp', wp_bp,#0=< wp_bp =< 10?
                        'up_c', up_c, #0=< up_c < 1
                        'vp_c', up_c, 
                        'bc_ap', bc_ap, #0=< bc_ap =< 1
                        'delta_bkg', delta_bkg, #0=< delta_bkg =< 10?
                        'wp0', wp0)
        scm[case] = SCM(**params)
        scm[case].run_direct()            # Run the SCM
        print('run SCM case',case+": zinv =", scm[case].zinv)
        
        # filter scm outputs
        TH_scm = scm[case].t_history[z_r_boolean_filter[case]]
        U_scm  = scm[case].u_history[z_r_boolean_filter[case]]
        V_scm  = scm[case].v_history[z_r_boolean_filter[case]]
        
        # plt.plot(scm[case].t_history[:,-1] ,scm[case].z_r)
        # plt.plot(scm[case].t_history[:,-20],scm[case].z_r)
        # plt.plot(U_scm[:,-1] ,z_r[case])
        # plt.plot(U_scm[:,-20],z_r[case])
        # plt.plot(U_les[case][:,-1] ,z_r[case],'k+')
        # plt.plot(U_les[case][:,-20],z_r[case],'k+')
        # plt.show()

        # print(TH_scm.shape)


        # compute the space-time L2 average,
        # divided by total depth and duration
        #trapz is a trapezoidal integral 

        metric_t = np.trapz( np.trapz( (TH_scm - TH_les[case])**2, z_r[case], axis=0) , time[case]) * 1/(z_r[case][-1] - z_r[case][0]) * 1 / (time[case][-1] - time[case][0]) 
        print("metric_t", metric_t)
        metric_u = np.trapz( np.trapz( (U_scm - U_les[case])**2, z_r[case], axis=0) , time[case]) * 1/(z_r[case][-1] - z_r[case][0]) * 1 / (time[case][-1] - time[case][0]) 
        print("metric_u", metric_u)
        metric_v = np.trapz( np.trapz( (V_scm - V_les[case])**2, z_r[case], axis=0) , time[case]) * 1/(z_r[case][-1] - z_r[case][0]) * 1 / (time[case][-1] - time[case][0]) 
        print("metric_u", metric_u)

        likelihood = np.exp(-beta_t*metric_t - beta_u*metric_u - beta_v*metric_v)
        print(likelihood)


        if sobolev==True:
            dz_TH_scm_tempo = np.divide( (scm[case].t_history[1:] - scm[case].t_history[:-1]).T ,  scm[case].z_r[1:]-scm[case].z_r[:-1]  ).T
            dz_U_scm_tempo  = np.divide( (scm[case].u_history[1:] - scm[case].u_history[:-1]).T ,  scm[case].z_r[1:]-scm[case].z_r[:-1]  ).T
            dz_V_scm_tempo  = np.divide( (scm[case].v_history[1:] - scm[case].v_history[:-1]).T ,  scm[case].z_r[1:]-scm[case].z_r[:-1]  ).T

            # print(z_w_boolean_filter[case].shape)
            # print(dz_TH_scm_tempo.shape)

            dz_TH_scm = dz_TH_scm_tempo[z_w_boolean_filter[case]]
            dz_U_scm  = dz_U_scm_tempo[z_w_boolean_filter[case]]
            dz_V_scm  = dz_V_scm_tempo[z_w_boolean_filter[case]]

            # #print(dz_TH_scm - dz_TH_les[case].shape)
            # print(dz_TH_scm.shape)
            # print(z_w[case].shape)
            # plt.plot(dz_TH_scm[:,-1],z_w[case])
            # plt.plot(dz_TH_les[case][:,-1],z_w[case])
            # plt.show()
            
            #  compute metrics
            # (z_w[case] is already filtered)
            metric_t_h1 = np.trapz( np.trapz( (dz_TH_scm - dz_TH_les[case])**2, z_w[case], axis=0) , time[case]) * 1/(z_w[case][-1] - z_w[case][0]) * 1 / (time[case][-1] - time[case][0])  

            metric_u_h1 = np.trapz( np.trapz( (dz_U_scm - dz_U_les[case])**2, z_w[case], axis=0) , time[case]) * 1/(z_w[case][-1] - z_w[case][0]) * 1 / (time[case][-1] - time[case][0])  
            
            metric_v_h1 = np.trapz( np.trapz( (dz_V_scm - dz_V_les[case])**2, z_w[case], axis=0) , time[case]) * 1/(z_w[case][-1] - z_w[case][0]) * 1 / (time[case][-1] - time[case][0])  

            likelihood = likelihood * np.exp(-beta_t_h1*metric_t_h1 - beta_u_h1*metric_u_h1 - beta_v_h1*metric_v_h1)
        
        return likelihood

    likelihoods=np.zeros(len(cases))
    
    # parrallelized for-loop
    with Pool() as p:
        likelihoods = p.map(likelihood_of_one_case, range(likelihoods.size))

    # total likelihood is the product of likelihood of each case
    tot_likelihood=np.prod(likelihoods)
    print('likelihood is', tot_likelihood)
    
    if np.isnan(tot_likelihood):
        #write parameters leading to Nan is a file
        with open(nan_file, "a") as file:
            file.write("\n")
            for key, value in params_to_estimate.items():
                file.write(f"{key}: {value}\n")
            file.write("\n")
        #fix estimation crash by putting 0. for NaN
        return 0.
    else:
        return tot_likelihood

#likelihood_mesonh(sobolev=True)

# if "__name__"=="__main__":
#    likelihood_mesonh()
#     # print(likelihood)
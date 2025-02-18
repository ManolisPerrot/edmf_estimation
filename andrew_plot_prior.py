import numpy as np
import scipy.stats.qmc as qmc

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
import pymc as pm
plt.rcParams['text.usetex'] = True
plt.rcParams.update({'figure.facecolor':'white'})
plt.rcParams.update({'savefig.facecolor':'white'})

#-----------------------------------------------------------------------------------
#---------------Sample from prior (=LHC)----------------------------
#-----------------------------------------------------------------------------------
number_of_draws = 500 #100 a bit sensitive, but OK

variables =  [
              ['Cent',[0., 0.99]],
              ['Cdet',[1., 1.99]],
              ['wp_a',[0.0, 1.]],
              ['wp_b',[0.0, 1.]],
              ['wp_bp',[0., 3.]],
              ['up_c',[0., 0.99]],
              ['bc_ap',[0., 0.45]],
              ['delta_bkg',[0., 3.]],
              ['wp0',[-1e-8,-1e-1]]
             ]

nvar = len(variables)
# Latin Hyper cube sampling
print('Initial sampling of parameter space, number of samples:', number_of_draws)
X = qmc.LatinHypercube(nvar).random(number_of_draws).T  #LHC is between 0 and 1, so ling is needed
for i in range(nvar-1):#LHC is between 0 and 1, so rescaling is needed
    X[i,:] =  variables[i][1][0] + X[i,:] * (variables[i][1][1] - variables[i][1][0])
# using log scale for wp0
i=-1
X[i,:] =  np.log10(-variables[i][1][0]) + X[i,:] * (np.log10(-variables[i][1][1]) - np.log10(- variables[i][1][0]))
X[i,:] = -10**X[i,:]

ds_subsampled = {variables[i][0]: ('draw',X[i]) for i in range(nvar)}
ds_subsampled=xr.Dataset(data_vars=ds_subsampled, coords={'draw': np.arange(number_of_draws)})

#-----------------------------------------------------------------------------------
#---------------Compute SCM for each draw----------------------------
#-----------------------------------------------------------------------------------


scm = {}

def scm_model(X, case):
    params = default_params.copy()  # Create a copy of default_params
    params.update(case_params[case])  # Update with the specific case hyperparameters in case_params[case]
    params_to_estimate = { key: X[i] for i, key in enumerate(list(ds_subsampled.keys()))} 
    params.update(params_to_estimate) # Update with the parameters to estimate
    scm = SCM(**params)
    scm.run_direct()            # Run the SCM 
    return scm

cases=['FC500','W005_C500_NO_COR']
for case in cases:
    def scm_model_wrapper(draw):
        print('computing scm number',draw)
        X = [ds_subsampled[key].sel(draw=draw).values for key in ds_subsampled.keys()]
        return scm_model(X,case)

    with Pool() as p:
        scm[case] = p.map(scm_model_wrapper, ds_subsampled.draw.data)

#-----------------------------------------------------------------------------------
#------------------Andrew plot-------------------------------------------------------
#-----------------------------------------------------------------------------------

#====================FC500====================
case='FC500'

fig, axes = plt.subplots(nrows=1, ncols=4, sharex=False,
                         sharey=True, constrained_layout = True)

def plot_FC500(scm=scm['FC500'][0],mld=320,linestyle='-',color='C0',alpha=0.05,axes=axes,fig=fig):

    # ===============================================================
    ax = axes.flat[0]
    ax.set_xlabel(r'$ C$')
    ax.set_ylabel(r'$z / h $')
    ax.set_title(r'$\overline{\theta}$')
    ax.plot(scm.t_np1[:, 0], scm.z_r/mld, linestyle=linestyle, color = color,
                alpha=alpha)
    ax.set_xlim((1.60, 1.78))
    # ===============================================================
    ax = axes.flat[1]
    ax.set_title(r'$\overline{w^\prime \theta^\prime}$')
    # ax.plot(-(scm.wted + scm.wtmf), scm.z_w/mld, linestyle=linestyle, color = color,
    #                 alpha=alpha)
    ax.plot(scm.tFlx, scm.z_w/mld, linestyle=linestyle, color = color,
                    alpha=alpha)
    ax.ticklabel_format(style='sci', axis='x', scilimits=(0, 0))
    ax.set_xlabel(r'$K.m.s^{-1}$')
    # ===============================================================
    # ===============================================================
    ax = axes.flat[2]
    ax.set_title(r'$k$')
    ax.plot(scm.tke_np1, scm.z_w/mld, linestyle=linestyle, color = color,
                alpha=alpha)
    ax.ticklabel_format(style='sci', axis='x', scilimits=(0, 0))
    ax.set_xlim((-0.0001, 0.003))
    ax.set_xlabel(r'$m^2.s^{-2}$')
    # ===============================================================
    ax = axes.flat[3]
    ax.set_title(r'$\overline{w^\prime \frac{\mathbf{u}^{\prime 2}}{2}  } + \frac{1}{\rho_0} \overline{w^\prime p^{\dagger \prime} }$')
    ax.plot((scm.wtke), scm.z_r/mld, linestyle=linestyle, color = color,
                alpha=alpha)
    ax.set_xlim((- 6e-5, 1e-5))
    ax.set_xlabel(r'$m^3.s^{-3}$')
    # ===============================================================
    # adding subplot labels
    subplot_label = [r'\rm{(a)}', r'\rm{(b)}', r'\rm{(c)}',
                    r'\rm{(d)}', r'\rm{(e)}', r'\rm{(f)}']
    for i,ax in enumerate(axes.flat):
        ax.set_box_aspect(1)
        ax.annotate(
        subplot_label[i],
        xy=(0, 1), xycoords='axes fraction',
        xytext=(+0.5, -0.5), textcoords='offset fontsize', 
        fontweight='bold',
        fontsize='medium', verticalalignment='top', 
        bbox=dict(facecolor='1.', edgecolor='black',linewidth=0.1),)
        ax.set_ylim((-480,0))
temp = np.array([scm[case][i].t_np1[:,0] for i in range(number_of_draws)])
wt   = np.array([scm[case][i].tFlx for i in range(number_of_draws)])
k    = np.array([scm[case][i].tke_np1 for i in range(number_of_draws)])
wtke = np.array([scm[case][i].wtke for i in range(number_of_draws)])
mld=1
vars   = [temp,wt,k,wtke]
z_adim = [scm[case][0].z_r/mld,scm[case][0].z_w/mld,scm[case][0].z_w/mld,scm[case][0].z_r/mld]

for i in range(number_of_draws):
    plot_FC500(scm=scm['FC500'][i],fig=fig, axes=axes,mld=mld)

for k,ax in enumerate(axes.flat):
    mean = np.mean(vars[k],axis=0)
    std = np.sqrt( np.mean((vars[k])**2,axis=0)-mean**2 )
    
    ax.plot(mean     ,z_adim[k],'k'   ,linewidth=0.7,label=r'\textrm{mean}')
    ax.plot(mean-std ,z_adim[k],'k--',linewidth=0.7 ,label=r'\textrm{mean} $\pm$ \textrm{std}')
    ax.plot(mean+std ,z_adim[k],'k--',linewidth=0.7 )
    ax.set_box_aspect(1)
axes.flat[2].legend(fancybox=False, shadow=False,fontsize=8)    
plt.savefig(f'figures/MCMC_{case}_prior_andrew_N{str(number_of_draws)}.pdf',bbox_inches='tight')
plt.show()


#====================WC====================
case='W005_C500_NO_COR'

fig, axes = plt.subplots(nrows=2, ncols=3, sharex=False,
                         sharey=True, constrained_layout=True)

def plot_WC(scm=scm[case][0],mld=320,linestyle='-',color='C0',alpha=0.05,axes=axes,fig=fig):
    ax_index=-1
    # ===============================================================
    ax_index=0
    ax = axes.flat[ax_index]
    ax.set_xlabel(r'$ C$')
    ax.set_ylabel(r'$z / h $')
    ax.set_title(r'$\overline{\theta}$')
    ax.plot(scm.t_np1[:, 0], scm.z_r/mld, linestyle=linestyle, color = color,
                alpha=alpha)
    ax.set_xlim((1.64, 1.78))
    # ===============================================================
    ax_index=1
    ax = axes.flat[ax_index]
    ax.set_title(r'$\overline{u}$')
    ax.set_xlabel(r'${\rm m}\;{\rm s}^{-1}$')
    ax.plot(scm.u_np1, scm.z_r/mld, linestyle=linestyle, color = color,
                alpha=alpha)
    ax.set_xlim((-1e-3, 0.1))
    # ===============================================================
    ax_index=3
    ax = axes.flat[ax_index]
    ax.set_title(r'$\overline{w^\prime \theta^\prime}$')
    # ax.plot(-(scm.wted + scm.wtmf), scm.z_w/mld, linestyle=linestyle, color = color,
    #                 alpha=alpha)
    ax.plot(scm.tFlx, scm.z_w/mld, linestyle=linestyle, color = color,
                    alpha=alpha)
    ax.ticklabel_format(style='sci', axis='x', scilimits=(0, 0))
    ax.set_xlabel(r'$K.m.s^{-1}$')
    # ===============================================================
    ax_index=4
    ax = axes.flat[ax_index]
    ax.set_title(r'$\overline{w^\prime u^\prime}$')
    ax.plot(scm.uFlx, scm.z_w/mld, linestyle=linestyle, color = color,
                    alpha=alpha)
    ax.ticklabel_format(style='sci', axis='x', scilimits=(0, 0))
    ax.set_xlabel(r'$m^2.s^{-2}$')
    ax.set_xlim((-5e-5, 1e-6))
    # ===============================================================
    ax_index=2
    ax = axes.flat[ax_index]
    ax.set_title(r'$k$')
    ax.plot(scm.tke_np1, scm.z_w/mld, linestyle=linestyle, color = color,
                alpha=alpha)
    ax.ticklabel_format(style='sci', axis='x', scilimits=(0, 0))
    ax.set_xlim((-0.0001, 0.003))
    ax.set_xlabel(r'$m^2.s^{-2}$')
    # ===============================================================
    ax_index=5
    ax = axes.flat[ax_index]
    ax.set_title(r'$\overline{w^\prime \frac{\mathbf{u}^{\prime 2}}{2}  } + \frac{1}{\rho_0} \overline{w^\prime p^{\dagger \prime} }$')
    ax.plot((scm.wtke), scm.z_r/mld, linestyle=linestyle, color = color,
                alpha=alpha)
    ax.set_xlim((- 6e-5, 1e-5))
    ax.set_xlabel(r'$m^3.s^{-3}$')
    # ===============================================================
    # adding subplot labels
    subplot_label = [r'\rm{(a)}', r'\rm{(b)}', r'\rm{(c)}',
                     r'\rm{(d)}', r'\rm{(e)}', r'\rm{(f)}']
    for i,ax in enumerate(axes.flat):
        ax.set_box_aspect(1)
        ax.annotate(
        subplot_label[i],
        xy=(0, 1), xycoords='axes fraction',
        xytext=(+0.5, -0.5), textcoords='offset fontsize', 
        fontweight='bold',
        fontsize='medium', verticalalignment='top', 
        bbox=dict(facecolor='1.', edgecolor='black',linewidth=0.1),)
        ax.set_ylim((-480,0))

# fig, axes = plt.subplots(nrows=1, ncols=4, sharex=False,
#                          sharey=True, constrained_layout = True)


temp = np.array([scm[case][i].t_np1[:,0] for i in range(number_of_draws)])
u = np.array([scm[case][i].u_np1 for i in range(number_of_draws)])
wt   = np.array([scm[case][i].tFlx for i in range(number_of_draws)])
wu   = np.array([scm[case][i].uFlx for i in range(number_of_draws)])
k    = np.array([scm[case][i].tke_np1 for i in range(number_of_draws)])
wtke = np.array([scm[case][i].wtke for i in range(number_of_draws)])
mld=1
vars   = [temp,u,k,wt,wu,wtke]
z_adim = [scm[case][0].z_r/mld,scm[case][0].z_r/mld,scm[case][0].z_w/mld,scm[case][0].z_w/mld,scm[case][0].z_w/mld,scm[case][0].z_r/mld]

for i in range(number_of_draws):
    plot_WC(scm=scm[case][i],fig=fig, axes=axes,mld=mld)

for k,ax in enumerate(axes.flat):
    mean = np.mean(vars[k],axis=0)
    std = np.sqrt( np.mean((vars[k])**2,axis=0)-mean**2 )
    
    ax.plot(mean     ,z_adim[k],'k'   ,linewidth=0.7,label=r'\textrm{mean}')
    ax.plot(mean-std ,z_adim[k],'k--',linewidth=0.7 ,label=r'\textrm{mean} $\pm$ \textrm{std}')
    ax.plot(mean+std ,z_adim[k],'k--',linewidth=0.7 )
    ax.set_box_aspect(1)
axes.flat[2].legend(fancybox=False, shadow=False,fontsize=8)    
plt.savefig(f'figures/MCMC_{case}_prior_andrew_N{str(number_of_draws)}.pdf',bbox_inches='tight')
plt.show()

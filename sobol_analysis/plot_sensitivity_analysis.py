import numpy as np
import matplotlib.pyplot as plt
import netCDF4 as nc
import pickle

plt.rcParams['text.usetex'] = True
# plt.rcParams.update({'font.size': 22})
plt.rcParams.update({'figure.facecolor': 'white'})
plt.rcParams.update({'savefig.facecolor': 'white'})
plt.rcParams.update({'lines.linewidth': 2.0})
# plt.rcParams['text.latex.preamble']=[r"\usepackage{amsmath}"]

nsample = '2048'
cases=['FC500','W005_C500_NO_COR']
case = cases[1] # TODO: loop on cases
# additional_attribute='beta1_ap0_'
additional_attribute=''

print('opening ','outputs/sobol_'+additional_attribute+case+'_'+nsample)
with open('outputs/sobol_'+additional_attribute+case+'_'+nsample, 'rb') as handle:
# with open('outputs/sobol_beta1_ap0_'+nsample, 'rb') as handle:
    output = pickle.load(handle)


saving_path = 'figures/analysis_of_variance_'+additional_attribute+case+nsample+'.png'

true_name={'Cent': r'$\beta_1$',
            'Cdet': r'$\beta_2$',
            'wp_a': r'$a$',
            'wp_b': r'$b$',
            'wp_bp': r'$b^\prime$',
            'up_c': r'$C_u$',
            'vp_c': r'$C_v$',
            'bc_ap': r'$a_p^0$',
            'delta_bkg': r'$\delta_0$',
            'wp0': r'$w_p^0$' }

colors={    'Cent': 'tab:blue',
            'Cdet': 'tab:orange',
            'wp_a': 'tab:green',
            'wp_b': 'tab:red',
           'wp_bp': 'tab:purple',
            'up_c': 'tab:brown',
            'vp_c': 'tab:brown',
           'bc_ap': 'tab:pink',
       'delta_bkg': 'tab:gray',
             'wp0': 'tab:olive',
             }

#=============== Plot only THETA =====================
if case != 'W005_C500_NO_COR':
    # fig, axs = plt.subplots(nrows=1, ncols=2, figsize=(12, 5), sharex=False)
    fig, axs = plt.subplots(nrows=1, ncols=2, figsize=(6.4,2.4), constrained_layout=True, sharex=False)
    i=-1

    field = 'temp'
    #====================================
    i+=1
    ax=axs.flat[i]
    xmin = -1e-5
    xmax = 0.00025
    zlim = -400

    # colors = []

    z_r = output[case]['z_r']

    for parameter in output[case]['sobol_indices']:
        variance=output[case]['sobol_indices'][parameter][field]['enumerator_z']
        # variance=output[case]['sobol_indices'][parameter][field]['z index']
        p = ax.plot(variance, z_r, color=colors[parameter], label=true_name[parameter]+' contribution' )
        # colors.append(p[0].get_color())
    totVariance=output[case]['sobol_indices'][parameter][field]['denominator_z'] #same for all parameters
    ax.plot(totVariance, z_r,'--k',label='Total Variance')

    ax.set_ylabel(r'$z(m)$')
    ax.set_xlabel(r'$K^2$')
    ax.set_title(r'$\textrm{Var}_{z,t} (\theta)$ ($t=72h$)')
    # ax.set_xlim((xmin, xmax))
    ax.set_xlim(xmin, xmax)
    ax.set_ylim((zlim, 0))
    ax.grid()
    #====================================
    i+=1
    ax=axs.flat[i]

    for k,parameter in enumerate(output[case]['sobol_indices']):
        color = colors[parameter]
        L2sobolindex=output[case]['sobol_indices'][parameter][field]['l2 index']
        ax.plot(parameter, L2sobolindex, 'o', color=color)
    ax.set_title(r'1st Sobol $L^2$ indices for $Y=\theta$')
    ax.set_xticklabels([true_name[key] for key in output[case]['sobol_indices']])
    # ax.set_yscale('log')
    ax.grid()


    # #====================================
    # #====================================
    # i+=1
    # ax=axs.flat[i]
    # xmin = -10
    # xmax = 10
    # # zlim = -400

    # colors = []

    # z_r = output[case]['z_r']

    # for parameter in output[case]['sobol_indices']:
    #     # variance=output[case]['sobol_indices'][parameter][field]['enumerator_total_z']
    #     variance=output[case]['sobol_indices'][parameter][field]['total z index']
    #     # variance=output[case]['sobol_indices'][parameter][field]['z index']
    #     p = ax.plot(variance, z_r, label=true_name[parameter]+' contribution' )
    #     colors.append(p[0].get_color())
    # # totVariance=output[case]['sobol_indices'][parameter][field]['denominator_z'] #same for all parameters
    # # ax.plot(totVariance, z_r,'--k',label='Total Variance')

    # ax.set_ylabel(r'$z(m)$')
    # ax.set_xlabel(r'$K^2$')
    # ax.set_title(r'$\textrm{Var}_{z,t} (\theta)$ ($t=72h$)')
    # ax.set_xlim((xmin, xmax))
    
    # ax.set_ylim((zlim, 0))
    # ax.grid()
    # #====================================
    # i+=1
    # ax=axs.flat[i]

    # for k,parameter in enumerate(output[case]['sobol_indices']):
    #     color = colors[k]
    #     L2sobolindex=output[case]['sobol_indices'][parameter][field]['total l2 index']
    #     ax.plot(parameter, L2sobolindex, 'o', color=color)
    # ax.set_title(r'Total Sobol $L^2$ indices for $Y=\theta$')
    # ax.set_xticklabels([true_name[key] for key in output[case]['sobol_indices']])
    # # ax.set_yscale('log')
    # ax.grid()


    # #====================================


    # # handles, labels = axs.flat[0].get_legend_handles_labels()
    # # fig.legend(handles, labels,loc='upper center', bbox_to_anchor=(0.5, 0.05),fancybox=False, shadow=False, ncol=3)
    # fig.tight_layout()
    # # plt.savefig(saving_path,bbox_inches='tight',dpi=600)

#========== PLOT U and THETA
else:

    # fig, axs = plt.subplots(nrows=2, ncols=2, figsize=(12, 8), sharex=False)
    fig, axs = plt.subplots(nrows=2, ncols=2, constrained_layout=True, sharex=False)
    # fig, axs = plt.subplots(nrows=3, ncols=2, constrained_layout=True, sharex=False)

    i=-1

    field = 'temp'
    #====================================
    i+=1
    ax=axs.flat[i]
    xmin = -1e-5
    xmax = 0.00025
    zlim = -400

    # colors = []

    z_r = output[case]['z_r']

    for parameter in output[case]['sobol_indices']:
        variance=output[case]['sobol_indices'][parameter][field]['enumerator_z']
        p = ax.plot(variance, z_r, color=colors[parameter], label=true_name[parameter]+' contribution' )
        # colors.append(p[0].get_color())
    totVariance=output[case]['sobol_indices'][parameter][field]['denominator_z'] #same for all parameters
    ax.plot(totVariance, z_r,'--k',
                        label='Total Variance')

    ax.set_ylabel(r'$z(m)$')
    ax.set_xlabel(r'$K^2$')
    ax.set_title(r'$\textrm{Var}_{z,t} (\theta)$ ($t=72h$)')
    # ax.set_xlim((xmin, xmax))
    ax.set_xlim(xmin, xmax)
    ax.set_ylim((zlim, 0))
    ax.grid()
    #====================================
    i+=1
    ax=axs.flat[i]

    for k,parameter in enumerate(output[case]['sobol_indices']):
        color = colors[parameter]
        L2sobolindex=output[case]['sobol_indices'][parameter][field]['l2 index']
        ax.plot(parameter, L2sobolindex, 'o', color=color)
    ax.set_title(r'1st Sobol $L^2$ indices for $Y=\theta$')
    ax.set_xticklabels([true_name[key] for key in output[case]['sobol_indices']])
    ax.grid()


    # #==================================== TOTAL INDICES
    # #====================================
    # i+=1
    # ax=axs.flat[i]
    # xmin = -10
    # xmax = 10
    # # zlim = -400

    # colors = []

    # z_r = output[case]['z_r']

    # for parameter in output[case]['sobol_indices']:
    #     # variance=output[case]['sobol_indices'][parameter][field]['enumerator_total_z']
    #     variance=output[case]['sobol_indices'][parameter][field]['total z index']
    #     # variance=output[case]['sobol_indices'][parameter][field]['z index']
    #     p = ax.plot(variance, z_r, label=true_name[parameter]+' contribution' )
    #     colors.append(p[0].get_color())
    # # totVariance=output[case]['sobol_indices'][parameter][field]['denominator_z'] #same for all parameters
    # # ax.plot(totVariance, z_r,'--k',label='Total Variance')

    # ax.set_ylabel(r'$z(m)$')
    # ax.set_xlabel(r'$K^2$')
    # ax.set_title(r'$\textrm{Var}_{z,t} (\theta)$ ($t=72h$)')
    # ax.set_xlim((xmin, xmax))
    
    # ax.set_ylim((zlim, 0))
    # ax.grid()
    # #====================================
    # i+=1
    # ax=axs.flat[i]

    # for k,parameter in enumerate(output[case]['sobol_indices']):
    #     color = colors[k]
    #     L2sobolindex=output[case]['sobol_indices'][parameter][field]['total l2 index']
    #     ax.plot(parameter, L2sobolindex, 'o', color=color)
    # ax.set_title(r'Total Sobol $L^2$ indices for $Y=\theta$')
    # ax.set_xticklabels([true_name[key] for key in output[case]['sobol_indices']])
    # # ax.set_yscale('log')
    # ax.grid()


    # # #====================================



    #====================================
    field = 'u' #
    #====================================
    z_r = output[case]['z_r']

    i+=1
    ax=axs.flat[i]
    xmin = -1e-5
    xmax = 0.0002
    zlim = -400
    for k,parameter in enumerate(output[case]['sobol_indices']):
        color = colors[parameter]
        variance=output[case]['sobol_indices'][parameter][field]['enumerator_z']
        ax.plot(variance, z_r, label=true_name[parameter]+' contribution', color=color )

    totVariance=output[case]['sobol_indices'][parameter][field]['denominator_z'] #same for all parameters
    ax.plot(totVariance, z_r,'--k',
                        label='Total Variance')

    ax.set_ylabel(r'$z(m)$')
    ax.set_xlabel(r'$m^2.s^{-2}$')
    ax.set_title(r'$\mathrm{Var}_{z,t} (u)$ ($t=72h$)')
    ax.set_xlim(xmin, xmax)
    ax.set_ylim((zlim, 0))
    ax.grid()
    #====================================
    i+=1
    ax=axs.flat[i]

    for k,parameter in enumerate(output[case]['sobol_indices']):
        color = colors[parameter]
        L2sobolindex=output[case]['sobol_indices'][parameter][field]['l2 index']
        ax.plot(parameter, L2sobolindex, 'o', color=color, label=true_name[parameter]+' contribution')
    ax.set_title(r'1st Sobol $L^2$ indices for $Y=u$')
    ax.set_xticklabels([true_name[key] for key in output[case]['sobol_indices']])
    ax.grid()

handles, labels = axs.flat[0].get_legend_handles_labels()
fig.legend(handles, labels,loc='upper center', bbox_to_anchor=(0.5, 0.02),fancybox=False, shadow=False, ncol=4)
# fig.tight_layout()
# fig.legend(handles,labels)
plt.savefig(saving_path,bbox_inches='tight',dpi=600)
print('figure saved at ',saving_path)

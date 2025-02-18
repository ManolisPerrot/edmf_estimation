import numpy as np
import arviz as az
import matplotlib.pyplot as plt
from matplotlib import ticker
from matplotlib.ticker import LogLocator
import arviz as az
import matplotlib.pyplot as plt
import numpy as np
from matplotlib.colors import BoundaryNorm, ListedColormap
from matplotlib.cm import ScalarMappable

# from likelihood_mesonh import likelihood_mesonh
plt.rcParams['text.usetex'] = True
plt.rcParams.update({'figure.facecolor':'white'})
plt.rcParams.update({'savefig.facecolor':'white'})
az.rcParams["plot.max_subplots"] = 200 #arviz has a default limitations of 8x8 subplots

## Load the data
data = az.from_netcdf('MCMC_output/MCMC_2024-12-05_09:05:18.950966.nc')

## convert to xarray dataset
ds = az.convert_to_dataset(data)

summary = az.summary(data)
## compute the MAP estimate
max_index = int(ds.argmax()['likelihood'])

chain_length = ds['draw'].shape[0]

chain_nr = max_index // chain_length
draw_nr = max_index % chain_length

MAP = ds.isel(draw=draw_nr, chain=chain_nr)

Cent = float(MAP['Cent'].values)
Cdet = float(MAP['Cdet'].values)
delta_bkg = float(MAP['delta_bkg'].values)
up_c = float(MAP['up_c'].values)
wp_a = float(MAP['wp_a'].values)
wp_b = float(MAP['wp_b'].values)
wp_bp = float(MAP['wp_bp'].values)
bc_ap = float(MAP['bc_ap'].values)
log_wp_0 = float(MAP['log_wp_0'].values)

print(log_wp_0)

map_dic = {key:float(MAP[key].values) for key in MAP.keys()}  
del map_dic['likelihood']
del map_dic['wp_0']
# likelihood_mesonh(    
#     Cent      = Cent,
#     Cdet      =  Cdet,
#     wp_a      = wp_a,
#     wp_b      = wp_b,
#     wp_bp     = wp_bp,
#     up_c      = up_c, #we take up_c=vp_c
#     bc_ap     = bc_ap,
#     delta_bkg = delta_bkg,
#     wp0       = wp_0,
#     sobolev=False,
#     nan_file='nan_parameters.txt',
#     trace=True,
#     ret_log_likelihood=False,
#     )
# """
# Errors are:
# 1st data:
# - metric_t: 1.343877792850065e-05
# - metric_u: 3.416123222101756e-09
# - metric_v: 3.416123222101756e-09

# 2nd data:
# - metric_t: 6.2391438912764285e-06
# - metric_u: 4.836421614543722e-06
# - metric_v: 0.0001588768739522521
# """

# likelihood_mesonh(    
#     Cent      = 0.8985,
#     Cdet      =  1.827,
#     wp_a      = 0.9458,
#     wp_b      = 0.9488,
#     wp_bp     = 1.951,
#     up_c      = 0.2711, #we take up_c=vp_c
#     bc_ap     = 0.3673,
#     delta_bkg = 2.253,
#     wp0       = -7.874e-08,
#     sobolev=False,
#     nan_file='nan_parameters.txt',
#     trace=True,
#     ret_log_likelihood=False,
#     )
# """
# Errors are:
# 1st data:
# - metric_t: 1.6724557285266624e-05
# - metric_u: 3.416123222101756e-09
# - metric_v: 3.416123222101756e-09

# 2nd data:
# - metric_t: 4.404447965212885e-06
# - metric_u: 8.48592718610331e-06
# - metric_v: 0.0001588768739522521
# """



# az.rhat(data)

# az.plot_trace(data, var_names=["Cent"])
# plt.tight_layout()
# #plt.savefig('paper/figures/Cent_trace.png')
# plt.show()

# az.plot_autocorr(data, var_names=["Cent", "Cdet", "delta_bkg"])
# plt.show()




#--------- Pairplot
axes = az.plot_pair(data, var_names=['Cent', 'Cdet', 'wp_a', 'wp_b', 'wp_bp', 'up_c', 'bc_ap', 'delta_bkg', 'log_wp_0'], 
# kind='scatter', scatter_kwargs={'alpha':1/254,},
# kind='hexbin',
kind='kde', 
marginals=True,figsize=(13,13),
reference_values=map_dic,reference_values_kwargs={'color':'C1','marker':'o','markersize':7,'alpha':1.},
point_estimate='mean',point_estimate_kwargs={'linestyle':':'},
# kde_kwargs={'fill_kwargs':{'alpha':0}},
# marginal_kwargs={'quantiles':[0.25,0.75],'color':'tab:gray'},
)

#------------------------------------------------------
# Add a discrete colorbar

# Define discrete levels
levels = np.linspace(0, 1, 7)  # 7 discrete levels

# Create a custom colormap
cmap = plt.cm.viridis
colors = cmap(np.linspace(0, 1, len(levels)))  # Extract colors for the levels
colors[0] = [1, 1, 1, 1]  # Replace the first color with white (RGBA: 1, 1, 1, 1)
custom_cmap = ListedColormap(colors)

# Define the norm
norm = BoundaryNorm(boundaries=levels, ncolors=custom_cmap.N, extend='neither')
# Add a discrete colorbar
fig = plt.gcf()
cbar_ax = fig.add_axes([0.9, 0.19, 0.03, 0.3])  # Adjust position and size (e.g., smaller height)
sm = ScalarMappable(cmap=custom_cmap, norm=norm)
sm.set_array([])  # Required for the colorbar
cbar = fig.colorbar(sm, cax=cbar_ax, ticks=levels, label=r"arbitrary units")
#------------------------------------------------------
for i,key in enumerate(map_dic):
    axes[8,i].tick_params(labelrotation=55)
    # axes[i,i].axvline(summary['mean'][key]+summary['sd'][key])
    # axes[i,i].axvline(summary['mean'][key]-summary['sd'][key])


# axes[8,8].set_xscale('symlog',linthresh=1e-9)
# axes[8,8].set_xlim(-1e-1,-1e-8)
# axes[8,8].tick_params(labelrotation=45)
# # axes[8,8].xaxis.set_major_locator(LogLocator(base=10.0, numticks=5))  # 5 ticks
# axes[8,8].set_xticks([-1e-2, -1e-4, -1e-6, -1e-8])

# axes[8,0].set_yscale('symlog',linthresh=1e-9)
# axes[8,0].set_ylim(-1e-1,-1e-8)
# axes[8,0].tick_params('y',labelrotation=0)
# axes[8,0].set_yticks([-1e-2, -1e-4, -1e-6, -1e-8])
for ax in axes.flat:
    ax.set_box_aspect(1)

true_names = [r'$C_{\mathrm{ent}}$', r'$C_{\mathrm{det}}$', r'$a$', r'$b$', r'$b^\prime$',r'$C_u$',r'$a_p^0$',r'$\delta_0$',  r'$\mathrm{log}_{10}(-w_p^0)$']
for i in range(9):
    axes[i,0].set_ylabel(true_names[i])
    axes[8,i].set_xlabel(true_names[i])

plt.tight_layout()
saving_name = 'figures/MCMC_pairplot_logwp0.pdf'
plt.savefig(saving_name,bbox_inches='tight')

# plt.savefig('figures/MCMC_pairplot.png',bbox_inches='tight')
# plt.show()

#------------------------------------------------------

# az.plot_forest(data, var_names=["Cent"], combined=True, hdi_prob=0.95, r_hat=True, ess=True);
# az.plot_forest(data, var_names=["Cdet"], combined=True, hdi_prob=0.95, r_hat=True, ess=True);
# az.plot_forest(data, var_names=["delta_bkg"], combined=True, hdi_prob=0.95, r_hat=True, ess=True);
# # az.plot_forest(trace, var_names=["likelihood"], combined=True, hdi_prob=0.95, r_hat=True, ess=True);

# plt.show()
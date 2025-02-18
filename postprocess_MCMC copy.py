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
import seaborn as sns
import xarray as xr
# from likelihood_mesonh import likelihood_mesonh
plt.rcParams['text.usetex'] = True
plt.rcParams.update({'figure.facecolor':'white'})
plt.rcParams.update({'savefig.facecolor':'white'})
az.rcParams["plot.max_subplots"] = 200 #arviz has a default limitations of 8x8 subplots

## Load the data
data = az.from_netcdf('MCMC_output/MCMC_2024-12-05_09:05:18.950966.nc')

## convert to xarray dataset
ds = az.convert_to_dataset(data)

# az.summary(data)
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


#compute correlation matrix
corr = np.zeros((len(map_dic),len(map_dic)))
for i,ikey in enumerate(map_dic):
    for j,jkey in enumerate(map_dic):
        if j>i:
            corr[i,j] = np.array([[xr.corr(data.posterior[ikey][0], data.posterior[jkey][0])]])




#--------- Pairplot
axes = az.plot_pair(data, var_names=['Cent', 'Cdet', 'wp_a', 'wp_b', 'wp_bp', 'up_c', 'bc_ap', 'delta_bkg', 'log_wp_0'], 
# kind='scatter', scatter_kwargs={'alpha':1/254,},
# kind='hexbin',
kind='kde', 
marginals=True,figsize=(13,13),reference_values=map_dic,divergences=True,reference_values_kwargs={'color':'C1','marker':'o','markersize':7,'alpha':1.})

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
for i in range(9):
    axes[8,i].tick_params(labelrotation=55)
for ax in axes.flat:
    ax.set_box_aspect(1)

true_names = [r'$C_{\mathrm{ent}}$', r'$C_{\mathrm{det}}$', r'$a$', r'$b$', r'$b^\prime$',r'$C_u$',r'$a_p^0$',r'$\delta_0$',  r'$\mathrm{log}_{10}(-w_p^0)$']
for i in range(9):
    axes[i,0].set_ylabel(true_names[i])
    axes[8,i].set_xlabel(true_names[i])

# #------------------------------------------------------
axes[0,8].plot(np.linspace(0,1,10),np.linspace(0,1,10))
# # Plotting correlations on the upper panels
# # Generate a custom diverging colormap
# # fig, axes = plt.subplots(9, 9, figsize=(13, 13))

cmap = sns.diverging_palette(230, 20, as_cmap=True)
# Plotting correlations as colored squares on upper panels
for i in range(9):
    for j in range(9):
        if i > j:  # Upper-diagonal subplots
            ax = axes[i, j]
            
            # Create a uniform square with color based on the correlation
            corr_value = corr[i, j]
            ax.imshow(
                [[corr_value]], 
                cmap=cmap, 
                vmin=-1, 
                vmax=1,
                extent=[0, 1, 0, 1]  # Scale to subplot's coordinate system
            )
            
            # Add correlation value as text
            ax.text(
                0.5, 0.5, f"{corr_value:.2f}",
                ha='center', va='center',
                fontsize=10, color='white' if abs(corr_value) > 0.5 else 'black'
            )
            
            # Remove ticks and labels for clean appearance
            ax.set_xticks([])
            ax.set_yticks([])
# # # Add a colorbar
# # cbar = fig.colorbar(im)
# # cbar.set_label("Correlation")
#------------------------------------------------------
plt.tight_layout()
saving_name = 'figures/MCMC_pairplot_logwp0.pdf'
# plt.savefig(saving_name,bbox_inches='tight')
plt.show()

#------------------------------------------------------

# az.plot_forest(data, var_names=["Cent"], combined=True, hdi_prob=0.95, r_hat=True, ess=True);
# az.plot_forest(data, var_names=["Cdet"], combined=True, hdi_prob=0.95, r_hat=True, ess=True);
# az.plot_forest(data, var_names=["delta_bkg"], combined=True, hdi_prob=0.95, r_hat=True, ess=True);
# # az.plot_forest(trace, var_names=["likelihood"], combined=True, hdi_prob=0.95, r_hat=True, ess=True);

# plt.show()


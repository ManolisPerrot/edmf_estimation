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



true_names = [r'$C_{\mathrm{ent}}$', r'$C_{\mathrm{det}}$', r'$a$', r'$b$', r'$b^\prime$',r'$C_u$',r'$a_p^0$',r'$\delta_0$',  r'$\mathrm{log}_{10}(-w_p^0)$']
var_names=['Cent', 'Cdet', 'wp_a', 'wp_b', 'wp_bp', 'up_c', 'bc_ap', 'delta_bkg', 'log_wp_0']
#-------------------- Trace=mixing of the chains
# all the chains should agree
#--------------------
axes = az.plot_trace(data, var_names=var_names)
#plt.savefig('paper/figures/Cent_trace.png')
for i in range(len(true_names)):
    axes[i,0].set_title(true_names[i])
    axes[i,1].set_title(true_names[i])
    
plt.tight_layout()
saving_name = 'figures/MCMC_mixing.pdf'
# plt.savefig(saving_name,bbox_inches='tight')

# #-------------------- Autocorrelation
az.plot_autocorr(data, var_names=["Cent", "Cdet", "delta_bkg"])
plt.show()




az.plot_forest(data, var_names=var_names, combined=True, hdi_prob=0.95, r_hat=True, ess=True);
plt.tight_layout()
saving_name = 'figures/MCMC_forest.pdf'
# plt.savefig(saving_name,bbox_inches='tight')
plt.show()
import numpy as np
import arviz as az
import matplotlib.pyplot as plt
from likelihood_mesonh import likelihood_mesonh

## Load the data
data = az.from_netcdf('MAP_error_run.nc')

## convert to xarray dataset
ds = az.convert_to_dataset(data)

az.summary(data)
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
wp_0 = float(MAP['wp_0'].values)

likelihood_mesonh(    
    Cent      = Cent,
    Cdet      =  Cdet,
    wp_a      = wp_a,
    wp_b      = wp_b,
    wp_bp     = wp_bp,
    up_c      = up_c, #we take up_c=vp_c
    bc_ap     = bc_ap,
    delta_bkg = delta_bkg,
    wp0       = wp_0,
    sobolev=False,
    nan_file='nan_parameters.txt',
    trace=True,
    ret_log_likelihood=False,
    )
"""
Errors are:
1st data:
- metric_t: 1.343877792850065e-05
- metric_u: 3.416123222101756e-09
- metric_v: 3.416123222101756e-09

2nd data:
- metric_t: 6.2391438912764285e-06
- metric_u: 4.836421614543722e-06
- metric_v: 0.0001588768739522521
"""

likelihood_mesonh(    
    Cent      = 0.8985,
    Cdet      =  1.827,
    wp_a      = 0.9458,
    wp_b      = 0.9488,
    wp_bp     = 1.951,
    up_c      = 0.2711, #we take up_c=vp_c
    bc_ap     = 0.3673,
    delta_bkg = 2.253,
    wp0       = -7.874e-08,
    sobolev=False,
    nan_file='nan_parameters.txt',
    trace=True,
    ret_log_likelihood=False,
    )
"""
Errors are:
1st data:
- metric_t: 1.6724557285266624e-05
- metric_u: 3.416123222101756e-09
- metric_v: 3.416123222101756e-09

2nd data:
- metric_t: 4.404447965212885e-06
- metric_u: 8.48592718610331e-06
- metric_v: 0.0001588768739522521
"""



az.rhat(data)

az.plot_trace(data, var_names=["Cent"])
plt.tight_layout()
#plt.savefig('paper/figures/Cent_trace.png')
plt.show()

az.plot_autocorr(data, var_names=["Cent", "Cdet", "delta_bkg"])
plt.show()




az.plot_pair(data, var_names=["Cent", "Cdet", "delta_bkg", "wp_a", "wp_b", "up_c"], kind='kde', marginals=True)

az.plot_forest(data, var_names=["Cent"], combined=True, hdi_prob=0.95, r_hat=True, ess=True);
az.plot_forest(data, var_names=["Cdet"], combined=True, hdi_prob=0.95, r_hat=True, ess=True);
az.plot_forest(data, var_names=["delta_bkg"], combined=True, hdi_prob=0.95, r_hat=True, ess=True);
# az.plot_forest(trace, var_names=["likelihood"], combined=True, hdi_prob=0.95, r_hat=True, ess=True);

plt.show()
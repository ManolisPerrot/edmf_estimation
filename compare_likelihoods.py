
from juliacall import Main as jl
import numpy as np
import seaborn as sns
import matplotlib.pyplot as plt
import pandas as pd
import xarray as xr
import multiprocessing as mp


###################################################
# plt.rcParams['text.usetex'] = True
# plt.rcParams.update({'font.size': 25})
# plt.rcParams.update({'figure.facecolor': 'white'})
# plt.rcParams.update({'savefig.facecolor': 'white'})
###########################################

"""For high dimensions, it is much easier to sample from distribution then compute marginals, 
instead of computing marginals from the pdf """

# colors
blue, orange, magenta, grey, green = '#0db4c3', '#eea021', '#ff0364', '#606172', '#3fb532'

jl.seval("""using SequentialMeasureTransport""")
jl.seval("""import SequentialMeasureTransport as SMT""")
jl.seval("""using Distributions""")
jl.seval("""using PythonCall""")
# ===========================================================================


loaded_reference_likelihood3 = np.load('reference_likelihood3_n20.npz', allow_pickle=True)

#convert into xarray for plotting
ds = xr.Dataset( {'likelihood': (['Cent','delta_bkg','wp_a'],loaded_reference_likelihood3['likelihood_output'])}, coords={'Cent': loaded_reference_likelihood3['Cent'],'delta_bkg': loaded_reference_likelihood3['delta_bkg'], 'wp_a': loaded_reference_likelihood3['wp_a']  })

#plot
fig, axs = plt.subplots(nrows=1, ncols=3)
ds['likelihood'].mean('Cent').plot(ax=axs.flat[0])
ds['likelihood'].mean('delta_bkg').plot(ax=axs.flat[1])
im = ds['likelihood'].mean('wp_a').plot(ax=axs.flat[2])
for ax in axs.flat:
    ax.set_box_aspect(1)
# plt.show()

#import estimated sampler
sampler_name = 'sampler_likelihood3_N500_L8_phi50_algb1_2.jld2'
print('Load sampler and sample')
jl.seval(f"""smp = SMT.load_sampler("{sampler_name}")""")
smp_instance = jl.smp

#define pdf in python
def infered_pdf(x):
    print('Computing infered pdf on', x)
    return jl.pdf(smp_instance, x)
# infered_pdf = np.vectorize(infered_pdf)

Cent_range      = ds['Cent']
delta_bkg_range = ds['delta_bkg']
wp_a_range      = ds['wp_a']
X,Y,Z = np.meshgrid(Cent_range,delta_bkg_range,wp_a_range,indexing='ij')

# Flatten the grids to create a list of points
points = np.array([X.flatten(), Y.flatten(), Z.flatten()]).T

# Use multiprocessing to compute pdf(x, y, z) in parallel
# with mp.Pool(mp.cpu_count()) as pool:
#     results = pool.map(infered_pdf, points)

results = np.array([infered_pdf(x) for x in points])

## Reshape the results back to the original 3D shape
infered_pdf_output = np.array(results).reshape(X.shape)

#plo the result
ds = xr.Dataset( {'likelihood': (['Cent','delta_bkg','wp_a'],loaded_reference_likelihood3['likelihood_output'])}, coords={'Cent': loaded_reference_likelihood3['Cent'],'delta_bkg': loaded_reference_likelihood3['delta_bkg'], 'wp_a': loaded_reference_likelihood3['wp_a']  })
fig, axs = plt.subplots(nrows=1, ncols=3)
ds['likelihood'].mean('Cent').plot(ax=axs.flat[0])
ds['likelihood'].mean('delta_bkg').plot(ax=axs.flat[1])
im = ds['likelihood'].mean('wp_a').plot(ax=axs.flat[2])

ds = ds.assign({'estimated_pdf': (['Cent','delta_bkg','wp_a'],infered_pdf_output)})

fig, axs = plt.subplots(nrows=1, ncols=3)
ds['estimated_pdf'][1:-1,1:-1,1:-1].mean('Cent').plot(ax=axs.flat[0])
ds['estimated_pdf'][1:-1,1:-1,1:-1].mean('delta_bkg').plot(ax=axs.flat[1])
im = ds['estimated_pdf'][1:-1,1:-1,1:-1].mean('wp_a').plot(ax=axs.flat[2])

plt.show()
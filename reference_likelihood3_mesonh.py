from likelihood_mesonh import likelihood_mesonh
import time
import numpy as np
import multiprocessing as mp
import matplotlib.pyplot as plt
#monitor duration of execution 
start = time.time()

def likelihood3(points):
    return likelihood_mesonh(Cent=points[0], delta_bkg=points[1], wp_a=points[2])

n = 20
Cent_range      = np.linspace(0.0,0.999, n)
delta_bkg_range = np.linspace(300*0.0001,300*0.01, n)
wp_a_range      = np.linspace(0.0,0.999, n)

X,Y,Z = np.meshgrid(Cent_range,delta_bkg_range,wp_a_range,indexing='ij')

# Flatten the grids to create a list of points
points = np.array([X.flatten(), Y.flatten(), Z.flatten()]).T

# Use multiprocessing to compute f(x, y, z) in parallel
with mp.Pool(mp.cpu_count()) as pool:
    results = pool.map(likelihood3, points)

# Reshape the results back to the original 3D shape
likelihood_output = np.array(results).reshape(X.shape)

np.savez('reference_likelihood3_n20.npz', likelihood_output = likelihood_output, Cent = Cent_range, delta_bkg = delta_bkg_range, wp_a = wp_a_range)

stop = time.time()
print('duration of execution', stop-start)



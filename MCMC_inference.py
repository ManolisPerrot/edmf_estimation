from likelihood_mesonh import likelihood_mesonh
import time
# from multiprocess import Pool
import numpy as np
import pymc as pm
import pytensor
import pytensor.tensor as pt
from pytensor.graph import Apply, Op
import arviz as az
import matplotlib.pyplot as plt


def log_likelihood(Cent, Cdet, wp_a, wp_b, wp_bp, up_c, bc_ap, delta_bkg, wp_0):
    # print(Cent, Cdet, delta_bkg)
    like = likelihood_mesonh(Cent=Cent, Cdet=Cdet, wp_a=wp_a, wp_b=wp_b, wp_bp=wp_bp, up_c=up_c,
                            bc_ap=bc_ap, delta_bkg=delta_bkg, wp0=wp_0, ret_log_likelihood=True)
    # print(like)
    return np.asarray(like)

# likelihood_mesonh(Cent=0.5, Cdet=1.5, delta_bkg=1.0, ret_log_likelihood=False, trace=True)

class LogLike(Op):
    def make_node(self, Cent, Cdet, wp_a, wp_b, wp_bp, up_c, bc_ap, delta_bkg, wp_0, data) -> Apply:
        # Convert inputs to tensor variables
        Cent = pt.as_tensor(Cent)
        Cdet = pt.as_tensor(Cdet)
        wp_a = pt.as_tensor(wp_a)
        wp_b = pt.as_tensor(wp_b)
        wp_bp = pt.as_tensor(wp_bp)
        up_c = pt.as_tensor(up_c)
        bc_ap = pt.as_tensor(bc_ap)
        delta_bkg = pt.as_tensor(delta_bkg)
        wp_0 = pt.as_tensor(wp_0)
        data = pt.as_tensor(data)    #keep this empty

        inputs = [Cent, Cdet, wp_a, wp_b, wp_bp, up_c, bc_ap, delta_bkg, wp_0, data]
        # Define output type, in our case a vector of likelihoods
        # with the same dimensions and same data type as data
        # If data must always be a vector, we could have hard-coded
        # outputs = [pt.vector()]
        outputs = [pt.scalar()]

        # Apply is an object that combines inputs, outputs and an Op (self)
        return Apply(self, inputs, outputs)

    def perform(self, node: Apply, inputs: list[np.ndarray], outputs: list[list[None]]) -> None:
        # This is the method that compute numerical output
        # given numerical inputs. Everything here is numpy arrays
        Cent, Cdet, wp_a, wp_b, wp_bp, up_c, bc_ap, delta_bkg, wp_0, data = inputs  # this will contain my variables

        # call our numpy log-likelihood function
        loglike_eval = log_likelihood(Cent, Cdet, wp_a, wp_b, wp_bp, up_c, bc_ap, delta_bkg, wp_0)

        # Save the result in the outputs list provided by PyTensor
        # There is one list per output, each containing another list
        # pre-populated with a `None` where the result should be saved.
        outputs[0][0] = np.asarray(loglike_eval)

loglike_op = LogLike()

# _test_like = loglike_op(0.5, 1.5, 0.5, 0.5, 0.3, 0.1, 1.0, 0.5)
# pytensor.dprint(_test_like, print_type=True)
# _test_like.eval()

def custom_model_loglike(data, Cent, Cdet, wp_a, wp_b, wp_bp, up_c, bc_ap, delta_bkg, wp_0):
    return loglike_op(Cent, Cdet, wp_a, wp_b, wp_bp, up_c, bc_ap, delta_bkg, wp_0, data)

MC_model = pm.Model()



## NEW bounds fixing NaN bugs (+ need small_ap = True)
# variables =  [
#               ['Cent',[0., 0.99]],
#               ['Cdet',[1., 1.99]],
#               ['wp_a',[0.01, 1.]],
#               ['wp_b',[0.01, 1.]],
#               ['wp_bp',[0.25, 2.5]],
#               ['up_c',[0., 0.9]],
#               ['bc_ap',[0., 0.45]],
#               ['delta_bkg',[0.25, 2.5]],
#               ['wp0',[-1e-8,-1e-7]]
#              ]

## !!!!!!!!!!!!!!!!!!! WARNING cahnge the saving name before overridding previous inference !!!!!!!
with MC_model:
    # Defining the prior
    Cent = pm.Uniform('Cent', lower=0., upper=1.)#pm.Uniform('Cent', lower=0, upper=0.99)
    Cdet = pm.Uniform('Cdet', lower=1., upper=2.)#pm.Uniform('Cdet', lower=1, upper=1.99)
    wp_a = pm.Uniform('wp_a', lower=0.0, upper=1.0)#pm.Uniform('wp_a', lower=0.01, upper=1.0)
    wp_b = pm.Uniform('wp_b', lower=0.0, upper=1.0)#pm.Uniform('wp_b', lower=0.01, upper=1.0)
    wp_bp     = pm.Uniform('wp_bp', lower=0., upper=3.) #pm.Uniform('wp_bp', lower=0., upper=2.5)
    up_c      = pm.Uniform('up_c', lower=0, upper=1.) #pm.Uniform('up_c', lower=0, upper=0.9)
    bc_ap     = pm.Uniform('bc_ap', lower=0, upper=0.45) #pm.Uniform('bc_ap', lower=0, upper=0.45)
    delta_bkg = pm.Uniform('delta_bkg', lower=0., upper=3.) #pm.Uniform('delta_bkg', lower=0.25, upper=2.5)
    #wp_0      = pm.Uniform('wp_0', lower=-1e-7, upper=-1e-8) #pm.Uniform('wp_0', lower=-1e-7, upper=-1e-8)
    # Sample uniformly in log space (log10)
    log_wp_0 = pm.Uniform('log_wp_0', lower=np.log10(1e-8), upper=np.log10(1e-1))
    # Convert back to the original scale and make it negative
    wp_0 = pm.Deterministic('wp_0', -10**log_wp_0)


    ## Define the likelihood
    pm.CustomDist('likelihood', Cent, Cdet, wp_a, wp_b, wp_bp, up_c, bc_ap, delta_bkg, wp_0, logp=custom_model_loglike)


with MC_model:
    start = time.time()
    # vars_list = list(MC_model.values_to_rvs.keys())[:]
    # step = pm.Metropolis()      # kind of MCMC random walk algorithm. 
    # step = pm.Slice()           # kind of MCMC random walk algorithm.
    step = pm.DEMetropolisZ()     # kind of MCMC random walk algorithm.
    trace = pm.sample(50000, step=step, tune=2000)  # samples #50 000 takes ~20h
    end = time.time()
    print('Time taken: ', end - start)

az.summary(trace)
# az.InferenceData.to_dataframe(trace)

## To save to netcdf
## !!!!!!!!!!!!!!!!!!! WARNING cahnge the name before overridding previous inference !!!!!!!
saving_name = 'full_MCMC_run_test.nc'
az.InferenceData.to_netcdf(trace, saving_name)

# trace = az.from_netcdf('trace.nc')

az.plot_trace(trace)
az.plot_pair(trace, var_names=["Cent", "Cdet", "delta_bkg"], kind='kde', marginals=True)
plt.show()

az.plot_forest(trace, var_names=["Cent"], combined=True, hdi_prob=0.95, r_hat=True, ess=True);
az.plot_forest(trace, var_names=["Cdet"], combined=True, hdi_prob=0.95, r_hat=True, ess=True);
az.plot_forest(trace, var_names=["delta_bkg"], combined=True, hdi_prob=0.95, r_hat=True, ess=True);
# az.plot_forest(trace, var_names=["likelihood"], combined=True, hdi_prob=0.95, r_hat=True, ess=True);

plt.show()

az.plot_autocorr(trace, var_names=["Cent", "Cdet", "delta_bkg", "likelihood"])
plt.show()

az.plot_pair(trace, var_names=["Cent", "Cdet", "delta_bkg"], kind='kde', marginals=True)
plt.show()
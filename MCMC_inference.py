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


def log_likelihood(Cent, Cdet, delta_bkg):
    # print(Cent, Cdet, delta_bkg)
    like = likelihood_mesonh(Cent=Cent, Cdet=Cdet, delta_bkg=delta_bkg)
    # print(like)
    return np.log(np.asarray(like))

log_likelihood(0.5, 1.5, 1.0)

class LogLike(Op):
    def make_node(self, Cent, Cdet, delta_bkg, data) -> Apply:
        # Convert inputs to tensor variables
        Cent = pt.as_tensor(Cent)
        Cdet = pt.as_tensor(Cdet)
        delta_bkg = pt.as_tensor(delta_bkg)
        data = pt.as_tensor(data)    #keep this empty

        inputs = [Cent, Cdet, delta_bkg, data]
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
        Cent, Cdet, delta_bkg, data = inputs  # this will contain my variables

        # call our numpy log-likelihood function
        loglike_eval = log_likelihood(Cent, Cdet, delta_bkg)

        # Save the result in the outputs list provided by PyTensor
        # There is one list per output, each containing another list
        # pre-populated with a `None` where the result should be saved.
        outputs[0][0] = np.asarray(loglike_eval)

loglike_op = LogLike()

_test_like = loglike_op(0.5, 1.5, 1.0, 1.0)
pytensor.dprint(_test_like, print_type=True)
_test_like.eval()

def custom_model_loglike(data, Cent, Cdet, delta_bkg):
    return loglike_op(Cent, Cdet, delta_bkg, data)

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



with MC_model:
    # Defining the prior
    Cent = pm.Uniform('Cent', lower=0, upper=1)
    Cdet = pm.Uniform('Cdet', lower=1, upper=2)
    # wp_a = pm.Uniform('wp_a', lower=0, upper=1)
    # wp_b = pm.Uniform('wp_b', lower=0, upper=1)
    # wp_bp = pm.Uniform('wp_bp', lower=0, upper=10)
    # up_c = pm.Uniform('up_c', lower=0, upper=1)
    # bc_ap = pm.Uniform('bc_ap', lower=0, upper=1)
    delta_bkg = pm.Uniform('delta_bkg', lower=0, upper=10)

    ## Define the likelihood
    pm.CustomDist('likelihood', Cent, Cdet, delta_bkg, logp=custom_model_loglike)


with MC_model:
    start = time.time()
    step = pm.Metropolis()      # kind of MCMC random walk algorithm. 
    trace = pm.sample(1000, step=step, tune=200)  # samples
    end = time.time()
    print('Time taken: ', end - start)

az.summary(trace)

az.plot_trace(trace)
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
#from julia.api import Julia
from juliacall import Main as jl
# from juliacall import Py
#jl = Julia(compiled_modules=False)
from likelihood_mesonh import likelihood_mesonh
import time
from multiprocess import Pool
import numpy as np
from copy import deepcopy

#monitor duration of execution 
start = time.time()



## install/update Julia packages
# jl.seval("using Pkg")
# jl.seval("Pkg.update()")
# jl.seval("""Pkg.add(url="https://github.com/benjione/SequentialMeasureTransport.jl.git")""")
# jl.seval("""Pkg.add("ApproxFun")""")
# jl.seval("""Pkg.add("Hypatia")""")

## import Julia packages
jl.seval("using SequentialMeasureTransport")
jl.seval("import SequentialMeasureTransport as SMT")
jl.seval("using ApproxFun")
# jl.seval("using Hypatia")

#from julia import Main

## Determine parameter ranges
#likelihood  = lambda x: likelihood_mesonh(Cent=x[0], Cdet=x[1], wp_a=x[2], wp_b=x[3], wp_bp=x[4], up_c=x[5], bc_ap=x[6], delta_bkg=x[7])
#likelihood2 = lambda x: likelihood_mesonh(Cent=x[0], Cdet=x[1], wp_bp=x[2], delta_bkg=x[3], wp_a=x[4],nan_file='nan_parameters_likelihood2_N2000_L4_phi50.txt')
likelihood3 = lambda x: likelihood_mesonh(Cent=x[0], delta_bkg=x[1], wp_a=x[2],nan_file='nan_parameters_likelihood3_N30_L10_phi50.txt')

start_l = time.time()
likelihood3([0.5, 0.5, 0.5])
stop_l = time.time()
print('duration of execution', stop_l-start_l)

def likelihood_broadcast(X):
    # return map(likelihood3, X)
    ret = []
    X = deepcopy(np.array(X))
    
    with Pool() as p:
        ret =  p.map(likelihood3, X)
    return ret

start_l = time.time()
likelihood_broadcast([[0.5, 0.5, 0.5], [0.5, 0.5, 0.5], [0.5, 0.5, 0.5], [0.5, 0.5, 0.5], [0.5, 0.5, 0.5]])
stop_l = time.time()
print('duration of execution', stop_l-start_l)


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



# create everything needed for the model
jl.seval("""
# L = [0.1, 1.1,  0.1,  0.1,  210*0.005,   0.1,  0.1,    210*0.0025] # lower bounds of parameters
# R = [0.9, 1.9,  0.9,  0.9,  390*0.005,   0.9,   0.9,   390*0.0025] # upper bounds of parameters
# L = [0.0, 1.00001, 300*0.0001, 300*0.0001, 0] # lower bounds of parameters
# R = [0.999, 1.999, 300*0.01  , 300*0.01  , 0.99] # upper bounds of parameters
L = [0.0,   300*0.0001, 0] # lower bounds of parameters
R = [0.999, 300*0.01  , 0.99] # upper bounds of parameters
N = length(L)
reference_map = SMT.ScalingReference{N}(L, R)
model = PSDModel(Legendre(0.0..1.0)^(N), :downward_closed, 5, max_Φ_size=50) #50 default
""")
#jl.likelihood = likelihood        # set the likelihood function in Julia
jl.likelihood3 = likelihood3        # set the likelihood function in Julia
jl.likelihood_broadcast = likelihood_broadcast        # set the likelihood function in Julia
#jl.seval("likelihood_func(x) = pyconvert(Float64, likelihood(x))")  # make pyobject a function in Julia (not threadsafe!!)
#jl.seval("likelihood_func2(x) = pyconvert(Float64, likelihood2(x))")  # make pyobject a function in Julia (not threadsafe!!)
jl.seval("likelihood_func3(x) = pyconvert(Float64, likelihood3(x))")  # make pyobject a function in Julia (not threadsafe!!)
jl.seval("likelihood_broadcast_func(x) = pyconvert(Vector{Float64}, likelihood_broadcast(x))")  # make pyobject a function in Julia (not threadsafe!!)

jl.seval("likelihood3([0.5, 0.5, 0.5])")

jl.seval("ret_val = likelihood_broadcast_func([[0.5, 0.5, 0.5], [0.5, 0.5, 0.5], [0.5, 0.5, 0.5]])")
## create the sampler
sra_sampler = jl.seval("""
adaptive_struct = SMT.AdaptiveSamplingStruct{Float64, N}(0.02, 0.975;
                    Nmax=20000, addmax=2000)

custom_fit!(model, X, Y, g; kwargs...) = SMT._adaptive_CV_α_divergence_Manopt!(model, 2.0, 
                X, Y, g, adaptive_struct; trace=true, 
                    maxit=2000, adaptive_sample_steps=20, broadcasted_target=true, threading=false)

sra_chi2 = SMT.SelfReinforcedSampler(likelihood_broadcast_func, 
                        model, 
                        3,              #L, number of layers
                        :adaptive,          #loss function to build approximation
                        reference_map; 
                        trace=true,
                        custom_fit=custom_fit!, #custom fit function 
                        λ_2=0.0, # controls the regularization, test 1e-4
                        λ_1=0.0, # controls the regularization
                        algebraic_base=1.2, #tempering coefficient are beta = 1/(algebraic_base)^{L - layer index}
                        N_sample=300, #at least 2000 for 4 parameters
                        threading=false,  # threading can not be used with pyobject function
                       broadcasted_tar_pdf=true,
                        # optimizer=Hypatia.Optimizer
                    )
""")

#save the sampler
jl.seval("""SMT.save_sampler(sra_chi2, "sampler_likelihood_adaptive_sampling_3L.jld2" )""")

stop = time.time()
print('duration of execution', stop-start)




# ## start generating samples or etc.
# from juliacall import Base
# import numpy as np

# sample = Base.rand(sra_sampler, 100)

# import os
# import pickle
# from juliacall import Main as jl

# # Define the filename for the serialized sampler
# sampler_file = "sampler.pkl"

# # Serialize the sra_sampler object and save it to a file
# with open(sampler_file, "wb") as f:
#     pickle.dump(sra_sampler, f)

# # Move the serialized file to Julia's working directory
# jl.eval("""using Serialization""")
# jl.eval(f"""sampler_file = "{sampler_file}" """)
# jl.eval("""sra_sampler = pickle.load(open(sampler_file, "rb"))""")









# jl.seval("""Pkg.add("StatsPlots")""")
# jl.seval("using StatsPlots")
# jl.seval("cornerplot(sample)")

# jl.cornerplot(sample)

# #TODO: j'ai l'impression qu'on remet une erreur si on doit resampler puis recalculer les stat à partir du sample ?

# # jl.seval("""Pkg.add("Distributions")""")

# # jl.seval("using Distributions")

# # jl.seval("pdf(sra_sampler,[0.,0.,0.,0.])")

# # pdf_func = jl.seval("f(x)=pdf(sra_sampler,x)")

# # pdf_func([0.,0.,0.,0.])

# sample_py = np.array(sample)

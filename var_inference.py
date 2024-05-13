#from julia.api import Julia
from juliacall import Main as jl
#jl = Julia(compiled_modules=False)
from likelihood_mesonh import likelihood_mesonh
import time

#monitor duration of execution 
start = time.time()



## install Julia packages
# jl.seval("using Pkg")
# jl.seval("""Pkg.add(url="https://github.com/benjione/SequentialMeasureTransport.jl.git")""")
# jl.seval("""Pkg.add("ApproxFun")""")
# jl.seval("""Pkg.add("Hypatia")""")

## import Julia packages
jl.seval("using SequentialMeasureTransport")
jl.seval("import SequentialMeasureTransport as SMT")
jl.seval("using ApproxFun")
jl.seval("using Hypatia")
#from julia import Main

## Determine parameter ranges
#likelihood  = lambda x: likelihood_mesonh(Cent=x[0], Cdet=x[1], wp_a=x[2], wp_b=x[3], wp_bp=x[4], up_c=x[5], bc_ap=x[6], delta_bkg=x[7])
likelihood2 = lambda x: likelihood_mesonh(Cent=x[0], Cdet=x[1], wp_bp=x[2], delta_bkg=x[3], wp_a=x[4],nan_file='nan_parameters_likelihood2_N2000_L4_phi50.txt')


# create everything needed for the model
jl.seval("""
# L = [0.1, 1.1,  0.1,  0.1,  210*0.005,   0.1,  0.1,    210*0.0025] # lower bounds of parameters
# R = [0.9, 1.9,  0.9,  0.9,  390*0.005,   0.9,   0.9,   390*0.0025] # upper bounds of parameters
L = [0.0, 1.00001, 300*0.0001, 300*0.0001, 0] # lower bounds of parameters
R = [0.999, 1.999, 300*0.01  , 300*0.01  , 0.99] # upper bounds of parameters
N = length(L)
reference_map = SMT.ScalingReference{N}(L, R)
model = PSDModel(Legendre(0.0..1.0)^(N), :downward_closed, 5, max_Φ_size=50) #50 default
""")
#jl.likelihood = likelihood        # set the likelihood function in Julia
jl.likelihood2 = likelihood2        # set the likelihood function in Julia
#jl.seval("likelihood_func(x) = pyconvert(Float64, likelihood(x))")  # make pyobject a function in Julia (not threadsafe!!)
jl.seval("likelihood_func2(x) = pyconvert(Float64, likelihood2(x))")  # make pyobject a function in Julia (not threadsafe!!)
## create the sampler
sra_sampler = jl.seval("""
sra_chi2 = SMT.SelfReinforcedSampler(likelihood_func2, 
                        model, 
                        4,              #L, number of layers
                        :Chi2,          #loss function to build approximation
                        reference_map; 
                        trace=true,
                        ϵ=1e-6, λ_2=0.0, λ_1=0.0,
                        algebraic_base=2.0, #tempering coefficient are beta = 1/(algebraic_base)^{L - layer index}
                        N_sample=2000, #at least 2000 for 4 parameters
                        threading=false,  # threading can not be used with pyobject function
                        # optimizer=Hypatia.Optimizer
                    )
""")

#save the sampler
jl.seval("""SMT.save_sampler(sra_chi2, "sampler_likelihood2_N2000_L4_phi50.jld2" )""")

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

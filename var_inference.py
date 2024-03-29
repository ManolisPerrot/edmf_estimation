#from julia.api import Julia
from juliacall import Main as jl
#jl = Julia(compiled_modules=False)

from likelihood_mesonh import likelihood_mesonh
import time

## install Julia packages
jl.seval("using Pkg")
jl.seval("""Pkg.add(url="https://github.com/benjione/SequentialMeasureTransport.jl.git")""")
jl.seval("""Pkg.add("ApproxFun")""")
jl.seval("""Pkg.add("Hypatia")""")

## import Julia packages
jl.seval("using SequentialMeasureTransport")
jl.seval("import SequentialMeasureTransport as SMT")
jl.seval("using ApproxFun")
jl.seval("using Hypatia")
#from julia import Main

## Determine parameter ranges
likelihood = lambda x: likelihood_mesonh(Cent=x[0], Cdet=x[1], wp_a=x[2], wp_b=x[3], wp_bp=x[4], up_c=x[5], bc_ap=x[6], delta_bkg=x[7])
likelihood2 = lambda x: likelihood_mesonh(Cent=x[0], wp_a=x[1], wp_b=x[2], up_c=x[3], bc_ap=x[4])


# create everything needed for the model
jl.seval("""
# L = [0.1, 1.1,  0.1,  0.1,  210*0.005,   0.1,  0.1,    210*0.0025] # lower bounds of parameters
# R = [0.9, 1.9,  0.9,  0.9,  390*0.005,   0.9,   0.9,   390*0.0025] # upper bounds of parameters
L = [0.0, 0, 0, 0] # lower bounds of parameters
R = [1.0, 1, 0.9, 0.3] # upper bounds of parameters
N = length(L)
reference_map = SMT.ScalingReference{N}(L, R)
model = PSDModel(Legendre(0.0..1.0)^(N), :downward_closed, 5, max_Φ_size=50)
""")
jl.likelihood = likelihood        # set the likelihood function in Julia
jl.likelihood2 = likelihood2        # set the likelihood function in Julia
jl.seval("likelihood_func(x) = pyconvert(Float64, likelihood(x))")  # make pyobject a function in Julia (not threadsafe!!)
jl.seval("likelihood_func2(x) = pyconvert(Float64, likelihood2(x))")  # make pyobject a function in Julia (not threadsafe!!)
## create the sampler
sra_sampler = jl.seval("""
sra_chi2 = SMT.SelfReinforcedSampler(likelihood_func2, model, 4, :Chi2,
                        reference_map; trace=true,
                        ϵ=1e-6, λ_2=0.0, λ_1=0.0,
                        algebraic_base=2.0,
                        N_sample=100,
                        threading=false,  # threading can not be used with pyobject function
                        # optimizer=Hypatia.Optimizer
                    )
""")

## start generating samples or etc.
from julia import Base
Base.rand(sra_sampler, 10)
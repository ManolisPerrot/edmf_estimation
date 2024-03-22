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

# create everything needed for the model
jl.seval("""
L = [0.0, 1, 0, 0, 0, 0, 0, 0] # lower bounds of parameters
R = [1.0, 2, 1, 1, 10, 1, 1, 10] # upper bounds of parameters
N = 8
reference_map = SMT.ScalingReference{N}(L, R)
model = PSDModel(Legendre(0.0..1.0)^(N), :downward_closed, 5, max_Φ_size=50)
""")
jl.likelihood = likelihood        # set the likelihood function in Julia
jl.seval("likelihood_func(x) = Float64(1000.0*likelihood(x))")  # make pyobject a function in Julia (not threadsafe!!)
## create the sampler
sra_sampler = jl.seval("""
sra_chi2 = SMT.SelfReinforcedSampler(likelihood_func, model, 4, :Chi2,
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
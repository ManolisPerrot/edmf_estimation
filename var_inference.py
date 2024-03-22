from julia.api import Julia
jl = Julia(compiled_modules=False)

from likelihood_mesonh import likelihood_mesonh
import time

## install Julia packages
jl.eval("using Pkg")
jl.eval("""Pkg.add(url="https://github.com/benjione/SequentialMeasureTransport.jl.git")""")
jl.eval("""Pkg.add("ApproxFun")""")
jl.eval("""Pkg.add("Hypatia")""")

## import Julia packages
jl.eval("using SequentialMeasureTransport")
jl.eval("import SequentialMeasureTransport as SMT")
jl.eval("using ApproxFun")
jl.eval("using Hypatia")
from julia import Main

## Determine parameter ranges
likelihood = lambda x: likelihood_mesonh(Cent=x[0], Cdet=x[1], wp_a=x[2], wp_b=x[3], wp_bp=x[4], up_c=x[5], bc_ap=x[6], delta_bkg=x[7])

# create everything needed for the model
jl.eval("""
L = zeros(8) # lower bounds of parameters
R = ones(8) # upper bounds of parameters
N = 8
reference_map = SMT.ScalingReference{N}(L, R)
model = PSDModel(Legendre(0.0..1.0)^(N), :downward_closed, 5, max_Φ_size=50)
""")
Main.likelihood = likelihood        # set the likelihood function in Julia
jl.eval("likelihood_func(x) = 1000.0*likelihood(x)")  # make pyobject a function in Julia (not threadsafe!!)
## create the sampler
sra_sampler = jl.eval("""
sra_chi2 = SMT.SelfReinforcedSampler(likelihood_func, model, 4, :Chi2,
                        reference_map; trace=true,
                        ϵ=1e-6, λ_2=0.0, λ_1=0.0,
                        algebraic_base=2.0,
                        N_sample=10000,
                        threading=false,  # threading can not be used with pyobject function
                        # optimizer=Hypatia.Optimizer
                    )
""")

## start generating samples or etc.
from julia import Base
Base.rand(sra_sampler, 10)
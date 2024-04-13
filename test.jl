from juliacall import Main as jl
import numpy as np
jl.seval("""using SequentialMeasureTransport""")
jl.seval("""import SequentialMeasureTransport as SMT""")
jl.seval("""using Distributions""")
jl.seval("""using PyCall""")


# Load sampler and sample
jl.seval("""sampler = SMT.load_sampler("smp.jld2")""")
jl.seval("""sample = rand(sampler, 100) #10 000 samples""")
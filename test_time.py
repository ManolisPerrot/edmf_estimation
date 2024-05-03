import time

#monitor duration of execution 
start = time.time()





stop = time.time()
print('duration of execution', (stop-start)/3600, 'hours')

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

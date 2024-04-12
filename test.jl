using Serialization
using Random

# Load the serialized sampler from the file
sampler_file = "sampler.jls"
sra_sampler = deserialize(sampler_file)

# Seed the default random number generator
Random.seed!(1234)

# Sample from the loaded sampler
sample = rand(sra_sampler, 100)

# Now you can use the sampled values as needed

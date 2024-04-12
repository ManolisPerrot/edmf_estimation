using SequentialMeasureTransport
import SequentialMeasureTransport as SMT
using Distributions

sampler = SMT.load_sampler("smp.jld2")

# evaluate directly the pdf from sampler
pdf(sampler, rand(5))

# Sample from the loaded sampler
sample = rand(sampler, 100) #10 000 samples
sample 

using StatsPlots
# hcat transforms a vector of vector to matrix
cornerplot(hcat(sample...))


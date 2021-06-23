using GeometricFlux
using Flux
using Zygote
using CUDA

Flux.@functor GeometricFlux.FeaturedGraph

include("cuda/cuda.jl")
include("representation/representation.jl")
include("nn_structures/nn_structures.jl")
include("utils.jl")

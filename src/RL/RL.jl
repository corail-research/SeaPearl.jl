using Flux
using Zygote
using CUDA

# TODO replace FeaturedGraph
Flux.@functor FeaturedGraph

include("cuda/cuda.jl")
include("representation/representation.jl")
include("nn_structures/nn_structures.jl")
include("utils.jl")

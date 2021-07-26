using Flux
using Zygote
using CUDA

include("utils/utils.jl")
include("cuda/cuda.jl")
include("representation/representation.jl")
include("nn_structures/nn_structures.jl")

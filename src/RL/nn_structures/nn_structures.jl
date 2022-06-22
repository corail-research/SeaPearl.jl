using Flux
using Zygote
using CUDA

abstract type NNStructure end

"""
    (nn::NNStructure)(x::AbstractArray{Float32,3})

Make NNStructure able to work with batches.
"""
(nn::NNStructure)(ts::AbstractTrajectoryState) = throw(ErrorException("missing function (::$(typeof(nn)))(::$(typeof(ts)))."))
function (nn::NNStructure)(x::AbstractVector{<:TabularTrajectoryState})
    batch_size = size(x, 3)
    qval = [nn(x[:, :, i]) for i in 1:batch_size]
    hcat(qval...)
end

function (nn::NNStructure)(x::AbstractVector{<:NonTabularTrajectoryState})
    qval = nn.(x)
    return hcat(qval...)
end

include("cpnn.jl")
include("heterogeneouscpnn.jl")
include("heterogeneousvariableoutputcpnn.jl")
include("heterogeneousfullfeaturedcpnn.jl")
include("heterogeneousfullfeaturedcpnnv2.jl")
include("heterogeneousfullfeaturedcpnnv3.jl")
include("heterogeneousfullfeaturedcpnnv4.jl")
include("fullfeaturedcpnn.jl")
include("variableoutputcpnn.jl")

struct ModelNotImplementedError{M} <: Exception
    m::M
    ModelNotImplementedError(m::M) where {M} = new{M}(m)
end

Base.showerror(io::IO, ie::ModelNotImplementedError) = print(io, "Model $(ie.m) not implemented.")

wears_mask(structure::NNStructure) = true
wears_mask(structure) = true # For simpler structures like Flux.Chain


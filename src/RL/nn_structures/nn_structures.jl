using Flux

abstract type NNStructure end

"""
    (nn::NNStructure)(x::AbstractArray{Float32,3})

Make NNStructure able to work with batches.
"""
function (nn::NNStructure)(x::AbstractArray{Float32,3})
    batch_size = size(x)[end]
    qval = [nn(x[:, :, i]) for i in 1:batch_size]
    hcat(qval...)
end

include("flexGNN.jl")
include("flex_variable_output_gnn.jl")

abstract type NNArgs end

struct ModelNotImplementedError{M} <: Exception
    m::M
    ModelNotImplementedError(m::M) where {M} = new{M}(m)
end

Base.showerror(io::IO, ie::ModelNotImplementedError) = print(io, "Model $(ie.m) not implemented.")

function build_model(structure::Type{T}, args::NNArgs) where {T <: NNStructure}
    throw(ModelNotImplementedError(T))
end

wears_mask(structure::NNStructure) = true
wears_mask(structure) = true # For simpler structures like Flux.Chain

include("fixed_output_gcn.jl")
include("fixed_output_gat.jl")
include("variable_output_gcn_lstm.jl")

include("weighted_graph_gat.jl")
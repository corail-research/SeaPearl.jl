using Flux

abstract type NNStructure end
abstract type NNArgs end

struct ModelNotImplementedError{M} <: Exception
    m::M
    ModelNotImplementedError(m::M) where {M} = new{M}(m)
end

Base.showerror(io::IO, ie::ModelNotImplementedError) = print(io, "Model $(ie.m) not implemented.")

function build_model(structure::Type{T}, args::NNArgs) where {T <: NNStructure}
    throw(ModelNotImplementedError(T))
end

include("fixed_output_gcn.jl")
include("fixed_output_gcn_lstm.jl")
include("fixed_output_gat.jl")
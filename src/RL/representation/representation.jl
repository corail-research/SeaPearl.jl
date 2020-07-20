
abstract type AbstractStateRepresentation end 


abstract type AbstractFeaturization end
abstract type FeaturizedStateRepresentation{F} <: AbstractStateRepresentation end

function featurize(::FeaturizedStateRepresentation{F}) where F <: AbstractFeaturization
    throw(ErrorException("Featurization $(F) not implemented."))
    nothing
end

include("default/cp_layer/cp_layer.jl")

include("default/defaultstaterepresentation.jl")
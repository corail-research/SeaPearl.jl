export CPGraphSpace

mutable struct CPGraph
    featuredgraph::GFlux.FeaturedGraph
    variable_id::Int64
end

"""
    CPGraphSpace(graphtype::Int64, featuretype::DataType, variable_id_low::Int64, variable_id_high::Int64)

This characterises all the CPGraph's that can be encountered. 
"""
struct CPGraphSpace <: RL.AbstractSpace
    graphtype::Int64
    featuretype::DataType
    variable_id_low::Int64
    variable_id_high::Int64

    function CPGraphSpace(graphtype::Int64, featuretype::DataType, variable_id_low::Int64, variable_id_high::Int64)
        variable_id_high >= variable_id_low || throw(ArgumentError("$variable_id_high must be >= $variable_id_low"))
        new(graphtype, featuretype, variable_id_low, variable_id_high)
    end
end

"""
    CPGraphSpace(variable_id_high::Int64)
Create a `CPGraphSpace` with span of `1:high`
"""
CPGraphSpace(graphtype::Int64, featuretype::DataType, variable_id_high::Int64) = CPGraphSpace(graphtype, featuretype, 1, variable_id_high)


Base.eltype(s::CPGraphSpace) = s.featuretype

"""
    Base.in(x, s::CPGraphSpace)::Bool

Test if 
"""
function Base.in(x, s::CPGraphSpace)::Bool
    propertynames(x) == (:featuredgraph, :variable_id) && typeof(x.featuredgraph) == GFlux.FeaturedGraph && typeof(x.featuredgraph.feature) == s.featuretype && true && s.variable_id_low <= x.variable_id <= s.variable_id_high
end 

function Random.rand(rng::AbstractRNG, s::CPGraphSpace)

    rand(rng, s.span)
end 

Base.length(s::DiscreteSpace) = length(s.span)
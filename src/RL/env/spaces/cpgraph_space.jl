using LinearAlgebra

export CPGraphSpace

mutable struct CPGraph
    featuredgraph::GeometricFlux.FeaturedGraph
    variable_id::Int64
end

"""
    CPGraph(cplayergraph::CPLayerGraph, x::AbstractIntVar)

Construct a CPGraph from the CPLayerGraph and the variable we want to branch on. 
Here we will define how the node feature will look like. Thus, it might be transformed later.
"""
function CPGraph(g::CPLayerGraph, x::AbstractIntVar)
    graph = LightGraphs.LinAlg.adjacency_matrix(g)
    # temporary use of a one hot encoder for each node. 
    feature = Matrix{Float32}(I, nv(g), nv(g))
    variable_id = index(g, VariableVertex(x))
    
    CPGraph(GeometricFlux.FeaturedGraph(graph, feature), variable_id)
end

"""
    CPGraphSpace(variable_id_low::Int64, variable_id_high::Int64, featuretype::Type{Number})

This characterises all the CPGraph's that can be encountered. 
"""
struct CPGraphSpace <: RL.AbstractSpace
    variable_id_low::Int64
    variable_id_high::Int64

    function CPGraphSpace(variable_id_low::Int64, variable_id_high::Int64)
        variable_id_high >= variable_id_low || throw(ArgumentError("$variable_id_high must be >= $variable_id_low"))
        new(variable_id_low, variable_id_high)
    end
end

"""
    CPGraphSpace(variable_id_high::Int64, featuretype::Type{Number})

Create a `CPGraphSpace` with span of `1:high`.
"""
CPGraphSpace(variable_id_high::Int64) = CPGraphSpace(1, variable_id_high)


Base.eltype(s::CPGraphSpace) = CPGraph

"""
    Base.in(x, s::CPGraphSpace)::Bool

Test if x is a CPGraph
"""
function Base.in(x, s::CPGraphSpace)::Bool
    propertynames(x) == (:featuredgraph, :variable_id) && typeof(x.featuredgraph) == GeometricFlux.FeaturedGraph && s.variable_id_low <= x.variable_id <= s.variable_id_high
end 

function Random.rand(rng::AbstractRNG, s::CPGraphSpace)
    g = CPLayerGraph()
    graph = LightGraphs.LinAlg.adjacency_matrix(g)
    # temporary use of a one hot encoder for each node. 
    feature = Matrix{Float32}(I, nv(g), nv(g))

    variable_id = 1
    
    CPGraph(GeometricFlux.FeaturedGraph(graph, feature), variable_id)
end

Base.length(s::CPGraphSpace) = error("CPGraphSpace is uncountable")
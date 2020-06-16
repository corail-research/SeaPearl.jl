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
    sparse_adj = LightGraphs.LinAlg.adjacency_matrix(g)
    # temporary use of a one hot encoder for each node. 
    feature = Matrix{Float32}(I, nv(g), nv(g))
    variable_id = index(g, VariableVertex(x))
    
    CPGraph(GeometricFlux.FeaturedGraph(g, feature), variable_id)
end

"""
    CPGraph(cplayergraph::CPLayerGraph, var_id::Int64)

Construct a CPGraph from the CPLayerGraph and the variable we want to branch on. 
Here we will define how the node feature will look like. Thus, it might be transformed later.
"""
function CPGraph(g::CPLayerGraph, var_id::Int64)
    sparse_adj = LightGraphs.LinAlg.adjacency_matrix(g)
    # temporary use of a one hot encoder for each node. 
    feature = Matrix{Float32}(I, nv(g), nv(g))
    
    CPGraph(GeometricFlux.FeaturedGraph(g, feature), var_id)
end

"""
    update!(cpgraph::CPGraph, g::CPLayerGraph, x::AbstractIntVar)

Update a CPGraph instance thanks to a new CPLayerGraph and a new Variable. 
The only thing that stay identic is basically the feature matrix.

---------- WARNING : 
At the moment, we are using GeometricFlux.FeaturedGraph, which is immutable, so
we could change the pointer ref or change elements after elements in the sparse 
adjacency matrix. But in order to get the things done quickly, we will start by ignoring 
the update!() function and we will create a new FeaturedGraph when we want to update
CPGraph.
"""
function update!(cpgraph::CPGraph, g::CPLayerGraph, x::AbstractIntVar)
    cpgraph.variable_id = index(cpgraph.featuredgraph.graph[], VariableVertex(x))

    # feature = cpgraph.featuredgraph.feature[]
    # sparse_adj = LightGraphs.LinAlg.adjacency_matrix(cpgraph)

    # cpgraph.featuredgraph = GeometricFlux.FeaturedGraph(sparse_adj, feature)
    nothing
end

RL.get_state(cpg::CPGraph) = cpg

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
CPGraphSpace(variable_id_high::Int64) = CPGraphSpace(0, variable_id_high)


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
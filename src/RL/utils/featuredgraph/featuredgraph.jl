mutable struct FeaturedGraph{T <: AbstractMatrix, N <: AbstractMatrix, E <: AbstractArray, G <: AbstractVector} <: AbstractFeaturedGraph
    graph::T
    nf::N
    ef::E
    gf::G
    directed::Bool
    
    function FeaturedGraph(graph::T, nf::N, ef::E, gf::G, directed::Bool) where {T <: AbstractMatrix, N <: AbstractMatrix, E <: AbstractArray, G <: AbstractVector}
        check_dimensions(graph, nf, ef, gf)
        return new{T,N,E,G}(graph, nf, ef, gf, directed)
    end

    function FeaturedGraph{T, N, E, G}(graph::AbstractArray, nf::AbstractArray, ef::AbstractArray, gf::AbstractArray, directed) where {T <: AbstractMatrix, N <: AbstractMatrix, E <: AbstractArray, G <: AbstractVector}
        check_dimensions(graph, nf, ef, gf)
        return new{T, N, E, G}(graph, nf, ef, gf, directed)
    end
end

function FeaturedGraph(graph::AbstractMatrix; directed::Symbol=:auto, n=size(graph, 1), nf=zeros(0,n), ef=zeros(0,n,n), gf=zeros(0))
    @assert directed ∈ [:auto, :directed, :undirected] "Unknown value for keyword directed."
    dir = directed == :auto ? transpose(graph) != graph : directed == :directed
    return FeaturedGraph(graph, nf, ef, gf, dir)
end

function FeaturedGraph(graph::AbstractGraph; kwargs...)
    return FeaturedGraph(Matrix(adjacency_matrix(graph)); kwargs...)
end


# ========== Accessing ==========
# code from GraphSignals.jl

"""
    graph(::FeaturedGraph)
Get referenced graph.
"""
graph(fg::FeaturedGraph) = fg.graph

"""
    node_feature(::FeaturedGraph)
Get node feature attached to graph.
"""
node_feature(fg::FeaturedGraph) = fg.nf

"""
    edge_feature(::FeaturedGraph)
Get edge feature attached to graph.
"""
edge_feature(fg::FeaturedGraph) = fg.ef

"""
    global_feature(::FeaturedGraph)
Get global feature attached to graph.
"""
global_feature(fg::FeaturedGraph) = fg.gf

"""
    has_graph(::FeaturedGraph)
Check if graph is available or not.
"""
has_graph(fg::FeaturedGraph) = fg.graph != zeros(0,0)

"""
    has_node_feature(::FeaturedGraph)
Check if node feature is available or not.
"""
has_node_feature(fg::FeaturedGraph) = !isempty(fg.nf)

"""
    has_edge_feature(::FeaturedGraph)
Check if edge feature is available or not.
"""
has_edge_feature(fg::FeaturedGraph) = !isempty(fg.ef)

"""
    has_global_feature(::FeaturedGraph)
Check if global feature is available or not.
"""
has_global_feature(fg::FeaturedGraph) = !isempty(fg.gf)


# ========== LightGraphs compatibility ==========

LightGraphs.nv(fg::FeaturedGraph) = LightGraphs.nv(graph(fg))
LightGraphs.nv(g::AbstractMatrix) = size(g,1)
LightGraphs.ne(fg::FeaturedGraph) = LightGraphs.ne(graph(fg))
LightGraphs.ne(g::AbstractMatrix) = LightGraphs.ne(LightGraphs.Graph(g))
LightGraphs.degree(fg::FeaturedGraph) = degree(graph(fg))

Flux.@functor FeaturedGraph

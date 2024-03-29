
"""
BatchedFeaturedGraph

A batched representation of the FeaturedGraph, to enable parallel computation.

It is deliberately more restrictive to prevent incorrect usage.
"""
struct BatchedFeaturedGraph{T <: Real} <: AbstractFeaturedGraph
    graph::AbstractArray{Int64, 3}
    nf::AbstractArray{T, 3}
    ef::AbstractArray{T, 4}
    gf::AbstractMatrix{T}

    function BatchedFeaturedGraph{T}(graph, nf, ef, gf) where T <: Real
        check_dimensions(graph, nf, ef, gf)
        return new{T}(graph, nf, ef, gf)
    end

    function BatchedFeaturedGraph{T}(
        graph; 
        nf=zeros(0, size(graph, 1), size(graph, 3)), 
        ef=zeros(0, size(graph, 1), size(graph, 1), size(graph, 3)), 
        gf=zeros(0, size(graph, 3))
    ) where T <: Real
        check_dimensions(graph, nf, ef, gf)
        return new{T}(graph, nf, ef, gf)
    end
end

BatchedFeaturedGraph(graph, nf, ef, gf) = BatchedFeaturedGraph{Float32}(graph, nf, ef, gf)

function BatchedFeaturedGraph{T}(fgs::Vector{FG}) where {T <: Real, FG <: FeaturedGraph}
    ngraphs = length(fgs)
    maxNodes = Base.maximum(LightGraphs.nv, fgs)
    nfLength = size(fgs[1].nf, 1)
    efLength = size(fgs[1].ef, 1)
    gfLength = size(fgs[1].gf, 1)

    graph = zeros(Int64, maxNodes, maxNodes, ngraphs)
    nf = zeros(T, nfLength, maxNodes, ngraphs)
    ef = zeros(T, efLength, maxNodes, maxNodes, ngraphs)
    gf = zeros(T, gfLength, ngraphs)

    for (i, fg) in enumerate(fgs)
        graph[1:LightGraphs.nv(fg),1:LightGraphs.nv(fg),i] = fg.graph
        nf[:, 1:LightGraphs.nv(fg), i] = fg.nf
        ef[:, 1:LightGraphs.nv(fg), 1:LightGraphs.nv(fg), i] = fg.ef
        gf[:, i] = fg.gf
    end

    return BatchedFeaturedGraph{T}(graph, nf, ef, gf)
end

BatchedFeaturedGraph(fgs::Vector{FG}) where {FG <: FeaturedGraph} = BatchedFeaturedGraph{Float32}(fgs)

# ========== Accessing ==========
# code from GraphSignals.jl

"""
    graph(::BatchedFeaturedGraph)
Get referenced graph.
"""
graph(fgs::BatchedFeaturedGraph) = fgs.graph

"""
    node_feature(::BatchedFeaturedGraph)
Get node feature attached to graph.
"""
node_feature(fgs::BatchedFeaturedGraph) = fgs.nf

"""
    edge_feature(::BatchedFeaturedGraph)
Get edge feature attached to graph.
"""
edge_feature(fgs::BatchedFeaturedGraph) = fgs.ef

"""
    global_feature(::BatchedFeaturedGraph)
Get global feature attached to graph.
"""
global_feature(fgs::BatchedFeaturedGraph) = fgs.gf

"""
    has_graph(::BatchedFeaturedGraph)
Check if graph is available or not.
"""
has_graph(fgs::BatchedFeaturedGraph) = fgs.graph != zeros(0,0,0)

"""
    has_node_feature(::BatchedFeaturedGraph)
Check if node feature is available or not.
"""
has_node_feature(fgs::BatchedFeaturedGraph) = !isempty(fgs.nf)

"""
    has_edge_feature(::BatchedFeaturedGraph)
Check if edge feature is available or not.
"""
has_edge_feature(fgs::BatchedFeaturedGraph) = !isempty(fgs.ef)

"""
    has_global_feature(::BatchedFeaturedGraph)
Check if global feature is available or not.
"""
has_global_feature(fgs::BatchedFeaturedGraph) = !isempty(fgs.gf)


# ========== LightGraphs compatibility ==========

LightGraphs.nv(fgs::BatchedFeaturedGraph) = LightGraphs.nv(graph(fgs))
LightGraphs.nv(g::AbstractArray{T, 3}) where T<:Real = size(g,1)

Flux.@functor BatchedFeaturedGraph
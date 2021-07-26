
"""
BatchedFeaturedGraph

A batched representation of the FeaturedGraph, to enable parallel computation.

It is deliberately more restrictive to prevent incorrect usage.
"""
struct BatchedFeaturedGraph{T <: Real} <: AbstractFeaturedGraph
    graph::AbstractArray{T, 3}
    nf::AbstractArray{T, 3}
    ef::AbstractArray{T, 4}
    gf::AbstractMatrix{T}

    function BatchedFeaturedGraph{T}(graph, nf, ef, gf) where T <: Real
        check_dimensions(graph, nf, ef, gf)
        return new{T}(graph, nf, ef, gf)
    end

    function BatchedFeaturedGraph{T}(
        graph; 
        nf=Fill(0, (0, size(graph, 1), size(graph, 3))), 
        ef=Fill(0, (0, size(graph, 1), size(graph, 1), size(graph, 3))), 
        gf=Fill(0, (0, size(graph, 3)))
    ) where T <: Real
        check_dimensions(graph, nf, ef, gf)
        return new{T}(graph, nf, ef, gf)
    end
end

BatchedFeaturedGraph(graph, nf, ef, gf) = BatchedFeaturedGraph{Float32}(graph, nf, ef, gf)

function BatchedFeaturedGraph{T}(fgs::Vector{FG}) where {T <: Real, FG <: FeaturedGraph}
    ngraphs = length(fgs)
    maxNodes = maximum(nv, fgs)
    nfLength = size(fgs[1].nf, 1)
    efLength = size(fgs[1].ef, 1)
    gfLength = size(fgs[1].gf, 1)

    graph = zeros(T, maxNodes, maxNodes, ngraphs)
    nf = zeros(T, nfLength, maxNodes, ngraphs)
    ef = zeros(T, efLength, maxNodes, maxNodes, ngraphs)
    gf = zeros(T, gfLength, ngraphs)

    for (i, fg) in enumerate(fgs)
        graph[1:nv(fg),1:nv(fg),i] = fg.graph
        nf[:, 1:nv(fg), i] = fg.nf
        ef[:, 1:nv(fg), 1:nv(fg), i] = fg.ef
        gf[:, i] = fg.gf
    end

    return BatchedFeaturedGraph{T}(graph, nf, ef, gf)
end

BatchedFeaturedGraph(fgs::Vector{FG}) where {FG <: FeaturedGraph} = BatchedFeaturedGraph{Float32}(fgs)

Flux.@functor BatchedFeaturedGraph

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

Flux.@functor BatchedFeaturedGraph
using LightGraphs
using FillArrays

abstract type AbstractFeaturedGraph end

function check_dimensions(graph::T, nf::N, ef::E, gf::G) where {T <: AbstractArray, N <: AbstractArray, E <: AbstractArray, G <: AbstractArray}
    if ndims(graph) == 2
        @assert ndims(nf) == 2 "Node feature Matrix has improper number of dimensions."
        @assert ndims(ef) == 3 "Edge feature Matrix has improper number of dimensions."
        @assert ndims(gf) == 1 "Global feature Matrix has improper number of dimensions."
    elseif ndims(graph) == 3
        @assert ndims(nf) == 3 "Node feature Matrix has improper number of dimensions."
        @assert ndims(ef) == 4 "Edge feature Matrix has improper number of dimensions."
        @assert ndims(gf) == 2 "Global feature Matrix has improper number of dimensions."

        @assert size(graph, 3) == size(nf, 3) == size(ef, 4) == size(gf, 2) "Inconsistent number of graphs accros matrices."
    end
    @assert size(graph, 1) == size(graph, 2) "Graph Matrix isn't square."
    @assert size(graph, 1) == size(nf, 2) "Node feature Matrix has incorrect number of nodes."
    @assert size(graph, 1) == size(ef, 2) == size(ef, 3) "Edge feature Matrix has incorrect number of nodes or isn't square."
end

include("featuredgraph.jl")
include("batchedfeaturedgraph.jl")

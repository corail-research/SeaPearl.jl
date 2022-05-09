using LightGraphs
using FillArrays

abstract type AbstractFeaturedGraph end

function check_dimensions(graph::T, nf::N, ef::E, gf::G) where {T<:AbstractArray,N<:AbstractArray,E<:AbstractArray,G<:AbstractArray}
    if ndims(graph) == 2
        @assert ndims(nf) == 2 "Node feature Matrix has improper number of dimensions."
        @assert ndims(ef) == 3 "Edge feature Matrix has improper number of dimensions."
        @assert ndims(gf) == 1 "Global feature Matrix has improper number of dimensions."
    elseif ndims(graph) == 3
        @assert ndims(nf) == 3 "Node feature Matrix has improper number of dimensions."
        @assert ndims(ef) == 4 "Edge feature Matrix has improper number of dimensions."
        @assert ndims(gf) == 2 "Global feature Matrix has improper number of dimensions."

        @assert size(graph, 3) == size(nf, 3) == size(ef, 4) == size(gf, 2) "Inconsistent number of graphs accross matrices."
    end
    @assert size(graph, 1) == size(graph, 2) "Graph Matrix isn't square."
    @assert size(graph, 1) == size(nf, 2) "Node feature Matrix has incorrect number of nodes."
    @assert size(graph, 1) == size(ef, 2) == size(ef, 3) "Edge feature Matrix has incorrect number of nodes or isn't square."
end

function check_dimensions(conToVar::T, valToVar::T, connf::N, varnf::N, valnf::N, ef::E, gf::G) where {T<:AbstractArray,N<:AbstractArray,E<:AbstractArray,G<:AbstractArray}
    @assert ndims(conToVar) == ndims(valToVar)
    if ndims(conToVar) == 2
        @assert ndims(connf) == 2 "Constraint Node feature Matrix has improper number of dimensions."
        @assert ndims(varnf) == 2 "Variable Node feature Matrix has improper number of dimensions."
        @assert ndims(valnf) == 2 "Value Node feature Matrix has improper number of dimensions."
        @assert ndims(ef) == 3 "Edge feature Matrix has improper number of dimensions."
        @assert ndims(gf) == 1 "Global feature Matrix has improper number of dimensions."
    elseif ndims(conToVar) == 3
        @assert ndims(connf) == 3 "Constraint Node feature Matrix has improper number of dimensions."
        @assert ndims(varnf) == 3 "Variable Node feature Matrix has improper number of dimensions."
        @assert ndims(valnf) == 3 "Value Node feature Matrix has improper number of dimensions."
        @assert ndims(ef) == 4 "Edge feature Matrix has improper number of dimensions."
        @assert ndims(gf) == 2 "Global feature Matrix has improper number of dimensions."

        @assert size(conToVar, 3) == size(valToVar) == size(connf, 3) == size(varnf, 3)== size(valnf, 3) == size(ef, 4) == size(gf, 2) "Inconsistent number of graphs accross matrices."
    end
    @assert size(conToVar, 2) == size(valToVar, 2) "The number of variable nodes is not consistent between conToVar and valToVar."
    @assert size(conToVar, 1) == size(connf, 2) "The number of constraint nodes is not consistent between conToVar and connf."
    @assert size(conToVar, 2) == size(varnf, 2) "The number of variable nodes is not consistent between conToVar and varnf."
    @assert size(valToVar, 1) == size(valnf, 2) "The number of value nodes is not consistent between valToVar and valnf"
    @assert size(valToVar, 2) == size(varnf, 2) "The number of variable nodes is not consistent between valToVar and varnf."
    @assert size(graph, 1) == size(nf, 2) "Node feature Matrix has incorrect number of nodes."
    @assert size(ef, 2) == size(ef, 3) "Edge feature Matrix isn't square."
    @assert size(ef, 2) == size(connf, 2) + size(varnf, 2) + size(valnf, 2) "The number of nodes is not consistent between the nodes features matrix and the edge features matrix."
end

include("featuredgraph.jl")
include("batchedfeaturedgraph.jl")
include("heterogeneousfeaturedgraph.jl")
include("heterogeneousbatchedfeaturedgraph.jl")

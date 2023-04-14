using FillArrays
using StatsBase:countmap

"""
    HeterogeneousTrajectoryState

The most basic state representation, with a featured graph, the index of the variable to branch on and optionnaly a list of possible values.
"""
struct HeterogeneousTrajectoryState <: GraphTrajectoryState
    fg::HeterogeneousFeaturedGraph
    variableIdx::Int
    possibleValuesIdx::Union{Nothing, Vector{Int64}}

    function HeterogeneousTrajectoryState(fg, var, val)
        @assert var <= size(fg.varnf,2) "The variable index is out of bound"
        @assert all(val .<= size(fg.valnf,2)) "One of the values index is out of bound"
        @assert all([tuple[2] for tuple in countmap([c for c in val])] .== 1) "values array contains one element at least twice"
        return new(fg, var, val)
    end
end

HeterogeneousTrajectoryState(sr::AbstractStateRepresentation) = throw(ErrorException("missing function HeterogeneousTrajectoryState(::$(typeof(sr)))."))

"""
    BatchedHeterogeneousTrajectoryState

The batched version of the `HeterogeneousTrajectoryState`.

It contains all the information that would be stored in a `HeterogeneousFeaturedGraph` but reorganised to enable simultaneous 
computation on a few graphs.
"""
struct BatchedHeterogeneousTrajectoryState{T} <: NonTabularTrajectoryState
    fg::BatchedHeterogeneousFeaturedGraph{T}
    variableIdx::AbstractVector{Int}
    possibleValuesIdx::Union{Nothing, AbstractVector{Vector{Int64}}} #Todo change this to abstract matrix

    function BatchedHeterogeneousTrajectoryState(fg, var, val)
        @assert all(var .<= size(fg.varnf,2)) "The variable index is out of bound"
        @assert all(reduce(vcat,val) .<= size(fg.valnf,2)) "One of the values index is out of bound"
        @assert all(reduce(vcat,[[tuple[2] for tuple in countmap([c for c in vals])] for vals in val]) .== 1) "values array contains one element at least twice"
        return new{Float32}(fg, var, val)
    end
end

"""
    Flux.functor(::Type{HeterogeneousTrajectoryState}, s)

Utility function used to load data on the working device.

To be noted: this behavior isn't standard, as the function returned creates a `BatchedHeterogeneousTrajectoryState`
rather than a `HeterogeneousTrajectoryState`. This behavior makes it possible to dynamically split the matrices of insterest
from the `HeterogeneousFeaturedGraph` wrapper.

function Flux.functor(::Type{HeterogeneousTrajectoryState}, s)
    contovar = Flux.unsqueeze(s.fg.contovar, 3)
    valtovar = Flux.unsqueeze(s.fg.valtovar, 3)
    varnf = Flux.unsqueeze(s.fg.varnf, 3)
    connf = Flux.unsqueeze(s.fg.connf, 3)
    valnf = Flux.unsqueeze(s.fg.valnf, 3)
    gf = Flux.unsqueeze(s.fg.gf, 2)

    return (contovar, valtovar, varnf, connf, valnf, gf), ls -> BatchedHeterogeneousTrajectoryState(
        BatchedHeterogeneousFeaturedGraph{Float32}(ls[1], ls[2], ls[3], ls[4], ls[5], ls[6]),
        [s.variableIdx], 
        [s.possibleValuesIdx]
    )
end

"""
function Flux.functor(::Type{<:HeterogeneousTrajectoryState}, s)
    return (s.fg.contovar, s.fg.valtovar, s.fg.varnf, s.fg.connf, s.fg.valnf, s.fg.gf), ls -> HeterogeneousTrajectoryState(
        HeterogeneousFeaturedGraph(ls[1], ls[2], ls[3], ls[4], ls[5], ls[6]),
        s.variableIdx, 
        s.possibleValuesIdx
    )
end

"""
    Flux.functor(::Type{Vector{HeterogeneousTrajectoryState}}, s)

Utility function used to load data on the working device.

To be noted: this behavior isn't standard, as the function returned creates a `BatchedHeterogeneousTrajectoryState`
rather than a `Vector{HeterogeneousTrajectoryState}`. This behavior makes it possible to dynamically creates matrices of 
the appropriated size to store all the graphs in 3D tensors.
"""
function Flux.functor(::Type{Vector{HeterogeneousTrajectoryState}}, v)
    batchSize = length(v)
    if batchSize==1
        return Flux.functor(HeterogeneousTrajectoryState, v[1])
    end
    variableIdx = ones(Int, batchSize)
    possibleValuesIdx = nothing

    ChainRulesCore.ignore_derivatives() do
        variableIdx = (state -> state.variableIdx).(v)
        possibleValuesIdx = (state -> state.possibleValuesIdx).(v)
    end

    fg = BatchedHeterogeneousFeaturedGraph([state.fg for state in v])
    
    return (fg,), ls -> BatchedHeterogeneousTrajectoryState(
        ls[1],
        variableIdx,
        possibleValuesIdx
    )
end

Flux.functor(::Type{BatchedHeterogeneousTrajectoryState{T}}, ts) where T = (ts.fg,), ls -> BatchedHeterogeneousTrajectoryState(ls[1], ts.variableIdx, ts.possibleValuesIdx) 
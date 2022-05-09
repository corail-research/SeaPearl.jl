using FillArrays

"""
    HeterogeneousTrajectoryState

The most basic state representation, with a featured graph, the index of the variable to branch on and optionnaly a list of possible values.
"""
struct HeterogeneousTrajectoryState <: GraphTrajectoryState
    fg::HeterogeneousFeaturedGraph
    variableIdx::Int

    HeterogeneousTrajectoryState(fg, variableIdx) = new(fg, variableIdx)
end

HeterogeneousTrajectoryState(sr::AbstractStateRepresentation) = throw(ErrorException("missing function HeterogeneousTrajectoryState(::$(typeof(sr)))."))

"""
    BatchedHeterogeneousTrajectoryState

The batched version of the `HeterogeneousTrajectoryState`.

It contains all the information that would be stored in a `HeterogeneousFeaturedGraph` but reorganised to enable simultaneous 
computation on a few graphs.
"""
Base.@kwdef struct BatchedHeterogeneousTrajectoryState{T} <: NonTabularTrajectoryState
    fg::BatchedHeterogeneousFeaturedGraph{T}
    variableIdx::AbstractVector{Int}
end
BatchedHeterogeneousTrajectoryState(fg, var) = BatchedHeterogeneousTrajectoryState{Float32}(fg=fg, variableIdx=var)

"""
    Flux.functor(::Type{HeterogeneousTrajectoryState}, s)

Utility function used to load data on the working device.

To be noted: this behavior isn't standard, as the function returned creates a `BatchedHeterogeneousTrajectoryState`
rather than a `HeterogeneousTrajectoryState`. This behavior makes it possible to dynamically split the matrices of insterest
from the `HeterogeneousFeaturedGraph` wrapper.
"""
function Flux.functor(::Type{HeterogeneousTrajectoryState}, s)
    contovar = Flux.unsqueeze(s.fg.contovar, 3)
    valtovar = Flux.unsqueeze(s.fg.valtovar, 3)
    connf = Flux.unsqueeze(s.fg.connf, 3)
    varnf = Flux.unsqueeze(s.fg.varnf, 3)
    valnf = Flux.unsqueeze(s.fg.valnf, 3)
    gf = Flux.unsqueeze(s.fg.gf, 2)

    return (contovar, valtovar, connf, varnf, valnf, gf), ls -> BatchedHeterogeneousTrajectoryState{Float32}(
        fg = BatchedHeterogeneousFeaturedGraph{Float32}(ls[1], ls[2], ls[3], ls[4], ls[5], ls[6]),
        variableIdx = [s.variableIdx],
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
    variableIdx = ones(Int, batchSize)
    
    Zygote.ignore() do
        variableIdx = (state -> state.variableIdx).(v)
    end

    fg = BatchedHeterogeneousFeaturedGraph([state.fg for state in v])
    
    return (fg,), ls -> BatchedHeterogeneousTrajectoryState{Float32}(
        fg = ls[1],
        variableIdx = variableIdx
    )
end
Flux.functor(::Type{BatchedHeterogeneousTrajectoryState{T}}, ts) where T = (ts.fg,), ls -> BatchedHeterogeneousTrajectoryState{T}(ls[1], ts.variableIdx, ts.allValuesIdx) 
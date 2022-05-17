using FillArrays

"""
    HeterogeneousTrajectoryState

The most basic state representation, with a featured graph, the index of the variable to branch on and optionnaly a list of possible values.
"""
Base.@kwdef struct HeterogeneousTrajectoryState <: GraphTrajectoryState
    fg::HeterogeneousFeaturedGraph
    variableIdx::Int
    possibleValuesIdx::Union{Nothing, Vector{Int64}}
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
    possibleValuesIdx::Union{Nothing, Vector{Int64}} #Todo change this to abstract matrix

end
BatchedHeterogeneousTrajectoryState(fg, var, val) = BatchedHeterogeneousTrajectoryState{AbstractMatrix}(fg=fg, variableIdx=var, possibleValuesIdx = val)

"""
    Flux.functor(::Type{HeterogeneousTrajectoryState}, s)

Utility function used to load data on the working device.

To be noted: this behavior isn't standard, as the function returned creates a `BatchedHeterogeneousTrajectoryState`
rather than a `HeterogeneousTrajectoryState`. This behavior makes it possible to dynamically split the matrices of insterest
from the `HeterogeneousFeaturedGraph` wrapper.
"""
function Flux.functor(::Type{<:HeterogeneousTrajectoryState}, s)
    return (s.fg.contovar, s.fg.valtovar, s.fg.varnf, s.fg.connf, s.fg.valnf, s.fg.gf), ls -> HeterogeneousTrajectoryState(
        fg = HeterogeneousFeaturedGraph(ls[1], ls[2], ls[3], ls[4], ls[5], ls[6]),
        variableIdx = s.variableIdx, 
        possibleValuesIdx = s.possibleValuesIdx
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

    Zygote.ignore() do
        variableIdx = (state -> state.variableIdx).(v)
        possibleValuesIdx = (state -> state.possibleValuesIdx).(v)
    end

    fg = BatchedHeterogeneousFeaturedGraph([state.fg for state in v])
    
    return (fg,), ls -> BatchedHeterogeneousTrajectoryState{Float32}(
        fg = ls[1],
        variableIdx = variableIdx,
        possibleValuesIdx = possibleValuesIdx
    )
end
Flux.functor(::Type{BatchedHeterogeneousTrajectoryState{T}}, ts) where T = (ts.fg,), ls -> BatchedHeterogeneousTrajectoryState{T}(ls[1], ts.variableIdx, ts.allValuesIdx) 
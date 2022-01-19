using FillArrays

"""
    DefaultTrajectoryState

The most basic state representation, with a featured graph, the index of the variable to branch on and optionnaly a list of possible values.
"""
struct DefaultTrajectoryState <: GraphTrajectoryState
    fg::FeaturedGraph
    variableIdx::Int
    allValuesIdx::Union{AbstractVector{Int}, Nothing}

    DefaultTrajectoryState(fg, variableIdx, allValuesIdx) = new(fg, variableIdx, allValuesIdx)
    DefaultTrajectoryState(fg, variableIdx) = new(fg, variableIdx, nothing)
end

DefaultTrajectoryState(sr::AbstractStateRepresentation) = throw(ErrorException("missing function DefaultTrajectoryState(::$(typeof(sr)))."))

"""
    BatchedDefaultTrajectoryState

The batched version of the `DefaultTrajectoryState`.

It contains all the information that would be stored in a `FeaturedGraph` but reorganised to enable simultaneous 
computation on a few graphs.
"""
Base.@kwdef struct BatchedDefaultTrajectoryState{T} <: NonTabularTrajectoryState
    fg::BatchedFeaturedGraph{T}
    variableIdx::AbstractVector{Int}
    allValuesIdx::Union{AbstractMatrix{Int}, Nothing} = nothing
end
BatchedDefaultTrajectoryState(fg, var, val) = BatchedDefaultTrajectoryState{Float32}(fg=fg, variableIdx=var, allValuesIdx=val)

"""
    Flux.functor(::Type{DefaultTrajectoryState}, s)

Utility function used to load data on the working device.

To be noted: this behavior isn't standard, as the function returned creates a `BatchedDefaultTrajectoryState`
rather than a `DefaultTrajectoryState`. This behavior makes it possible to dynamically split the matrices of insterest
from the `FeaturedGraph` wrapper.
"""
function Flux.functor(::Type{DefaultTrajectoryState}, s)
    adj = Flux.unsqueeze(s.fg.graph, 3)
    nf = Flux.unsqueeze(s.fg.nf, 3)
    ef = Flux.unsqueeze(s.fg.ef, 4)
    gf = Flux.unsqueeze(s.fg.gf, 2)
    allValuesIdx = nothing
    if !isnothing(s.allValuesIdx)
        allValuesIdx = Flux.unsqueeze(s.allValuesIdx, 2)
    end
    return (adj, nf, ef, gf), ls -> BatchedDefaultTrajectoryState{Float32}(
        fg = BatchedFeaturedGraph{Float32}(ls[1]; nf=ls[2], ef=ls[3], gf=ls[4]),
        variableIdx = [s.variableIdx],
        allValuesIdx = allValuesIdx
    )
end

"""
    Flux.functor(::Type{Vector{DefaultTrajectoryState}}, s)

Utility function used to load data on the working device.

To be noted: this behavior isn't standard, as the function returned creates a `BatchedDefaultTrajectoryState`
rather than a `Vector{DefaultTrajectoryState}`. This behavior makes it possible to dynamically creates matrices of 
the appropriated size to store all the graphs in 3D tensors.
"""
function Flux.functor(::Type{Vector{DefaultTrajectoryState}}, v)
    batchSize = length(v)
    variableIdx = ones(Int, batchSize)
    allValuesIdx = nothing
    if !isnothing(v[1].allValuesIdx)
        maxActions = Base.maximum(s -> length(s.allValuesIdx), v)
        allValuesIdx = zeros(Int, maxActions, batchSize)
    end
    
    Zygote.ignore() do
        # TODO: this could probably be optimized
        for (idx, state) in enumerate(v)
            variableIdx[idx] = state.variableIdx
            if !isnothing(allValuesIdx)
                allValuesIdx[1:length(state.allValuesIdx), idx] = state.allValuesIdx
            end
        end
    end

    fg = BatchedFeaturedGraph([state.fg for state in v])
    
    return (fg,), ls -> BatchedDefaultTrajectoryState{Float32}(
        fg = ls[1],
        variableIdx = variableIdx,
        allValuesIdx = allValuesIdx
    )
end
Flux.functor(::Type{BatchedDefaultTrajectoryState{T}}, ts) where T = (ts.fg,), ls -> BatchedDefaultTrajectoryState{T}(ls[1], ts.variableIdx, ts.allValuesIdx) 

function Base.ndims(sr::DefaultTrajectoryState) 
    return NaN
end 
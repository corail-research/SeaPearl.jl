using FillArrays

"""
    DefaultTrajectoryState

The most basic state representation, with a featured graph, the index of the variable to branch on and optionnaly a list of possible values.
"""
struct DefaultTrajectoryState <: GraphTrajectoryState
    fg::GraphSignals.FeaturedGraph
    variableIdx::Int
    possibleValuesIdx::Union{AbstractVector{Int}, Nothing}

    DefaultTrajectoryState(fg, variableIdx, possibleValuesIdx) = new(fg, variableIdx, possibleValuesIdx)
    DefaultTrajectoryState(fg, variableIdx) = new(fg, variableIdx, nothing)
end

DefaultTrajectoryState(sr::AbstractStateRepresentation) = throw(ErrorException("missing function DefaultTrajectoryState(::$(typeof(sr)))."))

"""
    BatchedFeaturedGraph

A batched representation of the GraphSignals.FeaturedGraph, to have a closer implementation to GeometricFlux.
"""
struct BatchedFeaturedGraph{T}
    graph::AbstractArray{T, 3}
    nf::AbstractArray{T, 3}
    ef::AbstractArray{T, 3}
    gf::AbstractMatrix{T}

    BatchedFeaturedGraph{T}(graph; nf=Fill(0, (0, nv(graph))), ef=Fill(0, (0, ne(graph))), gf=Fill(0, (0,))) where T = new{T}(graph, nf, ef, gf)
end

"""
    BatchedDefaultTrajectoryState

The batched version of the `DefaultTrajectoryState`.

It contains all the information that would be stored in a `FeaturedGraph` but reorganised to enable simultaneous 
computation on a few graphs.
"""
Base.@kwdef struct BatchedDefaultTrajectoryState{T} <: NonTabularTrajectoryState
    fg::BatchedFeaturedGraph
    variables::AbstractVector{Int}
    possibleValuesIdx::Union{AbstractMatrix{Int}, Nothing} = nothing
end

"""
    Flux.functor(::Type{DefaultTrajectoryState}, s)

Utility function used to load data on the working device.

To be noted: this behavior isn't standard, as the function returned creates a `BatchedDefaultTrajectoryState`
rather than a `DefaultTrajectoryState`. This behavior makes it possible to dynamically split the matrices of insterest
from the `FeaturedGraph` wrapper.
"""
function Flux.functor(::Type{DefaultTrajectoryState}, s)
    adj = Flux.unsqueeze(adjacency_matrix(s.fg), 3)
    nf = Flux.unsqueeze(s.fg.nf, 3)
    ef = Flux.unsqueeze(s.fg.ef, 3)
    gf = Flux.unsqueeze(s.fg.gf, 2)
    possibleValuesIdx = nothing
    if !isnothing(s.possibleValuesIdx)
        possibleValuesIdx = Flux.unsqueeze(s.possibleValuesIdx, 2)
    end
    return (adj, nf, ef, gf), ls -> BatchedDefaultTrajectoryState{Float32}(
        fg = BatchedFeaturedGraph{Float32}(ls[1]; nf=ls[2], ef=ls[3], gf=ls[4]),
        variables = [s.variableIdx],
        possibleValuesIdx = possibleValuesIdx
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
    maxNode = Base.maximum(s -> nv(s.fg), v)
    maxEdge = Base.maximum(s -> ne(s.fg), v)
    maxGlobal = Base.maximum(s -> length(s.fg.gf), v)
    batchSize = length(v)

    adj = zeros(eltype(v[1].fg.nf), maxNode, maxNode, batchSize)
    nf = zeros(eltype(v[1].fg.nf), size(v[1].fg.nf, 1), maxNode, batchSize)
    ef = zeros(eltype(v[1].fg.ef), size(v[1].fg.ef, 1), 2*maxEdge, batchSize)
    gf = zeros(eltype(v[1].fg.gf), maxGlobal, batchSize)
    variables = ones(Int, batchSize)

    possibleValuesIdx = nothing
    if !isnothing(v[1].possibleValuesIdx)
        maxActions = Base.maximum(s -> length(s.possibleValuesIdx), v)
        possibleValuesIdx = zeros(Int, maxActions, batchSize)
    end
    
    Zygote.ignore() do
        # TODO: this could probably be optimized
        foreach(enumerate(v)) do (idx, state)
            adj[1:size(adj,1),1:size(adj,2),idx] = adjacency_matrix(state.fg)
            nf[1:size(state.fg.nf, 1),1:size(state.fg.nf, 2),idx] = state.fg.nf
            ef[1:size(state.fg.ef, 1),1:size(state.fg.ef, 2),idx] = state.fg.ef
            gf[1:size(state.fg.gf, 1),idx] = state.fg.gf
            variables[idx] = state.variableIdx
            if !isnothing(possibleValuesIdx)
                possibleValuesIdx[1:length(state.possibleValuesIdx), idx] = state.possibleValuesIdx
            end
        end
    end
    
    return (adj, nf, ef, gf), ls -> BatchedDefaultTrajectoryState{Float32}(
        fg = BatchedFeaturedGraph{Float32}(ls[1]; nf=ls[2], ef=ls[3], gf=ls[4]),
        variables = variables,
        possibleValuesIdx = possibleValuesIdx
    )
end
using FillArrays

"""
    DefaultTrajectoryState

The most basic state representation, with a featured graph, the index of the variable to branch on and optionnaly a list of possible values.
"""
struct DefaultTrajectoryState <: GraphTrajectoryState
    fg::GeometricFlux.FeaturedGraph
    variableIdx::Int
    allValuesIdx::Union{AbstractVector{Int}, Nothing}

    DefaultTrajectoryState(fg, variableIdx, allValuesIdx) = new(fg, variableIdx, allValuesIdx)
    DefaultTrajectoryState(fg, variableIdx) = new(fg, variableIdx, nothing)
end

DefaultTrajectoryState(sr::AbstractStateRepresentation) = throw(ErrorException("missing function DefaultTrajectoryState(::$(typeof(sr)))."))

"""
    BatchedFeaturedGraph

A batched representation of the GeometricFlux.FeaturedGraph, to have a closer implementation to GeometricFlux.
"""
struct BatchedFeaturedGraph{T}
    graph::AbstractArray{T, 3}
    nf::AbstractArray{T, 3}
    ef::AbstractArray{T, 3}
    gf::AbstractMatrix{T}

    BatchedFeaturedGraph{T}(graph, nf, ef, gf) where T = new{T}(graph, nf, ef, gf)
    BatchedFeaturedGraph{T}(
        graph; 
        nf=Fill(0, (0, size(graph, 1), size(graph, 3))), 
        ef=Fill(0, (0, ne(graph[:,:,1]), size(graph, 3))), 
        gf=Fill(0, (0, size(graph, 3)))
    ) where T = new{T}(graph, nf, ef, gf)
end
BatchedFeaturedGraph(graph, nf, ef, gf) = BatchedFeaturedGraph{Float32}(graph, nf, ef, gf)

"""
    BatchedDefaultTrajectoryState

The batched version of the `DefaultTrajectoryState`.

It contains all the information that would be stored in a `FeaturedGraph` but reorganised to enable simultaneous 
computation on a few graphs.
"""
Base.@kwdef struct BatchedDefaultTrajectoryState{T} <: NonTabularTrajectoryState
    fg::BatchedFeaturedGraph
    variableIdx::AbstractVector{Int}
    allValuesIdx::Union{AbstractMatrix{Int}, Nothing} = nothing
end
BatchedDefaultTrajectoryState(fg, var, val) = BatchedDefaultTrajectoryState{Float32}(fg, var, val)

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
    maxNode = Base.maximum(s -> nv(s.fg), v)
    maxEdge = Base.maximum(s -> ne(s.fg), v)
    maxGlobal = Base.maximum(s -> length(s.fg.gf), v)
    batchSize = length(v)

    adj = zeros(eltype(v[1].fg.nf), maxNode, maxNode, batchSize)
    nf = zeros(eltype(v[1].fg.nf), size(v[1].fg.nf, 1), maxNode, batchSize)
    ef = zeros(eltype(v[1].fg.ef), size(v[1].fg.ef, 1), 2*maxEdge, batchSize)
    gf = zeros(eltype(v[1].fg.gf), maxGlobal, batchSize)
    variableIdx = ones(Int, batchSize)

    allValuesIdx = nothing
    if !isnothing(v[1].allValuesIdx)
        maxActions = Base.maximum(s -> length(s.allValuesIdx), v)
        allValuesIdx = zeros(Int, maxActions, batchSize)
    end
    
    Zygote.ignore() do
        # TODO: this could probably be optimized
        foreach(enumerate(v)) do (idx, state)
            adj[1:size(adj,1),1:size(adj,2),idx] = adjacency_matrix(state.fg)
            nf[1:size(state.fg.nf, 1),1:size(state.fg.nf, 2),idx] = state.fg.nf
            ef[1:size(state.fg.ef, 1),1:size(state.fg.ef, 2),idx] = state.fg.ef
            gf[1:size(state.fg.gf, 1),idx] = state.fg.gf
            variableIdx[idx] = state.variableIdx
            if !isnothing(allValuesIdx)
                allValuesIdx[1:length(state.allValuesIdx), idx] = state.allValuesIdx
            end
        end
    end
    
    return (adj, nf, ef, gf), ls -> BatchedDefaultTrajectoryState{Float32}(
        fg = BatchedFeaturedGraph{Float32}(ls[1]; nf=ls[2], ef=ls[3], gf=ls[4]),
        variableIdx = variableIdx,
        allValuesIdx = allValuesIdx
    )
end
Flux.@functor BatchedFeaturedGraph
Flux.functor(::Type{BatchedDefaultTrajectoryState{T}}, ts) where T = (ts.fg,), ls -> BatchedDefaultTrajectoryState{T}(ls[1], ts.variableIdx, ts.allValuesIdx) 

using SimpleWeightedGraphs
using LinearAlgebra

include("tsptwtrajectorystate.jl")

struct TsptwFeaturization <: AbstractFeaturization end

"""
    TsptwStateRepresentation{F, TS}

This is the Tsptw representation used by Quentin Cappart in Combining Reinforcement Learning and Constraint Programming
for Combinatorial Optimization (https://arxiv.org/pdf/2006.01610.pdf).
"""
mutable struct TsptwStateRepresentation{F, TS} <: FeaturizedStateRepresentation{F, TS}
    dist::Matrix
    timeWindows::Matrix
    pos::Matrix
    nodeFeatures::Union{Nothing, AbstractMatrix{Float32}}
    variableIdx::Union{Nothing, Int64}
    possibleValuesIdx::Union{Nothing, AbstractVector{Int64}}
end

function TsptwStateRepresentation{F, TS}(model::CPModel; action_space=nothing) where {F, TS}
    dist, timeWindows, pos = get_tsptw_info(model)
    sr = TsptwStateRepresentation{F, TS}(dist, timeWindows, pos, nothing, nothing, nothing)
    sr.nodeFeatures = featurize(sr)
    return sr
end

TsptwStateRepresentation(model::CPModel) = TsptwStateRepresentation{TsptwFeaturization, TsptwTrajectoryState}(model)

# This function is used for legacy. It enables compatibility with the experiments present during CPAIOR 2021, with variableOutputGNN
function TsptwTrajectoryState(sr::TsptwStateRepresentation{F, TsptwTrajectoryState}) where F
    # TODO change this once the InitializingPhase is fixed
    if isnothing(sr.variableIdx)
        sr.variableIdx = 1
    end
    if isnothing(sr.possibleValuesIdx)
        throw(ErrorException("Unable to build a TsptwTrajectoryState, when the possible values vector is nothing."))
    end

    n = size(sr.dist, 1)
    adj = ones(Int, n, n) - I
    edgeFeatures = build_edge_feature(adj, sr.dist)
    fg = GeometricFlux.FeaturedGraph(adj; nf=sr.nodeFeatures, ef=edgeFeatures)
    return TsptwTrajectoryState(fg, sr.variableIdx, sr.possibleValuesIdx)
end

function DefaultTrajectoryState(sr::TsptwStateRepresentation{F, DefaultTrajectoryState}) where F
    # TODO change this once the InitializingPhase is fixed
    if isnothing(sr.variableIdx)
        sr.variableIdx = 1
    end
    if isnothing(sr.possibleValuesIdx)
        throw(ErrorException("Unable to build a TsptwTrajectoryState, when the possible values vector is nothing."))
    end

    n = size(sr.dist, 1)
    adj = ones(Int, n, n) - I
    edgeFeatures = build_edge_feature(adj, sr.dist)
    fg = GeometricFlux.FeaturedGraph(adj; nf=sr.nodeFeatures, ef=edgeFeatures)

    actionSpace = collect(1:n)

    return DefaultTrajectoryState(fg, sr.variableIdx, actionSpace)
end

function get_tsptw_info(model::CPModel)
    dist, timeWindows, pos, grid_size = model.adhocInfo

    max_d = Base.maximum(dist)
    max_tw = Base.maximum(timeWindows)

    dist = dist ./ max_d
    timeWindows = timeWindows ./ max_tw
    pos = pos ./ grid_size

    return dist, timeWindows, pos
end

function update_representation!(sr::TsptwStateRepresentation, model::CPModel, x::AbstractIntVar)
    sr.possibleValuesIdx = collect(x.domain)

    i = 1
    while x.id != "a_"*string(i)
        i += 1
    end
    if SeaPearl.isbound(model.variables["v_"*string(i)])
        sr.variableIdx = SeaPearl.assignedValue(model.variables["v_"*string(i)])
    end
    update_features!(sr, model)
    return sr
end

function build_edge_feature(adj::AbstractMatrix, weighted_adj::AbstractMatrix)
    adj_list = GeometricFlux.adjacency_list(adj)
    n = length(adj_list)
    return hcat([build_edge_feature_aux(i, adj_list[i], weighted_adj) for i in 1:n]...)
end

function build_edge_feature_aux(i, js, weighted_adj::AbstractMatrix)
    hcat([weighted_adj[i, j] for j = js]...)
end

"""
    function featurize(sr::TsptwStateRepresentation{TsptwFeaturization})

Create nodeFeatures for every node of the graph. Supposed to be overwritten. 
Tsptw behavior is to call `Tsptw_featurize`.
"""
function featurize(sr::FeaturizedStateRepresentation{TsptwFeaturization, TS}) where TS
    n = size(sr.dist, 1)
    nodeFeatures = zeros(Float32, 6, n)
    for i in 1:n
        if !isnothing(sr.possibleValuesIdx) && !(i in sr.possibleValuesIdx)
            nodeFeatures[5, i] = 1.
        end
        if i == sr.variableIdx
            nodeFeatures[6, i] = 1.
        end
    end

    nodeFeatures[1:2, :] = transpose(sr.pos)
    nodeFeatures[3:4, :] = transpose(sr.timeWindows)
    return nodeFeatures
end

function update_features!(sr::FeaturizedStateRepresentation{TsptwFeaturization, TS}, model::CPModel) where TS
    sr.nodeFeatures[5, :] .= 0
    if !isnothing(sr.possibleValuesIdx)
        sr.nodeFeatures[5, sr.possibleValuesIdx] .= 1
    end
    sr.nodeFeatures[6, :] .= 0
    if !isnothing(sr.variableIdx)
        sr.nodeFeatures[6, sr.variableIdx] = 1
    end
    return 
end

"""
    feature_length(gen::TsptwGenerator, ::Type{TsptwStateRepresentation{TsptwFeaturization}})

Returns the length of the feature vector, useful for SeaPearl to choose the size of the container
"""
feature_length(::Type{TsptwStateRepresentation{TsptwFeaturization, TS}}) where TS = 6

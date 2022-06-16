struct GraphColoringFeaturization <: AbstractFeaturization end

"""
    GraphColoringStateRepresentation{F, TS}

This is a standard graphcoloring representation using the graph of the problem with nodes having their assigned value as label.
"""
mutable struct GraphColoringStateRepresentation{F, TS} <: FeaturizedStateRepresentation{F, TS}
    graph::LightGraphs.Graph
    nodeFeatures::Union{Nothing, AbstractMatrix{Float32}}
    variableToId::Union{Nothing, Dict{AbstractVar,Int}}
    idToVariable::Union{Nothing, Vector{AbstractVar}}
    variableIdx::Union{Nothing, Int64}
    possibleValuesIdx::Union{Nothing, AbstractVector{Int64}}
end

function GraphColoringStateRepresentation{F, TS}(model::CPModel; action_space=nothing) where {F, TS}
    graph, variableToId, idToVariable = get_graphcoloring_graph(model)
    sr = GraphColoringStateRepresentation{F, TS}(graph, nothing, variableToId, idToVariable, nothing, nothing)
    sr.nodeFeatures = featurize(sr)
    return sr
end

GraphColoringRepresentation(model::CPModel) = GraphColoringStateRepresentation{GraphColoringFeaturization, GraphColoringTrajectoryState}(model)

function DefaultTrajectoryState(sr::GraphColoringStateRepresentation{F, DefaultTrajectoryState}) where F
    # TODO change this once the InitializingPhase is fixed
    if isnothing(sr.variableIdx)
        throw(ErrorException("Unable to build a DefaultTrajectoryState, when the branching variable is nothing."))
    end

    n = LightGraphs.nv(sr.graph)
    adj = LightGraphs.adjacency_matrix(sr.graph)
    fg = FeaturedGraph(adj; nf=sr.nodeFeatures)

    actionSpace = collect(1:n)

    return DefaultTrajectoryState(fg, sr.variableIdx, actionSpace, nothing)
end

function get_graphcoloring_graph(model::CPModel)
    graph = LightGraphs.Graph(length(model.branchable_variables))
    variableToId = Dict{AbstractVar, Int}()
    idToVariable = Vector{AbstractVar}()
    id = 1
    for variable in values(model.branchable_variables)
        if variable != model.objective
            variableToId[variable] = id
            push!(idToVariable, variable)
            id += 1
        end
    end
    variableToId[model.objective] = id
    push!(idToVariable, model.objective)
    for i in 1:length(model.branchable_variables)-1
        LightGraphs.add_edge!(graph,i,length(model.branchable_variables))
    end
    for constraint in model.constraints
        if isa(constraint, NotEqual)
            LightGraphs.add_edge!(graph,variableToId[constraint.x],variableToId[constraint.y])
        end
    end
    return graph, variableToId, idToVariable
end

function update_representation!(sr::GraphColoringStateRepresentation, model::CPModel, x::AbstractIntVar)
    sr.possibleValuesIdx = collect(x.domain)
    sr.variableIdx = sr.variableToId[x]
    update_features!(sr, model)
    return sr
end

"""
    function featurize(sr::GraphColoringStateRepresentation{GraphColoringFeaturization})

Create nodeFeatures for every node of the graph (current color of the node or -1 if the color has not been determined yet)
"""
function featurize(sr::FeaturizedStateRepresentation{GraphColoringFeaturization, TS}) where TS
    n = LightGraphs.nv(sr.graph)
    nodeFeatures = zeros(Float32, 2, n)
    for i in 1:n-1
        nodeFeatures[1,i] = -1
        nodeFeatures[2,i] = 0
    end
    nodeFeatures[1,n] = 0
    nodeFeatures[2,n] = 1

    return nodeFeatures
end

function update_features!(sr::FeaturizedStateRepresentation{GraphColoringFeaturization, TS}, model::CPModel) where TS
    for i in 1:LightGraphs.nv(sr.graph)-1
        if isbound(sr.idToVariable[i])
            sr.nodeFeatures[1,i] = assignedValue(sr.idToVariable[i])
        end
    end
    return 
end

"""
    feature_length(gen::GraphColoringGenerator, ::Type{GraphColoringStateRepresentation{GraphColoringFeaturization}})

Returns the length of the feature vector, useful for SeaPearl to choose the size of the container
"""
feature_length(::Type{GraphColoringStateRepresentation{GraphColoringFeaturization, TS}}) where TS = 2
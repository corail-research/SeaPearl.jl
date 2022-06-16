struct GraphColoringFeaturization <: AbstractFeaturization end

"""
    GraphColoringStateRepresentation{F, TS}

This is a standard graphcoloring representation using the graph of the problem with nodes having their assigned value as label.
"""
mutable struct GraphColoringStateRepresentation{F, TS} <: FeaturizedStateRepresentation{F, TS}
    graph::LightGraphs.Graph
    nodeFeatures::Union{Nothing, AbstractMatrix{Float32}}
    variableToId::Union{Nothing, Dict{Variable,Int}}
    idToVariable::Union{Nothing, Vector{Variable}}
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
        sr.variableIdx = 1
    end
    if isnothing(sr.possibleValuesIdx)
        throw(ErrorException("Unable to build a GraphColoringTrajectoryState, when the possible values vector is nothing."))
    end

    n = nv(sr.graph)
    adj = adjacency_matrix(sr.graph)
    fg = FeaturedGraph(adj; nf=sr.nodeFeatures)

    actionSpace = collect(1:n)

    return DefaultTrajectoryState(fg, sr.variableIdx, actionSpace)
end

function get_graphcoloring_graph(model::CPModel)
    graph = LightGraphs.Graph(model.numberOfVariables-1)
    variableToId = Dict{Variable, Id}()
    idToVariable = Vector{Variable}()
    id = 1
    for variable in model.variables
        if variable != model.objective
            variableToId[variable] = id
            push!(idToVariable, variable)
            id += 1
        end
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
    update_features!(sr, model)
    return sr
end

"""
    function featurize(sr::GraphColoringStateRepresentation{GraphColoringFeaturization})

Create nodeFeatures for every node of the graph (current color of the node or -1 if the color has not been determined yet)
"""
function featurize(sr::FeaturizedStateRepresentation{GraphColoringFeaturization, TS}) where TS
    n = nv(sr.graph)
    nodeFeatures = zeros(Float32, 1, n)
    for i in 1:n
        nodeFeatures[1,i] = -1
    end

    return nodeFeatures
end

function update_features!(sr::FeaturizedStateRepresentation{GraphColoringFeaturization, TS}, model::CPModel) where TS
    for i in 1:nv(sr.graph)
        if isbound(idToVariable[i])
            nodeFeatures[1,i] = assignedValue(idToVariable[i])
        end
    end
    return 
end

"""
    feature_length(gen::GraphColoringGenerator, ::Type{GraphColoringStateRepresentation{GraphColoringFeaturization}})

Returns the length of the feature vector, useful for SeaPearl to choose the size of the container
"""
feature_length(::Type{GraphColoringStateRepresentation{GraphColoringFeaturization, TS}}) where TS = 1
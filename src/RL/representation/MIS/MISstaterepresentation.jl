struct MISFeaturization <: AbstractFeaturization end

"""
    MISStateRepresentation{F, TS}

This is a standard MIS representation using the graph of the problem with nodes having their assigned value as label.
"""
mutable struct MISStateRepresentation{F, TS} <: FeaturizedStateRepresentation{F, TS}
    graph::Graphs.Graph
    nodeFeatures::Union{Nothing, AbstractMatrix{Float32}}
    variableToId::Union{Nothing, Dict{AbstractVar,Int}}
    idToVariable::Union{Nothing, Vector{AbstractVar}}
    variableIdx::Union{Nothing, Int64}
    possibleValuesIdx::Union{Nothing, AbstractVector{Int64}}
end

function MISStateRepresentation{F, TS}(model::CPModel; action_space=nothing) where {F, TS}
    graph, variableToId, idToVariable = get_MIS_graph(model)
    sr = MISStateRepresentation{F, TS}(graph, nothing, variableToId, idToVariable, nothing, nothing)
    sr.nodeFeatures = featurize(sr)
    return sr
end

MISRepresentation(model::CPModel) = MISStateRepresentation{MISFeaturization, MISTrajectoryState}(model)

function DefaultTrajectoryState(sr::MISStateRepresentation{F, DefaultTrajectoryState}) where F
    # TODO change this once the InitializingPhase is fixed
    if isnothing(sr.variableIdx)
        throw(ErrorException("Unable to build a DefaultTrajectoryState, when the branching variable is nothing."))
    end
    if isnothing(sr.possibleValuesIdx)
        throw(ErrorException("Unable to build a MISTrajectoryState, when the possible values vector is nothing."))
    end

    n = Graphs.nv(sr.graph)
    adj = Graphs.adjacency_matrix(sr.graph)
    fg = FeaturedGraph(adj; nf=sr.nodeFeatures)

    actionSpace = collect(1:n)

    return DefaultTrajectoryState(fg, sr.variableIdx, actionSpace, nothing)
end

function get_MIS_graph(model::CPModel)
    graph = Graphs.Graph(length(model.branchable_variables))
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
   
    for constraint in model.constraints
        if isa(constraint, SumLessThan)
            Graphs.add_edge!(graph,variableToId[constraint.x[1]],variableToId[constraint.x[2]])
        end
    end
    return graph, variableToId, idToVariable
end

function update_representation!(sr::MISStateRepresentation, model::CPModel, x::AbstractIntVar)
    sr.possibleValuesIdx = collect(x.domain)
    sr.variableIdx = sr.variableToId[x]
    update_features!(sr, model)
    return sr
end

"""
    function featurize(sr::MISStateRepresentation{MISFeaturization})

Create nodeFeatures for every node of the graph (current color of the node or -1 if the color has not been determined yet)
"""
function featurize(sr::FeaturizedStateRepresentation{MISFeaturization, TS}) where TS
    n = Graphs.nv(sr.graph)
    nodeFeatures = zeros(Float32, 1, n)
    for i in 1:n
        nodeFeatures[1,i] = 0
    end

    return nodeFeatures
end

function update_features!(sr::FeaturizedStateRepresentation{MISFeaturization, TS}, model::CPModel) where TS
    for i in 1:Graphs.nv(sr.graph)
        if isbound(sr.idToVariable[i])
            sr.nodeFeatures[1,i] = assignedValue(sr.idToVariable[i])
        end
    end
    return 
end

"""
    feature_length(gen::MISGenerator, ::Type{MISStateRepresentation{MISFeaturization}})

Returns the length of the feature vector, useful for SeaPearl to choose the size of the container
"""
feature_length(::Type{MISStateRepresentation{MISFeaturization, TS}}) where TS = 1
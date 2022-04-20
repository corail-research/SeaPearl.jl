include("cp_layer/cp_layer.jl")

"""
    DefaultStateRepresentation{F, TS}

This is the default representation used by SeaPearl unless the user define his own.

It consists in a tripartite graph representation of the CP Model, with features associated with each node
and an index specifying the variable that should be branched on.
"""
mutable struct DefaultStateRepresentation{F,TS} <: FeaturizedStateRepresentation{F,TS}
    cplayergraph::CPLayerGraph
    nodeFeatures::Union{Nothing,AbstractMatrix{Float32}}
    globalFeatures::Union{Nothing,AbstractVector{Float32}}
    variableIdx::Union{Nothing,Int64}
    allValuesIdx::Union{Nothing,Vector{Int64}}
    valueToPos::Union{Nothing, Dict{Int64, Int64}}
    chosenFeatures::Union{Nothing,Dict{String,Tuple{Bool,Int64}}}
    constraintTypeToId::Union{Nothing,Dict{Type,Int}}
end

function DefaultStateRepresentation{F,TS}(model::CPModel; action_space=nothing, chosen_features=nothing) where {F,TS}
    g = CPLayerGraph(model)
    allValuesIdx = nothing
    valueToPos = nothing
    if !isnothing(action_space)
        allValuesIdx = indexFromCpVertex.([g], ValueVertex.(action_space))
        valueToPos = Dict{Int64, Int64}()
        for (pos, value) in enumerate(action_space)
            valueToPos[value] = pos
        end
    end
    
    sr = DefaultStateRepresentation{F,TS}(g, nothing, nothing, nothing, allValuesIdx, valueToPos, nothing, nothing)
    if isnothing(chosen_features)
        sr.nodeFeatures = featurize(sr)
    else
        sr.nodeFeatures = featurize(sr; chosen_features=chosen_features)
    end
    sr.globalFeatures = global_featurize(sr)
    return sr
end

function DefaultTrajectoryState(sr::DefaultStateRepresentation{F,DefaultTrajectoryState}) where {F}
    if isnothing(sr.variableIdx)
        throw(ErrorException("Unable to build a DefaultTrajectoryState, when the branching variable is nothing."))
    end
    adj = Matrix(adjacency_matrix(sr.cplayergraph))
    fg = isnothing(sr.globalFeatures) ?
         FeaturedGraph(adj; nf=sr.nodeFeatures) : FeaturedGraph(adj; nf=sr.nodeFeatures, gf=sr.globalFeatures)
    return DefaultTrajectoryState(fg, sr.variableIdx, sr.allValuesIdx)
end

"""
    update_representation!(sr::DefaultStateRepresentation, model::CPModel, x::AbstractIntVar)

Update the StateRepesentation according to its Type and Featurization.
"""
function update_representation!(sr::DefaultStateRepresentation, model::CPModel, x::AbstractIntVar)
    update_features!(sr, model)
    sr.variableIdx = indexFromCpVertex(sr.cplayergraph, VariableVertex(x))
    return sr
end

struct DefaultFeaturization <: AbstractFeaturization end

struct FeaturizationHelper <: AbstractFeaturization end

"""
    featurize(sr::DefaultStateRepresentation{DefaultFeaturization, TS})

Create features for every node of the graph. Supposed to be overwritten.

Default behavior consists in a 3D One-hot vector that encodes whether the node represents a Constraint, a Variable or a Value.
"""
function featurize(sr::FeaturizedStateRepresentation{DefaultFeaturization,TS}) where {TS}
    g = sr.cplayergraph
    features = zeros(Float32, 3, nv(g))
    for i in 1:nv(g)
        cp_vertex = SeaPearl.cpVertexFromIndex(g, i)
        if isa(cp_vertex, ConstraintVertex)
            features[1, i] = 1.0f0
        end
        if isa(cp_vertex, VariableVertex)
            features[2, i] = 1.0f0
        end
        if isa(cp_vertex, ValueVertex)
            features[3, i] = 1.0f0
        end
    end
    features
end


"""

"""
function initChosenFeatures(sr::DefaultStateRepresentation{FeaturizationHelper,TS}, values_onehot::Bool, constraint_activity::Bool, variable_initial_domain_size::Bool, nb_involved_constraint_propagation::Bool, nb_not_bounded_variable::Bool) where {TS}
    counter = 3
    sr.chosenFeatures = Dict{String, Tuple{Bool, Int64}}(
        "values_onehot" => (values_onehot, -1),
        "constraint_activity" => (constraint_activity, -1),
        "variable_initial_domain_size" => (variable_initial_domain_size, -1),
        "nb_involved_constraint_propagation" => (nb_involved_constraint_propagation, -1),
        "nb_not_bounded_variable" => (nb_not_bounded_variable, -1)
    )
    if constraint_activity
        counter += 1
        sr.chosenFeatures["constraint_activity"] = (constraint_activity, counter)
    end
    if nb_involved_constraint_propagation
        counter += 1
        sr.chosenFeatures["nb_involved_constraint_propagation"] = (nb_involved_constraint_propagation, counter)
    end
    if variable_initial_domain_size
        counter += 1
        sr.chosenFeatures["variable_initial_domain_size"] = (variable_initial_domain_size, counter)
    end
    if nb_not_bounded_variable
        counter += 1
        sr.chosenFeatures["nb_not_bounded_variable"] = (nb_not_bounded_variable, counter)
    end

    counter += 1
    constraintTypeToId = Dict{Type,Int}()
    constraintsList = keys(sr.cplayergraph.cpmodel.statistics.numberOfTimesInvolvedInPropagation)
    for constraint in constraintsList
        if !haskey(constraintTypeToId,typeof(constraint))
            constraintTypeToId[typeof(constraint)] = counter
            counter += 1 
        end
    end
    sr.constraintTypeToId = constraintTypeToId
    sr.chosenFeatures["values_onehot"] = (values_onehot, counter)
end

"""
Featurization helper: initializes the graph with the features specified as arguments.
"""
function featurize(sr::DefaultStateRepresentation{FeaturizationHelper,TS}; chosen_features::Dict{String,Bool}) where {TS}
    constraint_activity = chosen_features["constraint_activity"]
    variable_initial_domain_size = chosen_features["variable_initial_domain_size"]
    nb_involved_constraint_propagation = chosen_features["nb_involved_constraint_propagation"]
    values_onehot = chosen_features["values_onehot"]
    nb_not_bounded_variable = chosen_features["nb_not_bounded_variable"]
    
    g = sr.cplayergraph
    
    initChosenFeatures(sr, values_onehot, constraint_activity, variable_initial_domain_size, nb_involved_constraint_propagation, nb_not_bounded_variable)

    nb_features = sr.chosenFeatures["values_onehot"][2]
    if sr.chosenFeatures["values_onehot"][1]
        nb_features += g.numberOfValues - 1
    end

    features = zeros(Float32, nb_features, nv(g))
    for i in 1:nv(g)
        cp_vertex = SeaPearl.cpVertexFromIndex(g, i)
        if isa(cp_vertex, ConstraintVertex)
            features[1, i] = 1.0f0
            if constraint_activity
                features[sr.chosenFeatures["constraint_activity"][2], i] = cp_vertex.constraint.active.value
            end
            if nb_involved_constraint_propagation
                features[sr.chosenFeatures["nb_involved_constraint_propagation"][2], i] = 0
            end
            if nb_not_bounded_variable
                variables = variablesArray(cp_vertex.constraint)
                features[sr.chosenFeatures["nb_not_bounded_variable"][2], i] = count(x -> !isbound(x), variables)
            end
            features[sr.constraintTypeToId[typeof(cp_vertex.constraint)] , i] = 1
        end
        if isa(cp_vertex, VariableVertex)
            features[2, i] = 1.0f0
            if variable_initial_domain_size
                features[sr.chosenFeatures["variable_initial_domain_size"][2], i] = length(cp_vertex.variable.domain)
            end
        end
        if isa(cp_vertex, ValueVertex)
            features[3, i] = 1.0f0
            if values_onehot
                # cp_vertex_idx = find(x -> x == cp_vertex.value, sr.allValuesIdx) # TODO : absolutely optimize (IMPORTANT)
                cp_vertex_idx = sr.valueToPos[cp_vertex.value]
                features[sr.chosenFeatures["values_onehot"][2]+cp_vertex_idx - 1, i] = 1
            else
                features[sr.chosenFeatures["values_onehot"][2], i] = cp_vertex.value
            end
        end
    end

    return features
end
"""
function global_featurize(sr::FeaturizedStateRepresentation{DefaultFeaturization, TS}) where TS
    g = sr.cplayergraph
    graph = Graph(g)
    density = LightGraphs.density(graph)
    return [density]
end
"""

"""
    feature_length(gen::AbstractModelGenerator, ::Type{FeaturizedStateRepresentation})

Returns the length of the feature vector, for the `DefaultFeaturization`.
"""
feature_length(::Type{<:FeaturizedStateRepresentation{DefaultFeaturization,TS}}) where {TS} = 3

DefaultStateRepresentation(m::CPModel) = DefaultStateRepresentation{DefaultFeaturization,DefaultTrajectoryState}(m::CPModel)

function update_features!(sr::DefaultStateRepresentation{FeaturizationHelper,TS}, ::CPModel) where {TS}
    g = sr.cplayergraph
    for i in 1:nv(g)
        cp_vertex = SeaPearl.cpVertexFromIndex(g, i)
        if isa(cp_vertex, ConstraintVertex)
            if sr.chosenFeatures["constraint_activity"][1]
                sr.nodeFeatures[sr.chosenFeatures["constraint_activity"][2], i] = cp_vertex.constraint.active.value
            end
            if sr.chosenFeatures["nb_involved_constraint_propagation"][1]
                sr.nodeFeatures[sr.chosenFeatures["nb_involved_constraint_propagation"][2], i] = sr.cplayergraph.cpmodel.statistics.numberOfTimesInvolvedInPropagation[cp_vertex.constraint]
            end
            if sr.chosenFeatures["nb_not_bounded_variable"][1]
                variables = variablesArray(cp_vertex.constraint)
                sr.nodeFeatures[sr.chosenFeatures["nb_not_bounded_variable"][2], i] = count(x -> !isbound(x), variables)
            end
        end
        if isa(cp_vertex, ValueVertex)
            if sr.chosenFeatures["values_onehot"][1]
                # cp_vertex_idx = find(x -> x == cp_vertex.value, sr.allValuesIdx) # TODO : absolutely optimize (IMPORTANT)
                cp_vertex_idx = sr.valueToPos[cp_vertex.value]
                sr.nodeFeatures[sr.chosenFeatures["values_onehot"][2] + cp_vertex_idx - 1, i] = 1
            else
                sr.nodeFeatures[sr.chosenFeatures["values_onehot"][2], i] = cp_vertex.value
            end
        end
    end
end
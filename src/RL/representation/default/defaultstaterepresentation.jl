include("cp_layer/cp_layer.jl")

"""
    DefaultStateRepresentation{F, TS}

This is the default representation used by SeaPearl unless the user define his own.

It consists in a tripartite graph representation of the CP Model, with features associated with each node
and an index specifying the variable that should be branched on.

Fields:
- `cplayergraph`: representation of the problem as a tripartite graph.
- `nodeFeatures`: 
- `globalFeatures`: 
- `variableIdx`: 
- `allValuesIdx`: 
- `valueToPos`: Dictionary mapping the value of an action to its position in the one-hot encoding of the value. The boolean corresponds to the fact that the feature is used or not, the integer corresponds to the position of the feature in the vector.
- `chosenFeatures`: Dictionary of featurization options, useful in case `FeaturizationHelper` is used. See `FeaturizationHelper` for details about the options.
- `constraintTypeToId`: Dictionary mapping the type of a constraint to its position in the one-hot encoding of the constraint type.
"""
mutable struct DefaultStateRepresentation{F,TS} <: FeaturizedStateRepresentation{F,TS}
    cplayergraph::CPLayerGraph
    nodeFeatures::Union{Nothing,AbstractMatrix{Float32}}
    globalFeatures::Union{Nothing,AbstractVector{Float32}}
    variableIdx::Union{Nothing,Int64}
    allValuesIdx::Union{Nothing,Vector{Int64}}
    valueToPos::Union{Nothing,Dict{Int64,Int64}}
    chosenFeatures::Union{Nothing,Dict{String,Tuple{Bool,Int64}}}
    constraintTypeToId::Union{Nothing,Dict{Type,Int}}
    nbFeatures::Int64
end

"""
    feature_length(gen::AbstractModelGenerator, ::Type{FeaturizedStateRepresentation})

Returns the length of the feature vector.
"""
feature_length(sr::Type{<:DefaultStateRepresentation{F,TS}}) where {F, TS} = sr.nbFeatures

DefaultStateRepresentation(m::CPModel) = DefaultStateRepresentation{DefaultFeaturization,DefaultTrajectoryState}(m::CPModel)

function DefaultStateRepresentation{F,TS}(model::CPModel; action_space=nothing, chosen_features=nothing) where {F,TS}
    g = CPLayerGraph(model)
    allValuesIdx = nothing
    valueToPos = nothing
    if !isnothing(action_space)
        allValuesIdx = indexFromCpVertex.([g], ValueVertex.(action_space))
        valueToPos = Dict{Int64,Int64}()
        for (pos, value) in enumerate(action_space)
            valueToPos[value] = pos
        end
    end

    sr = DefaultStateRepresentation{F,TS}(g, nothing, nothing, nothing, allValuesIdx, valueToPos, nothing, nothing, 0)
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

"""
Featurization taking advantage of the `chosenFeatures` dictionary. This dictionary specifies, via a boolean, whether to add this or that feature to the featurization.

The dictionary must specify a boolean value for the following features:
- "values_onehot": a one-hot encoding of the value for value nodes
- "values_raw": the raw value of the value for value nodes
- "constraint_activity": whether or not the constraint is active for constraint nodes
- "constraint_type": a one-hot encoding of the constraint type for constraint nodes
- "variable_initial_domain_size": the initial size of the domain of the variable for variable nodes
- "variable_domain_size": the current size of the domain of the variable for variable nodes 
- "variable_is_bound": whether or not the variable is bound for variable nodes
- "nb_involved_constraint_propagation": the number of times the constraint has been put in the fixPoint call stack for constraint nodes.
- "nb_not_bounded_variable": the number of non-bound variable involve in the constraint for constraint nodes
"""
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
    sr.nbFeatures = 3
    features
end

"""
    initChosenFeatures(sr::DefaultStateRepresentation{FeaturizationHelper,TS}, chosen_features::Dict{String,Bool})

TODO
"""
function initChosenFeatures(sr::DefaultStateRepresentation{FeaturizationHelper,TS}, chosen_features::Dict{String,Bool}) where {TS}
    
    # Initialize chosenFeatures with all positions at -1
    sr.chosenFeatures = Dict{String,Tuple{Bool,Int64}}(
        "values_onehot" => (chosen_features["values_onehot"], -1),
        "values_raw" => (chosen_features["values_raw"], -1),
        "constraint_activity" => (chosen_features["constraint_activity"], -1),
        "constraint_type" => (chosen_features["constraint_type"], -1),
        "variable_initial_domain_size" => (chosen_features["variable_initial_domain_size"], -1),
        "variable_domain_size" => (chosen_features["variable_domain_size"], -1),
        "variable_is_bound" => (chosen_features["variable_is_bound"], -1),
        "nb_involved_constraint_propagation" => (chosen_features["nb_involved_constraint_propagation"], -1),
        "nb_not_bounded_variable" => (chosen_features["nb_not_bounded_variable"], -1)
    )
        
    counter = 4 # There is at least three features : the one-hot encoding of the node type ∈ {Constraint, Value, Variable}
    if sr.chosenFeatures["constraint_activity"][1]
        sr.chosenFeatures["constraint_activity"] = (sr.chosenFeatures["constraint_activity"][1], counter)
        counter += 1
    end
    if sr.chosenFeatures["nb_involved_constraint_propagation"][1]
        sr.chosenFeatures["nb_involved_constraint_propagation"] = (sr.chosenFeatures["nb_involved_constraint_propagation"][1], counter)
        counter += 1
    end
    if sr.chosenFeatures["variable_initial_domain_size"][1]
        sr.chosenFeatures["variable_initial_domain_size"] = (sr.chosenFeatures["variable_initial_domain_size"][1], counter)
        counter += 1
    end
    if sr.chosenFeatures["variable_domain_size"][1]
        sr.chosenFeatures["variable_domain_size"] = (sr.chosenFeatures["variable_domain_size"][1], counter)
        counter += 1
    end
    if sr.chosenFeatures["variable_is_bound"][1]
        sr.chosenFeatures["variable_is_bound"] = (sr.chosenFeatures["variable_is_bound"][1], counter)
        counter += 1
    end
    if sr.chosenFeatures["nb_not_bounded_variable"][1]
        sr.chosenFeatures["nb_not_bounded_variable"] = (sr.chosenFeatures["nb_not_bounded_variable"][1], counter)
        counter += 1
    end

    if sr.chosenFeatures["nb_not_bounded_variable"][1]
        sr.chosenFeatures["nb_not_bounded_variable"] = (sr.chosenFeatures["nb_not_bounded_variable"][1], counter)
        counter += 1
    end

    if sr.chosenFeatures["constraint_type"][1]
        sr.chosenFeatures["constraint_type"] = (sr.chosenFeatures["constraint_type"][1], counter)
        constraintTypeToId = Dict{Type,Int}()
        constraintsList = keys(sr.cplayergraph.cpmodel.statistics.numberOfTimesInvolvedInPropagation)
        for constraint in constraintsList
            if !haskey(constraintTypeToId, typeof(constraint))
                constraintTypeToId[typeof(constraint)] = counter
                counter += 1
            end
        end
        sr.constraintTypeToId = constraintTypeToId
    end
    
    if sr.chosenFeatures["values_raw"][1]
        sr.chosenFeatures["values_raw"] = (sr.chosenFeatures["values_raw"][1], counter)
        counter += 1
    end

    if sr.chosenFeatures["values_onehot"][1]
        sr.chosenFeatures["values_onehot"] = (sr.chosenFeatures["values_onehot"][1], counter)
        counter += sr.cplayergraph.numberOfValues
    end

    sr.nbFeatures = counter - 1
end

"""
Featurization helper: initializes the graph with the features specified as arguments.
"""
function featurize(sr::DefaultStateRepresentation{FeaturizationHelper,TS}; chosen_features::Dict{String,Bool}) where {TS}
    constraint_activity = chosen_features["constraint_activity"]
    constraint_type = chosen_features["constraint_type"]
    variable_initial_domain_size = chosen_features["variable_initial_domain_size"]
    variable_domain_size = chosen_features["variable_domain_size"]
    variable_is_bound = chosen_features["variable_is_bound"]
    nb_involved_constraint_propagation = chosen_features["nb_involved_constraint_propagation"]
    values_onehot = chosen_features["values_onehot"]
    values_raw = chosen_features["values_raw"]
    nb_not_bounded_variable = chosen_features["nb_not_bounded_variable"]

    println(values_raw, chosen_features["values_raw"], )

    g = sr.cplayergraph

    initChosenFeatures(sr, chosen_features)

    features = zeros(Float32, sr.nbFeatures, nv(g))
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
            if constraint_type
                features[sr.constraintTypeToId[typeof(cp_vertex.constraint)], i] = 1
            end
        end
        if isa(cp_vertex, VariableVertex)
            features[2, i] = 1.0f0
            if variable_initial_domain_size
                features[sr.chosenFeatures["variable_initial_domain_size"][2], i] = length(cp_vertex.variable.domain)
            end
            if variable_domain_size
                features[sr.chosenFeatures["variable_domain_size"][2], i] = length(cp_vertex.variable.domain)
            end
            if variable_is_bound
                features[sr.chosenFeatures["variable_is_bound"][2], i] = isbound(cp_vertex.variable)
            end
        end
        if isa(cp_vertex, ValueVertex)
            features[3, i] = 1.0f0
            if values_onehot
                cp_vertex_idx = sr.valueToPos[cp_vertex.value]
                features[sr.chosenFeatures["values_onehot"][2]+cp_vertex_idx-1, i] = 1
            elseif values_raw
                features[sr.chosenFeatures["values_raw"][2], i] = cp_vertex.value
            end
        end
    end

    return features
end

"""
    update_features!(sr::DefaultStateRepresentation{FeaturizationHelper,TS}, ::CPModel)

Function updating the features of the graph nodes. 

Use the `sr.chosenFeatures` dictionary to find out which features are used and their positions in the vector.
"""
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
        if isa(cp_vertex, VariableVertex)
            if sr.chosenFeatures["variable_domain_size"][1]
                sr.nodeFeatures[sr.chosenFeatures["variable_domain_size"][2], i] = length(cp_vertex.variable.domain)
            end
            if sr.chosenFeatures["variable_is_bound"][1]
                sr.nodeFeatures[sr.chosenFeatures["variable_is_bound"][2], i] = isbound(cp_vertex.variable)
            end
        end
        if isa(cp_vertex, ValueVertex) # Probably useless, check before removing
            if sr.chosenFeatures["values_onehot"][1]
                cp_vertex_idx = sr.valueToPos[cp_vertex.value]
                sr.nodeFeatures[sr.chosenFeatures["values_onehot"][2]+cp_vertex_idx-1, i] = 1
            else
                sr.nodeFeatures[sr.chosenFeatures["values_raw"][2], i] = cp_vertex.value
            end
        end
    end
end
"""
    DefaultStateRepresentation{F, TS}

This is the default representation used by SeaPearl unless the user define his own.

It consists in a tripartite graph representation of the CP Model, with features associated with each node
and an index specifying the variable that should be branched on.

Fields:
- `cplayergraph`: representation of the problem as a tripartite graph.
- `nodeFeatures`: Feature matrix of the nodes. Each column corresponds to a node.
- `globalFeatures`: Feature vector of the entire graph.
- `variableIdx`: Index of the variable we are currently considering.
- `allValuesIdx`: Index of value nodes in `cplayergraph`.
- `valueToPos`: Dictionary mapping the value of an action to its position in the one-hot encoding of the value. 
The boolean corresponds to the fact that the feature is used or not, the integer corresponds to the position of the feature in the vector.
- `chosenFeatures`: Dictionary of featurization options. The boolean corresponds to whether the feature is active or not, 
the integer corresponds to the position of the feature in the vector. See below for details about the options.
- `constraintTypeToId`: Dictionary mapping the type of a constraint to its position in the one-hot encoding of the constraint type.

The `chosenFeatures` dictionary specify a boolean -notifying whether the features are active or not - 
and a position for the following features:
- "constraint_activity": whether or not the constraint is active for constraint nodes
- "constraint_type": a one-hot encoding of the constraint type for constraint nodes
- "nb_involved_constraint_propagation": the number of times the constraint has been put in the fixPoint call stack for constraint nodes.
- "nb_not_bounded_variable": the number of non-bound variable involve in the constraint for constraint nodes
- "variable_domain_size": the current size of the domain of the variable for variable nodes 
- "variable_initial_domain_size": the initial size of the domain of the variable for variable nodes
- "variable_is_bound": whether or not the variable is bound for variable nodes
- "values_onehot": a one-hot encoding of the value for value nodes
- "values_raw": the raw value of the value for value nodes
"""
mutable struct DefaultStateRepresentation{F,TS} <: FeaturizedStateRepresentation{F,TS}
    cplayergraph::CPLayerGraph
    nodeFeatures::Union{Nothing,AbstractMatrix{Float32}}
    globalFeatures::Union{Nothing,AbstractVector{Float32}}
    variableIdx::Union{Nothing,Int64}
    allValuesIdx::Union{Nothing,Vector{Int64}}
    possibleValuesIdx::Union{Nothing, Vector{Int64}}
    valueToPos::Union{Nothing,Dict{Int64,Int64}}
    chosenFeatures::Union{Nothing,Dict{String,Tuple{Bool,Int64}}}
    constraintTypeToId::Union{Nothing,Dict{Type,Int}}
    nbFeatures::Int64
end

"""
    feature_length(sr::DefaultStateRepresentation{F,TS}) where {F,TS}

Returns the length of the feature vector.

`sr.nbFeatures` is set in `initChosenFeatures`, which is called in `featurize` when the `DefaultStateRepresentation` is created.
"""
feature_length(sr::DefaultStateRepresentation{F,TS}) where {F,TS} = sr.nbFeatures

"""
    feature_length(gen::AbstractModelGenerator, ::Type{FeaturizedStateRepresentation})

Returns the length of the feature vector, for the `DefaultFeaturization` with no chosen features.

Must be overwritten for any other featurization. 

The difference with the `feature_length(sr::DefaultStateRepresentation{F,TS})` function is that it takes a type as a parameter and not an instance.
"""
feature_length(::Type{<:FeaturizedStateRepresentation{DefaultFeaturization, TS}}) where TS = 3

DefaultStateRepresentation(m::CPModel) = DefaultStateRepresentation{DefaultFeaturization,DefaultTrajectoryState}(m::CPModel)

"""
    DefaultStateRepresentation{F,TS}(model::CPModel; action_space=nothing, chosen_features::Union{Nothing, Dict{String,Bool}}=nothing) where {F,TS}

Constructor to initialize the representation with an action space and a dictionary of feature choices.
"""
function DefaultStateRepresentation{F,TS}(model::CPModel; action_space=nothing, chosen_features::Union{Nothing,Dict{String,Bool}}=nothing) where {F,TS}
    g = CPLayerGraph(model)
    allValuesIdx = nothing
    valueToPos = nothing
    possibleValuesIdx = nothing

    if !isnothing(action_space)
        allValuesIdx = indexFromCpVertex.([g], ValueVertex.(action_space))
        valueToPos = Dict{Int64,Int64}()
        for (pos, value) in enumerate(action_space) # TODO : understand why value are all in action space
            valueToPos[value] = pos
        end
    end

    sr = DefaultStateRepresentation{F,TS}(g, nothing, nothing, nothing, allValuesIdx, nothing, valueToPos, nothing, nothing, 0)
    if isnothing(chosen_features)
        sr.nodeFeatures = featurize(sr) # custom featurize function doesn't necessarily support chosen_features
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
    adj = Matrix(LightGraphs.adjacency_matrix(sr.cplayergraph))
    fg = isnothing(sr.globalFeatures) ?
         FeaturedGraph(adj; nf=sr.nodeFeatures) : FeaturedGraph(adj; nf=sr.nodeFeatures, gf=sr.globalFeatures)
    return DefaultTrajectoryState(fg, sr.variableIdx, sr.allValuesIdx, sr.possibleValuesIdx)
end

"""
    update_representation!(sr::DefaultStateRepresentation, model::CPModel, x::AbstractIntVar)

Update the StateRepesentation according to its Type and Featurization.
"""
function update_representation!(sr::DefaultStateRepresentation, model::CPModel, x::AbstractIntVar)
    update_features!(sr, model)
    ncon = sr.cplayergraph.numberOfConstraints
    nvar = sr.cplayergraph.numberOfVariables
    sr.possibleValuesIdx = map(v -> indexFromCpVertex(sr.cplayergraph, ValueVertex(v)), collect(x.domain))
    sr.variableIdx = indexFromCpVertex(sr.cplayergraph, VariableVertex(x))

    return sr
end

"""
    featurize(sr::DefaultStateRepresentation{DefaultFeaturization, TS})

Create features for every node of the graph. Can be overwritten for a completely custom featurization.

Default behavior consists in a 3D One-hot vector that encodes whether the node represents a Constraint, a Variable or a Value.

It is also possible to pass a `chosen_features` dictionary allowing to choose among some non mandatory features. 
It will be used in `initChosenFeatures!` to initialize `sr.chosenFeatures`. 
See `DefaultStateRepresentation` for a list of possible options.
It is only necessary to specify the options you wish to activate.
"""
function featurize(sr::DefaultStateRepresentation{DefaultFeaturization,TS}; chosen_features::Union{Nothing,Dict{String,Bool}}=nothing) where {TS}
    initChosenFeatures!(sr, chosen_features)
    g = sr.cplayergraph
    features = zeros(Float32, sr.nbFeatures, LightGraphs.nv(g))
    for i in 1:LightGraphs.nv(g)
        cp_vertex = SeaPearl.cpVertexFromIndex(g, i)
        if sr.chosenFeatures["node_number_of_neighbors"][1]
            features[sr.chosenFeatures["node_number_of_neighbors"][2], i] = length(LightGraphs.outneighbors(g, i))
        end
        if isa(cp_vertex, ConstraintVertex)
            features[1, i] = 1.0f0
            if sr.chosenFeatures["constraint_activity"][1]
                if isa(cp_vertex.constraint, ViewConstraint)
                    features[sr.chosenFeatures["constraint_activity"][2], i] = isbound(cp_vertex.constraint.parent)
                else
                    features[sr.chosenFeatures["constraint_activity"][2], i] = cp_vertex.constraint.active.value
                end
            end
            if sr.chosenFeatures["nb_involved_constraint_propagation"][1]
                features[sr.chosenFeatures["nb_involved_constraint_propagation"][2], i] = 0
            end
            if sr.chosenFeatures["nb_not_bounded_variable"][1]
                variables = variablesArray(cp_vertex.constraint)
                features[sr.chosenFeatures["nb_not_bounded_variable"][2], i] = count(x -> !isbound(x), variables)
            end
            if sr.chosenFeatures["constraint_type"][1]
                features[sr.constraintTypeToId[typeof(cp_vertex.constraint)], i] = 1
                if isa(cp_vertex.constraint, ViewConstraint)
                    if isa(cp_vertex.constraint.child, IntVarViewMul)
                        features[sr.constraintTypeToId[typeof(cp_vertex.constraint)] + 1, i] = cp_vertex.constraint.child.a
                    elseif isa(cp_vertex.constraint.child, IntVarViewOffset)
                        features[sr.constraintTypeToId[typeof(cp_vertex.constraint)] + 2, i] = cp_vertex.constraint.child.c
                    elseif isa(cp_vertex.constraint.child, IntVarViewOpposite)
                        features[sr.constraintTypeToId[typeof(cp_vertex.constraint)] + 1, i] = -1
                    elseif isa(cp_vertex.constraint.child, BoolVarViewNot)
                        features[sr.constraintTypeToId[typeof(cp_vertex.constraint)] + 3, i] = 1
                    else
                        error("WARNING: Unknwon VarViewType: please implement DefaultFeaturization for this type!")
                    end
                end
            end
        end
        if isa(cp_vertex, VariableVertex)
            features[2, i] = 1.0f0
            if sr.chosenFeatures["variable_initial_domain_size"][1]
                features[sr.chosenFeatures["variable_initial_domain_size"][2], i] = length(cp_vertex.variable.domain)
            end
            if sr.chosenFeatures["variable_domain_size"][1]
                features[sr.chosenFeatures["variable_domain_size"][2], i] = length(cp_vertex.variable.domain)
            end
            if sr.chosenFeatures["variable_is_bound"][1]
                features[sr.chosenFeatures["variable_is_bound"][2], i] = isbound(cp_vertex.variable)
            end
            if sr.chosenFeatures["variable_is_branchable"][1]
                features[sr.chosenFeatures["variable_is_branchable"][2], i] = Int(haskey(sr.cplayergraph.cpmodel.branchable,cp_vertex.variable.id) && sr.cplayergraph.cpmodel.branchable[cp_vertex.variable.id]==1)
            end
            if sr.chosenFeatures["variable_is_objective"][1]
                features[sr.chosenFeatures["variable_is_objective"][2], i] = sr.cplayergraph.cpmodel.objective == cp_vertex.variable
            end
            if sr.chosenFeatures["variable_assigned_value"][1]
                features[sr.chosenFeatures["variable_assigned_value"][2], i] = isbound(cp_vertex.variable) ? assignedValue(cp_vertex.variable) : 0
            end
        end
        if isa(cp_vertex, ValueVertex)
            features[3, i] = 1.0f0
            if sr.chosenFeatures["values_raw"][1]
                features[sr.chosenFeatures["values_raw"][2], i] = cp_vertex.value
            end
            if sr.chosenFeatures["values_onehot"][1]
                cp_vertex_idx = sr.valueToPos[cp_vertex.value]
                features[sr.chosenFeatures["values_onehot"][2]+cp_vertex_idx-1, i] = 1
            end
        end
    end

    return features
end

"""
    initChosenFeatures!(sr::DefaultStateRepresentation{DefaultFeaturization,TS}, chosen_features::Dict{String,Bool})

Builds the `sr.chosenFeatures` dictionary  and sets `sr.nbFeatures`.
"""
function initChosenFeatures!(sr::DefaultStateRepresentation{DefaultFeaturization,TS}, chosen_features::Union{Nothing,Dict{String,Bool}}) where {TS}
    # Initialize chosenFeatures with all positions at -1 and presence to false
    sr.chosenFeatures = Dict{String,Tuple{Bool,Int64}}(
        "constraint_activity" => (false, -1),
        "constraint_type" => (false, -1),
        "nb_involved_constraint_propagation" => (false, -1),
        "nb_not_bounded_variable" => (false, -1),
        "node_number_of_neighbors" => (false, -1),
        "variable_domain_size" => (false, -1),
        "variable_initial_domain_size" => (false, -1),
        "variable_is_bound" => (false, -1),
        "variable_is_branchable" => (false, -1),
        "variable_is_objective" => (false, -1),
        "variable_assigned_value" => (false, -1),
        "values_onehot" => (false, -1),
        "values_raw" => (false, -1),
    )

    counter = 4 # There is at least three features : the one-hot encoding of the node type ∈ {Constraint, Value, Variable}
    if !isnothing(chosen_features)
        if haskey(chosen_features, "constraint_activity") && chosen_features["constraint_activity"]
            sr.chosenFeatures["constraint_activity"] = (true, counter)
            counter += 1
        end

        if haskey(chosen_features, "nb_involved_constraint_propagation") && chosen_features["nb_involved_constraint_propagation"]
            sr.chosenFeatures["nb_involved_constraint_propagation"] = (true, counter)
            counter += 1
        end

        if haskey(chosen_features, "variable_initial_domain_size") && chosen_features["variable_initial_domain_size"]
            sr.chosenFeatures["variable_initial_domain_size"] = (true, counter)
            counter += 1
        end

        if haskey(chosen_features, "variable_domain_size") && chosen_features["variable_domain_size"]
            sr.chosenFeatures["variable_domain_size"] = (true, counter)
            counter += 1
        end

        if haskey(chosen_features, "variable_is_bound") && chosen_features["variable_is_bound"]
            sr.chosenFeatures["variable_is_bound"] = (true, counter)
            counter += 1
        end

        if haskey(chosen_features, "variable_is_branchable") && chosen_features["variable_is_branchable"]
            sr.chosenFeatures["variable_is_branchable"] = (true, counter)
            counter += 1
        end

        if haskey(chosen_features, "variable_is_objective") && chosen_features["variable_is_objective"]
            sr.chosenFeatures["variable_is_objective"] = (true, counter)
            counter += 1
        end

        if haskey(chosen_features, "variable_assigned_value") && chosen_features["variable_assigned_value"]
            sr.chosenFeatures["variable_assigned_value"] = (true, counter)
            counter += 1
        end

        if haskey(chosen_features, "node_number_of_neighbors") && chosen_features["node_number_of_neighbors"]
            sr.chosenFeatures["node_number_of_neighbors"] = (true, counter)
            counter += 1
        end

        if haskey(chosen_features, "nb_not_bounded_variable") && chosen_features["nb_not_bounded_variable"]
            sr.chosenFeatures["nb_not_bounded_variable"] = (true, counter)
            counter += 1
        end


        if haskey(chosen_features, "constraint_type") && chosen_features["constraint_type"]
            sr.chosenFeatures["constraint_type"] = (true, counter)
            constraintTypeToId = Dict{Type,Int}()
            nbcon = sr.cplayergraph.numberOfConstraints
            constraintsVertexList = sr.cplayergraph.idToNode[1:nbcon]
            for vertex in constraintsVertexList
                if !haskey(constraintTypeToId, typeof(vertex.constraint))
                    constraintTypeToId[typeof(vertex.constraint)] = counter
                    if isa(vertex.constraint,ViewConstraint)
                        counter += 4 
                    else
                        counter += 1
                    end
                end
            end
            sr.constraintTypeToId = constraintTypeToId
        end

        if haskey(chosen_features, "values_raw") && chosen_features["values_raw"]
            sr.chosenFeatures["values_raw"] = (true, counter)
            counter += 1
        end

        if haskey(chosen_features, "values_onehot") && chosen_features["values_onehot"]
            sr.chosenFeatures["values_onehot"] = (true, counter)
            counter += sr.cplayergraph.numberOfValues
        end
    end

    sr.nbFeatures = counter - 1
end

"""
    update_features!(sr::DefaultStateRepresentation{DefaultFeaturization,TS}, ::CPModel)

Updates the features of the graph nodes. 

Use the `sr.chosenFeatures` dictionary to find out which features are used and their positions in the vector.
"""
function update_features!(sr::DefaultStateRepresentation{DefaultFeaturization,TS}, ::CPModel) where {TS}
    g = sr.cplayergraph
    for i in 1:LightGraphs.nv(g)
        cp_vertex = SeaPearl.cpVertexFromIndex(g, i)
        if sr.chosenFeatures["node_number_of_neighbors"][1]
            sr.nodeFeatures[sr.chosenFeatures["node_number_of_neighbors"][2], i] = length(LightGraphs.outneighbors(g, i))
        end
        if isa(cp_vertex, ConstraintVertex)
            if sr.chosenFeatures["constraint_activity"][1]
                if isa(cp_vertex.constraint, ViewConstraint)
                    sr.nodeFeatures[sr.chosenFeatures["constraint_activity"][2], i] = isbound(cp_vertex.constraint.parent)
                else
                    sr.nodeFeatures[sr.chosenFeatures["constraint_activity"][2], i] = cp_vertex.constraint.active.value
                end
            end

            if sr.chosenFeatures["nb_involved_constraint_propagation"][1]
                if isa(cp_vertex.constraint, ViewConstraint)
                    sr.nodeFeatures[sr.chosenFeatures["nb_involved_constraint_propagation"][2], i] = 0
                else
                    sr.nodeFeatures[sr.chosenFeatures["nb_involved_constraint_propagation"][2], i] = sr.cplayergraph.cpmodel.statistics.numberOfTimesInvolvedInPropagation[cp_vertex.constraint]
                end
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

            if sr.chosenFeatures["variable_assigned_value"][1]
                sr.nodeFeatures[sr.chosenFeatures["variable_assigned_value"][2], i] = isbound(cp_vertex.variable) ? assignedValue(cp_vertex.variable) : 0
            end
        end
        if isa(cp_vertex, ValueVertex) # Probably useless, check before removing
            if sr.chosenFeatures["values_raw"][1]
                sr.nodeFeatures[sr.chosenFeatures["values_raw"][2], i] = cp_vertex.value
            end

            if sr.chosenFeatures["values_onehot"][1]
                cp_vertex_idx = sr.valueToPos[cp_vertex.value]
                sr.nodeFeatures[sr.chosenFeatures["values_onehot"][2]+cp_vertex_idx-1, i] = 1
            end
        end
    end
end
"""
    HeterogeneousStateRepresentation{F, TS}

Similar to the `DefaultStateRepresentation`, except that the feature matrices are specific to each type of node (constraint, variable and value).

It consists in a tripartite graph representation of the CP Model, with features associated with each node
and an index specifying the variable that should be branched on.

Fields:
- `cplayergraph`: representation of the problem as a tripartite graph.
- `constraintNodeFeatures`: Feature matrix of the constraint nodes. Each column corresponds to a node.
- `variableNodeFeatures`: Feature matrix of the variable nodes. Each column corresponds to a node.
- `valueNodeFeatures`: Feature matrix of the value nodes. Each column corresponds to a node.
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
mutable struct HeterogeneousStateRepresentation{F,TS} <: FeaturizedStateRepresentation{F,TS}
    cplayergraph::CPLayerGraph
    variableNodeFeatures::Union{Nothing,AbstractMatrix{Float32}}
    constraintNodeFeatures::Union{Nothing,AbstractMatrix{Float32}}
    valueNodeFeatures::Union{Nothing,AbstractMatrix{Float32}}
    globalFeatures::Union{Nothing,AbstractVector{Float32}}
    variableIdx::Union{Nothing,Int64}
    allValuesIdx::Union{Nothing,Vector{Int64}}
    valueToPos::Union{Nothing,Dict{Int64,Int64}}
    chosenFeatures::Union{Nothing,Dict{String,Tuple{Bool,Int64}}}
    constraintTypeToId::Union{Nothing,Dict{Type,Int}}
    nbVariableFeatures::Int64
    nbConstraintFeatures::Int64
    nbValueFeatures::Int64
end

HeterogeneousStateRepresentation(m::CPModel) = HeterogeneousStateRepresentation{DefaultFeaturization,HeterogeneousTrajectoryState}(m::CPModel)

"""
    HeterogeneousStateRepresentation{F,TS}(model::CPModel; action_space=nothing, chosen_features::Union{Nothing, Dict{String,Bool}}=nothing) where {F,TS}

Constructor to initialize the representation with an action space and a dictionary of feature choices.
"""
function HeterogeneousStateRepresentation{F,TS}(model::CPModel; action_space=nothing, chosen_features::Union{Nothing,Dict{String,Bool}}=nothing) where {F,TS}
    g = CPLayerGraph(model)
    allValuesIdx = nothing
    valueToPos = nothing
    if !isnothing(action_space)
        allValuesIdx = indexFromCpVertex.([g], ValueVertex.(action_space))
        valueToPos = Dict{Int64,Int64}()
        for (pos, value) in enumerate(action_space) # TODO : understand why value are all in action space
            valueToPos[value] = pos
        end
    end

    sr = HeterogeneousStateRepresentation{F,TS}(g, nothing, nothing, nothing, nothing, nothing, allValuesIdx, valueToPos, nothing, nothing, 0, 0, 0)
    sr.variableNodeFeatures, sr.constraintNodeFeatures, sr.valueNodeFeatures = featurize(sr; chosen_features=chosen_features)
    sr.globalFeatures = global_featurize(sr)
    return sr
end

function HeterogeneousTrajectoryState(sr::HeterogeneousStateRepresentation{F,HeterogeneousTrajectoryState}) where {F}
    if isnothing(sr.variableIdx)
        throw(ErrorException("Unable to build an HeterogeneousTrajectoryState, when the branching variable is nothing."))
    end
    contovar, valtovar = adjacency_matrices(sr.cplayergraph)
    globalFeatures = isnothing(sr.globalFeatures) ? zeros(0) : sr.globalFeatures
    fg = HeterogeneousFeaturedGraph(contovar, valtovar, sr.variableNodeFeatures, sr.constraintNodeFeatures, sr.valueNodeFeatures, globalFeatures)
    return HeterogeneousTrajectoryState(fg, sr.variableIdx)
end

"""
    update_representation!(sr::HeterogeneousStateRepresentation, model::CPModel, x::AbstractIntVar)

Update the StateRepesentation according to its Type and Featurization.
"""
function update_representation!(sr::HeterogeneousStateRepresentation, model::CPModel, x::AbstractIntVar)
    update_features!(sr, model)
    sr.variableIdx = indexFromCpVertex(sr.cplayergraph, VariableVertex(x)) - sr.cplayergraph.numberOfConstraints
    return sr
end

"""
    featurize(sr::HeterogeneousStateRepresentation{DefaultFeaturization, TS})

Create features for every node of the graph. Can be overwritten for a completely custom featurization.

Default behavior consists in a 3D One-hot vector that encodes whether the node represents a Constraint, a Variable or a Value.

It is also possible to pass a `chosen_features` dictionary allowing to choose among some non mandatory features. 
It will be used in `initChosenFeatures` to initialize `sr.chosenFeatures`. 
See `HeterogeneousStateRepresentation` for a list of possible options.
It is only necessary to specify the options you wish to activate.
"""
function featurize(sr::HeterogeneousStateRepresentation{DefaultFeaturization,TS}; chosen_features::Union{Nothing,Dict{String,Bool}}=nothing) where {TS}
    initChosenFeatures(sr, chosen_features)

    g = sr.cplayergraph
    variableFeatures = zeros(Float32, sr.nbVariableFeatures, g.numberOfVariables)
    constraintFeatures = zeros(Float32, sr.nbConstraintFeatures, g.numberOfConstraints)
    valueFeatures = zeros(Float32, sr.nbValueFeatures, g.numberOfValues)
    ncon = sr.cplayergraph.numberOfConstraints
    nvar = sr.cplayergraph.numberOfVariables
    for i in 1:nv(g)
        cp_vertex = SeaPearl.cpVertexFromIndex(g, i)
        if isa(cp_vertex, VariableVertex)
            if sr.chosenFeatures["variable_initial_domain_size"][1]
                variableFeatures[sr.chosenFeatures["variable_initial_domain_size"][2], i - ncon] = length(cp_vertex.variable.domain)
            end
            if sr.chosenFeatures["variable_domain_size"][1]
                variableFeatures[sr.chosenFeatures["variable_domain_size"][2], i - ncon] = length(cp_vertex.variable.domain)
            end
            if sr.chosenFeatures["variable_is_bound"][1]
                variableFeatures[sr.chosenFeatures["variable_is_bound"][2], i - ncon] = isbound(cp_vertex.variable)
            end
        end
        if isa(cp_vertex, ConstraintVertex)
            if sr.chosenFeatures["constraint_activity"][1]
                if isa(cp_vertex.constraint, ViewConstraint)
                    constraintFeatures[sr.chosenFeatures["constraint_activity"][2], i] = isbound(cp_vertex.constraint.parent)
                else
                    constraintFeatures[sr.chosenFeatures["constraint_activity"][2], i] = cp_vertex.constraint.active.value
                end
            end
            if sr.chosenFeatures["nb_involved_constraint_propagation"][1]
                constraintFeatures[sr.chosenFeatures["nb_involved_constraint_propagation"][2], i] = 0
            end
            if sr.chosenFeatures["nb_not_bounded_variable"][1]
                variables = variablesArray(cp_vertex.constraint)
                constraintFeatures[sr.chosenFeatures["nb_not_bounded_variable"][2], i] = count(x -> !isbound(x), variables)
            end
            if sr.chosenFeatures["constraint_type"][1]
                constraintFeatures[sr.constraintTypeToId[typeof(cp_vertex.constraint)], i] = 1
                if isa(cp_vertex.constraint, ViewConstraint)
                    if isa(cp_vertex.constraint.child, IntVarViewMul)
                        constraintFeatures[sr.constraintTypeToId[typeof(cp_vertex.constraint) + 1], i] = cp_vertex.constraint.child.a
                    elseif isa(cp_vertex.constraint.child, IntVarViewOffset)
                        constraintFeatures[sr.constraintTypeToId[typeof(cp_vertex.constraint) + 2], i] = cp_vertex.constraint.child.c
                    elseif isa(cp_vertex.constraint.child, IntVarViewOpposite)
                        constraintFeatures[sr.constraintTypeToId[typeof(cp_vertex.constraint) + 1], i] = -1
                    elseif isa(cp_vertex.constraint.child, BoolVarViewNot)
                        constraintFeatures[sr.constraintTypeToId[typeof(cp_vertex.constraint) + 3], i] = 1
                    else
                        error("WARNING: Unknown VarViewType: please implement DefaultFeaturization for this type!")
                    end
                end
            end
        end
        if isa(cp_vertex, ValueVertex)
            if sr.chosenFeatures["values_raw"][1]
                valueFeatures[sr.chosenFeatures["values_raw"][2], i - ncon - nvar] = cp_vertex.value
            end
            if sr.chosenFeatures["values_onehot"][1]
                cp_vertex_idx = sr.valueToPos[cp_vertex.value]
                valueFeatures[sr.chosenFeatures["values_onehot"][2] + cp_vertex_idx - 1, i - ncon - nvar] = 1
            end
        end
    end

    return variableFeatures, constraintFeatures, valueFeatures
end

"""
    initChosenFeatures(sr::HeterogeneousStateRepresentation{DefaultFeaturization,TS}, chosen_features::Dict{String,Bool})

Builds the `sr.chosenFeatures` dictionary  and sets `sr.nbFeatures`.
"""
function initChosenFeatures(sr::HeterogeneousStateRepresentation{DefaultFeaturization,TS}, chosen_features::Union{Nothing,Dict{String,Bool}}) where {TS}
    # Initialize chosenFeatures with all positions at -1 and presence to false
    sr.chosenFeatures = Dict{String,Tuple{Bool,Int64}}(
        "constraint_activity" => (false, -1),
        "constraint_type" => (false, -1),
        "nb_involved_constraint_propagation" => (false, -1),
        "nb_not_bounded_variable" => (false, -1),
        "variable_domain_size" => (false, -1),
        "variable_initial_domain_size" => (false, -1),
        "variable_is_bound" => (false, -1),
        "values_onehot" => (false, -1),
        "values_raw" => (false, -1),
    )

    variable_counter = 1
    constraint_counter = 1
    value_counter = 1
    if !isnothing(chosen_features)
        if haskey(chosen_features, "constraint_activity") && chosen_features["constraint_activity"]
            sr.chosenFeatures["constraint_activity"] = (true, constraint_counter)
            constraint_counter += 1
        end

        if haskey(chosen_features, "nb_involved_constraint_propagation") && chosen_features["nb_involved_constraint_propagation"]
            sr.chosenFeatures["nb_involved_constraint_propagation"] = (true, constraint_counter)
            constraint_counter += 1
        end

        if haskey(chosen_features, "variable_initial_domain_size") && chosen_features["variable_initial_domain_size"]
            sr.chosenFeatures["variable_initial_domain_size"] = (true, variable_counter)
            variable_counter += 1
        end

        if haskey(chosen_features, "variable_domain_size") && chosen_features["variable_domain_size"]
            sr.chosenFeatures["variable_domain_size"] = (true, variable_counter)
            variable_counter += 1
        end

        if haskey(chosen_features, "variable_is_bound") && chosen_features["variable_is_bound"]
            sr.chosenFeatures["variable_is_bound"] = (true, variable_counter)
            variable_counter += 1
        end

        if haskey(chosen_features, "nb_not_bounded_variable") && chosen_features["nb_not_bounded_variable"]
            sr.chosenFeatures["nb_not_bounded_variable"] = (true, constraint_counter)
            constraint_counter += 1
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
                        constraint_counter += 4 
                    else
                        constraint_counter += 1
                    end
                end
            end
            sr.constraintTypeToId = constraintTypeToId
        end

        if haskey(chosen_features, "values_raw") && chosen_features["values_raw"]
            sr.chosenFeatures["values_raw"] = (true, value_counter)
            value_counter += 1
        end

        if haskey(chosen_features, "values_onehot") && chosen_features["values_onehot"]
            sr.chosenFeatures["values_onehot"] = (true, value_counter)
            value_counter += sr.cplayergraph.numberOfValues
        end
    end
    sr.nbVariableFeatures = variable_counter - 1
    sr.nbConstraintFeatures = constraint_counter - 1
    sr.nbValueFeatures = value_counter - 1
end

"""
    update_features!(sr::HeterogeneousStateRepresentation{DefaultFeaturization,TS}, ::CPModel)

Updates the features of the graph nodes. 

Use the `sr.chosenFeatures` dictionary to find out which features are used and their positions in the vector.
"""
function update_features!(sr::HeterogeneousStateRepresentation{DefaultFeaturization,TS}, ::CPModel) where {TS}
    g = sr.cplayergraph
    ncon = sr.cplayergraph.numberOfConstraints
    nvar = sr.cplayergraph.numberOfVariables
    for i in 1:nv(g)
        cp_vertex = SeaPearl.cpVertexFromIndex(g, i)
        if isa(cp_vertex, VariableVertex)
            if sr.chosenFeatures["variable_domain_size"][1]
                sr.variableNodeFeatures[sr.chosenFeatures["variable_domain_size"][2], i - ncon] = length(cp_vertex.variable.domain)
            end

            if sr.chosenFeatures["variable_is_bound"][1]
                sr.variableNodeFeatures[sr.chosenFeatures["variable_is_bound"][2], i - ncon] = isbound(cp_vertex.variable)
            end
        end
        if isa(cp_vertex, ConstraintVertex)
            if sr.chosenFeatures["constraint_activity"][1]
                if isa(cp_vertex.constraint, ViewConstraint)
                    sr.constraintNodeFeatures[sr.chosenFeatures["constraint_activity"][2], i] = isbound(cp_vertex.constraint.parent)
                else
                    sr.constraintNodeFeatures[sr.chosenFeatures["constraint_activity"][2], i] = cp_vertex.constraint.active.value
                end
            end

            if sr.chosenFeatures["nb_involved_constraint_propagation"][1]
                sr.constraintNodeFeatures[sr.chosenFeatures["nb_involved_constraint_propagation"][2], i] = sr.cplayergraph.cpmodel.statistics.numberOfTimesInvolvedInPropagation[cp_vertex.constraint]
            end

            if sr.chosenFeatures["nb_not_bounded_variable"][1]
                variables = variablesArray(cp_vertex.constraint)
                sr.constraintNodeFeatures[sr.chosenFeatures["nb_not_bounded_variable"][2], i] = count(x -> !isbound(x), variables)
            end
        end
        if isa(cp_vertex, ValueVertex) # Probably useless, check before removing
            if sr.chosenFeatures["values_raw"][1]
                sr.valueNodeFeatures[sr.chosenFeatures["values_raw"][2], i - ncon - nvar] = cp_vertex.value
            end

            if sr.chosenFeatures["values_onehot"][1]
                cp_vertex_idx = sr.valueToPos[cp_vertex.value]
                sr.valueNodeFeatures[sr.chosenFeatures["values_onehot"][2]+cp_vertex_idx-1, i - ncon - nvar] = 1
            end
        end
    end
end
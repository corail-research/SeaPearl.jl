include("cp_layer/cp_layer.jl")

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
    constraintNodeFeatures::Union{Nothing,AbstractMatrix{Float32}}
    variableNodeFeatures::Union{Nothing,AbstractMatrix{Float32}}
    valueNodeFeatures::Union{Nothing,AbstractMatrix{Float32}}
    globalFeatures::Union{Nothing,AbstractVector{Float32}}
    variableIdx::Union{Nothing,Int64}
    allValuesIdx::Union{Nothing,Vector{Int64}}
    valueToPos::Union{Nothing,Dict{Int64,Int64}}
    chosenFeatures::Union{Nothing,Dict{String,Tuple{Bool,Int64}}}
    constraintTypeToId::Union{Nothing,Dict{Type,Int}}
    nbFeatures::Int64
end
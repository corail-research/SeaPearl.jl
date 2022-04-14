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
end

function DefaultStateRepresentation{F,TS}(model::CPModel; action_space=nothing, chosen_features=nothing) where {F,TS}
    g = CPLayerGraph(model)
    allValuesIdx = nothing
    if !isnothing(action_space)
        allValuesIdx = indexFromCpVertex.([g], ValueVertex.(action_space))
    end
    sr = DefaultStateRepresentation{F,TS}(g, nothing, nothing, nothing, allValuesIdx)
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
Featurization helper: initializes the graph with the features specified as arguments.
"""
function featurize(sr::DefaultStateRepresentation{FeaturizationHelper,TS}; chosen_features::Dict{String,Bool}) where {TS}
    constraint_activity = chosen_features["constraint_activity"]
    variable_initial_domain_size = chosen_features["variable_initial_domain_size"]
    nb_involved_contraint_propagation = chosen_features["nb_involved_contraint_propagation"]
    values_onehot = chosen_features["values_onehot"]
    
    g = sr.cplayergraph
    nb_features = 3
    if values_onehot
        nb_features += g.numberOfValues
    end
    nb_features += constraint_activity + variable_initial_domain_size + nb_involved_contraint_propagation

    features = zeros(Float32, nb_features, nv(g))
    for i in 1:nv(g)
        cp_vertex = SeaPearl.cpVertexFromIndex(g, i)
        counter = 4
        if isa(cp_vertex, ConstraintVertex)
            features[1, i] = 1.0f0
            if constraint_activity
                features[counter, i] = cp_vertex.constraint.active.value
                counter += 1
            end
            if nb_involved_contraint_propagation
                features[counter, i] = 0
                counter += 1
            end
        end
        if isa(cp_vertex, VariableVertex)
            features[2, i] = 1.0f0
            if variable_initial_domain_size
                features[counter, i] = length(cp_vertex.variable.domain)
                counter += 1
            end
        end
        if isa(cp_vertex, ValueVertex)
            features[3, i] = 1.0f0
            if values_onehot
                cp_vertex_idx = find(x -> x == cp_vertex.value, sr.allValuesIdx)
                features[counter+cp_vertex_idx, i] = 1
            else
                features[counter, i] = cp_vertex.value
            end
        end
    end
    sr.chosenFeatures = Dict{String,Bool}(
        "values_onehot" => values_onehot,
        "constraint_activity" => constraint_activity,
        "variable_initial_domain_size" => variable_initial_domain_size,
        "nb_involved_contraint_propagation" => nb_involved_contraint_propagation
    )
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

# function update_features!(sr::Type{<:FeaturizedStateRepresentation{FeaturizationHelper,TS}}, ::CPModel) where {TS}
#     println(sr.features_chosen)
# end
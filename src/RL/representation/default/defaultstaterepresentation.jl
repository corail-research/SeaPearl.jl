include("cp_layer/cp_layer.jl")

"""
    DefaultStateRepresentation{F, TS}

This is the default representation used by SeaPearl unless the user define his own.

It consists in a tripartite graph representation of the CP Model, with features associated with each node
and an index specifying the variable that should be branched on.
"""
mutable struct DefaultStateRepresentation{F, TS} <: FeaturizedStateRepresentation{F, TS}
    cplayergraph::CPLayerGraph
    nodeFeatures::Union{Nothing, AbstractMatrix{Float32}}
    globalFeatures::Union{Nothing, AbstractVector{Float32}}
    variableIdx::Union{Nothing, Int64}
    allValuesIdx::Union{Nothing, Vector{Int64}}
end

function DefaultStateRepresentation{F, TS}(model::CPModel; action_space=nothing) where {F, TS}
    g = CPLayerGraph(model)
    allValuesIdx = nothing
    if !isnothing(action_space)
        allValuesIdx = indexFromCpVertex.([g], ValueVertex.(action_space))
    end
    sr = DefaultStateRepresentation{F, TS}(g, nothing, nothing, nothing, allValuesIdx)
    sr.nodeFeatures = featurize(sr)
    sr.globalFeatures = global_featurize(sr)
    return sr
end

function DefaultTrajectoryState(sr::DefaultStateRepresentation{F, DefaultTrajectoryState}) where F
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
    featurize(sr::DefaultStateRepresentation{DefaultFeaturization, TS})

Create features for every node of the graph. Supposed to be overwritten.

Default behavior consists in a 3D One-hot vector that encodes whether the node represents a Constraint, a Variable or a Value.
"""
function featurize(sr::FeaturizedStateRepresentation{DefaultFeaturization, TS}) where TS
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
    feature_length(gen::AbstractModelGenerator, ::Type{FeaturizedStateRepresentation})

Returns the length of the feature vector, for the `DefaultFeaturization`.
"""
feature_length(::Type{<:FeaturizedStateRepresentation{DefaultFeaturization, TS}}) where TS <: DefaultTrajectoryState = 3

DefaultStateRepresentation(m::CPModel) = DefaultStateRepresentation{DefaultFeaturization, DefaultTrajectoryState}(m::CPModel)

include("cp_layer/cp_layer.jl")

"""
    DefaultStateRepresentation{F, TS}

This is the default representation used by SeaPearl unless the user define his own and give
the information to his LearnedHeurstic when defining it. 
"""
mutable struct DefaultStateRepresentation{F, TS} <: FeaturizedStateRepresentation{F, TS}
    cplayergraph::CPLayerGraph
    features::Union{Nothing, AbstractArray{Float32, 2}}
    variable_id::Union{Nothing, Int64}
end

function DefaultStateRepresentation{F, TS}(model::CPModel) where {F, TS}
    g = CPLayerGraph(model)
    sr = DefaultStateRepresentation{F, TS}(g, nothing, nothing)

    sr.features = featurize(sr)
    sr
end

""" 
    function update_representation!(sr::DefaultStateRepresentation, model::CPModel, x::AbstractIntVar)

While working with DefaultStateRepresentation, at each step of the research node, only the variable_id need to be updated. 
features don't need to be updated as they encode the initial problem and the CPLayerGraph is automatically updated as it is linked to the CPModel. 
"""
function update_representation!(sr::DefaultStateRepresentation, model::CPModel, x::AbstractIntVar)
    update_features!(sr, model)
    sr.variable_id = indexFromCpVertex(sr.cplayergraph, VariableVertex(x))
    sr
end

function trajectoryState(sr::DefaultStateRepresentation{F, TS}) where {F, TS}
    return TS(sr)
end

struct DefaultFeaturization <: AbstractFeaturization end

"""
    function featurize(sr::DefaultStateRepresentation{DefaultFeaturization, TS})

Create features for every node of the graph. Supposed to be overwritten. 
Default behavior is to call `default_featurize` which consists in 3D One-hot vector that encodes whether the node represents a Constraint, a Variable or a Value 
"""
function featurize(sr::DefaultStateRepresentation{DefaultFeaturization, TS}) where TS
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

function update_features!(::DefaultStateRepresentation{DefaultFeaturization, TS}, ::CPModel) where TS end

"""
    feature_length(gen::AbstractModelGenerator, ::Type{DefaultStateRepresentation{DefaultFeaturization}})

Returns the length of the feature vector, useful for SeaPearl to choose the size of the container
"""
feature_length(gen::SeaPearl.AbstractModelGenerator, ::Type{DefaultStateRepresentation{DefaultFeaturization, TS}}) where TS = 3

struct DefaultTrajectoryState <: NonTabularTrajectoryState
    fg::GraphSignals.FeaturedGraph
    variabeIdx::Int
end

struct BatchedDefaultTrajectoryState{S, T} <: NonTabularTrajectoryState
    adjacencies::AbstractArray{S, 3}
    features::AbstractArray{T, 3}
    variables::AbstractVector{Int}
end

function DefaultTrajectoryState(sr::DefaultStateRepresentation{F, DefaultTrajectoryState}) where {F}
    if isnothing(sr.variable_id)
        throw(ErrorException("Unable to build a DefaultTrajectoryState, when the branching variable is nothing."))
    end
    adj = adjacency_matrix(sr.cplayergraph)
    fg = FeaturedGraph(adj; nf=sr.features)
    return DefaultTrajectoryState(fg, sr.variable_id)
end

DefaultStateRepresentation(m::CPModel) = DefaultStateRepresentation{DefaultFeaturization, DefaultTrajectoryState}(m::CPModel)



include("cp_layer/cp_layer.jl")

"""
    DefaultStateRepresentation{F, TS}

This is the default representation used by SeaPearl unless the user define his own.

It consists in a tripartite graph representation of the CP Model, with features associated with each node
and an index specifying the variable that should be branched on.
"""
mutable struct DefaultStateRepresentation{F, TS} <: FeaturizedStateRepresentation{F, TS}
    cplayergraph::CPLayerGraph
    features::Union{Nothing, AbstractArray{Float32, 2}}
    variableIdx::Union{Nothing, Int64}
end

function DefaultStateRepresentation{F, TS}(model::CPModel) where {F, TS}
    g = CPLayerGraph(model)
    sr = DefaultStateRepresentation{F, TS}(g, nothing, nothing)
    sr.features = featurize(sr)
    return sr
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

"""
    trajectoryState(sr::DefaultStateRepresentation{F, TS})
    
Return a TrajectoryState based on the present state represented by `sr`.

The type of the returned object is defined by the `TS` parametric type defined in `sr`.
"""
trajectoryState(sr::DefaultStateRepresentation{F, TS}) where {F, TS} = TS(sr)

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
feature_length(::Type{<:FeaturizedStateRepresentation{DefaultFeaturization, TS}}) where TS = 3

"""
    DefaultTrajectoryState

The most basic state representation, with a featured graph and the index of the variable to branch on.
"""
struct DefaultTrajectoryState <: NonTabularTrajectoryState
    fg::GraphSignals.FeaturedGraph
    variableIdx::Int
end

"""
    BatchedDefaultTrajectoryState

The batched version of the `DefaultTrajectoryState`.

It contains all the information that would be stored in a `FeaturedGraph` but reorganised to enable simultaneous 
computation on a few graphs.
"""
Base.@kwdef struct BatchedDefaultTrajectoryState <: NonTabularTrajectoryState
    adjacencies::Union{AbstractArray, Nothing} = nothing
    nodeFeatures::Union{AbstractArray, Nothing} = nothing
    edgeFeatures::Union{AbstractArray, Nothing} = nothing
    globalFeatures::Union{AbstractArray, Nothing} = nothing
    variables::Union{AbstractVector{Int}, Nothing} = nothing
end

function DefaultTrajectoryState(sr::DefaultStateRepresentation{F, DefaultTrajectoryState}) where {F}
    if isnothing(sr.variableIdx)
        throw(ErrorException("Unable to build a DefaultTrajectoryState, when the branching variable is nothing."))
    end
    adj = Matrix(adjacency_matrix(sr.cplayergraph))
    fg = FeaturedGraph(adj; nf=sr.features)
    return DefaultTrajectoryState(fg, sr.variableIdx)
end

"""
    Flux.functor(::Type{DefaultTrajectoryState}, s)

Utility function used to load data on the working device.

To be noted: this behavior isn't standard, as the function returned creates a `BatchedDefaultTrajectoryState`
rather than a `DefaultTrajectoryState`. This behavior makes it possible to dynamically split the matrices of insterest
from the `FeaturedGraph` wrapper.
"""
function Flux.functor(::Type{DefaultTrajectoryState}, s)
    adj = Flux.unsqueeze(adjacency_matrix(s.fg), 3)
    nf = Flux.unsqueeze(s.fg.nf, 3)
    ef = Flux.unsqueeze(s.fg.ef, 3)
    gf = Flux.unsqueeze(s.fg.gf, 2)
    return (adj, nf, ef, gf), ls -> BatchedDefaultTrajectoryState(
        adjacencies = ls[1],
        nodeFeatures = ls[2],
        edgeFeatures = ls[3],
        globalFeatures = ls[4],
        variables = [s.variableIdx]
    )
end

"""
    Flux.functor(::Type{Vector{DefaultTrajectoryState}}, s)

Utility function used to load data on the working device.

To be noted: this behavior isn't standard, as the function returned creates a `BatchedDefaultTrajectoryState`
rather than a `Vector{DefaultTrajectoryState}`. This behavior makes it possible to dynamically creates matrices of 
the appropriated size to store all the graphs in 3D tensors.
"""
function Flux.functor(::Type{Vector{DefaultTrajectoryState}}, v)
    maxNode = Base.maximum(s -> nv(s.fg), v)
    batchSize = length(v)

    adjacencies = zeros(eltype(v[1].fg.nf), maxNode, maxNode, batchSize)
    nodeFeatures = zeros(eltype(v[1].fg.nf), size(v[1].fg.nf, 1), maxNode, batchSize)
    edgeFeatures = zeros(eltype(v[1].fg.ef), size(v[1].fg.ef, 1), maxNode, batchSize)
    globalFeatures = zeros(eltype(v[1].fg.gf), size(v[1].fg.gf, 1), batchSize)
    variables = ones(Int, batchSize)
    
    Zygote.ignore() do
        # TODO: this could probably be optimized
        foreach(enumerate(v)) do (idx, state)
            adj = adjacency_matrix(state.fg)
            adjacencies[1:size(adj,1),1:size(adj,2),idx] = adj
            nodeFeatures[1:size(state.fg.nf, 1),1:size(state.fg.nf, 2),idx] = state.fg.nf
            edgeFeatures[1:size(state.fg.ef, 1),1:size(state.fg.ef, 2),idx] = state.fg.ef
            globalFeatures[1:size(state.fg.gf, 1),idx] = state.fg.gf
            variables[idx] = state.variableIdx
        end
    end
    
    return (adjacencies, nodeFeatures, edgeFeatures, globalFeatures), ls -> BatchedDefaultTrajectoryState(
        adjacencies = ls[1], 
        nodeFeatures = ls[2],
        edgeFeatures = ls[3],
        globalFeatures = ls[4],
        variables)
end

DefaultStateRepresentation(m::CPModel) = DefaultStateRepresentation{DefaultFeaturization, DefaultTrajectoryState}(m::CPModel)



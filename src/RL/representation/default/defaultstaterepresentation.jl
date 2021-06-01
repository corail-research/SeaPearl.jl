
struct DefaultFeaturization <: AbstractFeaturization end

include("cp_layer/cp_layer.jl")

"""
    DefaultStateRepresentation{F}

This is the default representation used by SeaPearl unless the user define his own and give
the information to his LearnedHeurstic when defining it. 
"""
mutable struct DefaultStateRepresentation{F} <: FeaturizedStateRepresentation{F}
    cplayergraph::CPLayerGraph
    features::Union{Nothing, AbstractArray{Float32, 2}}
    variable_id::Union{Nothing, Int64}
end

function DefaultStateRepresentation{F}(model::CPModel) where F
    g = CPLayerGraph(model)
    sr = DefaultStateRepresentation{F}(g, nothing, nothing, nothing)

    features = featurize(sr)
    sr.features = transpose(features)
    sr
end

DefaultStateRepresentation(m::CPModel) = DefaultStateRepresentation{DefaultFeaturization}(m::CPModel)

""" 
        function update_representation!(sr::DefaultStateRepresentation, model::CPModel, x::AbstractIntVar)

While working with DefaultStateRepresentation, at each step of the research node, only the variable_id need to be updated. 
features don't need to be updated as they encode the initial problem and the CPLayerGraph is automatically updated as it is linked to the CPModel. 
"""
function update_representation!(sr::DefaultStateRepresentation, model::CPModel, x::AbstractIntVar)
    sr.variable_id = indexFromCpVertex(sr.cplayergraph, VariableVertex(x))
    sr
end

"""
        function featuredgraph(array::Array{Float32, 2}, ::Type{DefaultStateRepresentation})::GeometricFlux.FeaturedGraph

#TODO analyse and comment featured graph
"""
function featuredgraph(array::AbstractArray{Float32, 2}, ::Type{DefaultStateRepresentation})::GeometricFlux.FeaturedGraph
    # Here we only take what's interesting, removing all null values that are there only to accept bigger graphs
    row_indexes = findall(x -> x == 1, array[:, 1])
    col_indexes = vcat(1 .+ row_indexes, (size(array, 1)+2):size(array, 2))
    array = array[row_indexes, col_indexes]
    
    n = size(array, 1)
    dense_adj = array[:, 1:n]
    features = array[:, n+1:end-2]
    fg = GraphSignals.FeaturedGraph(dense_adj; nf=permutedims(features, [2, 1])) # Cannot use `transpose` to transpose here, see https://github.com/yuehhua/GraphSignals.jl/pull/19
    return fg
end

"""
    function featurize(sr::DefaultStateRepresentation{DefaultFeaturization})

Create features for every node of the graph. Supposed to be overwritten. 
Default behavior is to call `default_featurize` which consists in 3D One-hot vector that encodes whether the node represents a Constraint, a Variable or a Value 
"""
function featurize(sr::DefaultStateRepresentation{DefaultFeaturization})
    g = sr.cplayergraph
    features = zeros(Float32, nv(g), 3)
    for i in 1:nv(g)
        cp_vertex = SeaPearl.cpVertexFromIndex(g, i)
        if isa(cp_vertex, ConstraintVertex)    
            features[i, 1] = 1.0f0
        end
        if isa(cp_vertex, VariableVertex)
            features[i, 2] = 1.0f0
        end
        if isa(cp_vertex, ValueVertex)
            features[i, 3] = 1.0f0
        end
    end
    features
end

"""
    feature_length(gen::AbstractModelGenerator, ::Type{DefaultStateRepresentation{DefaultFeaturization}})

Returns the length of the feature vector, useful for SeaPearl to choose the size of the container
"""
feature_length(gen::SeaPearl.AbstractModelGenerator, ::Type{DefaultStateRepresentation{DefaultFeaturization}}) = 3




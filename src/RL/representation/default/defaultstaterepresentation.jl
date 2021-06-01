using GraphPlot

struct DefaultFeaturization <: AbstractFeaturization end


include("cp_layer/cp_layer.jl")

"""
    DefaultStateRepresentation{F}

This is the default representation used by SeaPearl unless the user define his own and give
the information to his LearnedHeurstic when defining it.
"""
mutable struct DefaultStateRepresentation{F} <: FeaturizedStateRepresentation{F}
    cplayergraph::CPLayerGraph
    features::Union{Nothing, Array{Float32, 2}}
    variable_id::Union{Nothing, Int64}
    possible_value_ids::Union{Nothing, Array{Int64}}
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

While working with DefaultStateRepresentation, at each step of the research node, only the variable_id and the possible_value_ids need to be updated.
features don't need to be updated as they encode the initial problem and the CPLayerGraph is automatically updated as it is linked to the CPModel.
"""
function update_representation!(sr::DefaultStateRepresentation, model::CPModel, x::AbstractIntVar)
    sr.variable_id = indexFromCpVertex(sr.cplayergraph, VariableVertex(x))
    sr.possible_value_ids = possible_values(sr.variable_id, sr.cplayergraph)
    sr
end

"""
        function to_arraybuffer(sr::DefaultStateRepresentation, rows=nothing::Union{Nothing, Int})::Array{Float32, 2}

This function encodes the DefaultStateRepresentation in a Array{Float32, 2}. This function is usefull as the trajectory buffer can only stock Array.
The argument "rows" allows the user to define the fixed size of the array that will encode the state. This is usefull as the size of the trajectory buffer
is fixed in advance. This method makes the array-encoding robust to different instance size as long as the size does not exceed the maximum size defined
by "rows". Such an encoding is a key element in the quest for generalization over different instances of a same problem.

#TODO precisely describe the array construction whether rows=nothing or not.
"""
function to_arraybuffer(sr::DefaultStateRepresentation, rows=nothing::Union{Nothing, Int})::Array{Float32, 2}
    adj = Matrix(LightGraphs.LinAlg.adjacency_matrix(sr.cplayergraph))
    var_id = sr.variable_id

    var_code = zeros(Float32, size(adj, 1))
    var_code[var_id] = 1f0

    vector_values = zeros(Float32, size(adj, 1))
    for i in sr.possible_value_ids
        vector_values[i] = 1.
    end


    if isnothing(rows)
        return hcat(ones(Float32, size(adj, 1), 1), adj, transpose(sr.features), var_code, vector_values)
    end

    @assert rows > size(adj, 1) "maxNumberOfCPNodes too small"

    cp_graph_array = hcat(ones(Float32, size(adj, 1), 1), adj, zeros(Float32, size(adj, 1), rows - size(adj, 1)), transpose(sr.features), var_code, vector_values)
    filler = zeros(Float32, rows - size(cp_graph_array, 1), size(cp_graph_array, 2))


    return vcat(cp_graph_array, filler)

end
"""
        function featuredgraph(array::Array{Float32, 2}, ::Type{DefaultStateRepresentation})::GeometricFlux.FeaturedGraph

#TODO analyse and comment featured graph
"""
function featuredgraph(array::Array{Float32, 2}, ::Type{DefaultStateRepresentation})::GeometricFlux.FeaturedGraph
    # Here we only take what's interesting, removing all null values that are there only to accept bigger graphs
    row_indexes = findall(x -> x == 1, array[:, 1])
    col_indexes = vcat(1 .+ row_indexes, (size(array, 1)+2):size(array, 2))
    array = view(array, row_indexes, col_indexes)

    n = size(array, 1)
    dense_adj = array[:, 1:n]
    features = array[:, n+1:end-2]

    return GraphSignals.FeaturedGraph(dense_adj; nf=permutedims(features, [2, 1])) # Cannot use `transpose` to transpose here, see https://github.com/yuehhua/GraphSignals.jl/pull/19
end

function branchingvariable_id(array::Array{Float32, 2}, ::Type{DefaultStateRepresentation})::Int64
    findfirst(x -> x == 1, array[:, end-1])
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

"""
    function possible_values(variable_id::Int64, g::CPLayerGraph)

Return the ids of the values that the variable denoted by `variable_id` can take.
It actually returns the id of every ValueVertex neighbors of the VariableVertex.

"""
function possible_values(variable_id::Int64, g::CPLayerGraph)
    possible_values = LightGraphs.neighbors(g, variable_id)
    filter!((id) -> isa(cpVertexFromIndex(g, convert(Int64, id)), ValueVertex), possible_values)
    return possible_values
end

"""
    function possible_value_ids(array::Array{Float32, 2})

Returns the ids of the ValueVertex that are in the domain of the variable we are branching on.
"""
function possible_value_ids(array::Array{Float32, 2}, ::Type{DefaultStateRepresentation})
    findall(x -> x == 1, array[:, end])
end

function print_tripartite(sr::DefaultStateRepresentation)
    cpmodel = sr.cplayergraph
    n = cpmodel.totalLength
    nodefillc = []
    for id in 1:n
        v = cpmodel.idToNode[id]
        if isa(v, VariableVertex) push!(nodefillc,"red")
        elseif isa(v, ValueVertex) push!(nodefillc,"blue")
        else  push!(nodefillc,"black") end
    end
    gplot(cpmodel;nodefillc=nodefillc)
end

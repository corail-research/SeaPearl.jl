using SparseArrays

mutable struct CPGraph
    featuredgraph::GeometricFlux.FeaturedGraph
    variable_id::Int64
    possible_value_ids::Array{Int64}
end

"""
    function featurize(cpmodel::CPModel)

Create features for every node of the graph. Supposed to be overwritten. 
Default behavior is to call `default_featurize`.
"""
featurize(g::CPLayerGraph) = default_featurize(g::CPLayerGraph)

"""
    function default_featurize(g::CPLayerGraph)

Create a feature consisting of a one-hot encoder for the type of vertex (variable, constraint or value).
Hence it is a feature of size 3.
"""
function default_featurize(g::CPLayerGraph)
    features = zeros(Float32, nv(g), 3)
    for i in 1:nv(g)
        cp_vertex = CPRL.cpVertexFromIndex(g, i)
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
    CPGraph(cplayergraph::CPLayerGraph, var_id::Int64)

Construct a CPGraph from the CPModel and the id (in the graph) of the variable we want to branch on. 
"""
function CPGraph(cpmodel::CPModel, variable_id::Int64)
    # graph
    g = CPLayerGraph(cpmodel)
    sparse_adj = LightGraphs.LinAlg.adjacency_matrix(g)
    # feature
    feature = featurize(g)

    values = Int64[]
    if !isempty(cpmodel) && variable_id > 0
        values = possible_values(variable_id, g)
    end

    # all together
    CPGraph(GeometricFlux.FeaturedGraph(sparse_adj, transpose(feature)), variable_id, values)
end

"""
For convenience during tests but might be deleted later.
"""
function CPGraph(cpmodel::CPModel, x::AbstractIntVar)
    variable_id = indexFromCpVertex(CPLayerGraph(cpmodel), VariableVertex(x))
    CPGraph(cpmodel, variable_id)
end

"""
    CPGraph(array::Array{Float32})

Takes an array an go back to a CPGraph 
"""
function CPGraph(array::Array{Float32, 2})::CPGraph

    # Here we only take what's interesting, removing all null values that are there only to accept bigger graphs
    row_indexes = findall(x -> x == 1, array[:, 1])
    col_indexes = vcat(1 .+ row_indexes, (size(array, 1)+2):size(array, 2))
    array = view(array, row_indexes, col_indexes)
    
    n = size(array, 1)
    dense_adj = array[:, 1:n]
    features = array[:, n+1:end-2]

    var_code = array[:, end-1]
    var_code = findall(x -> x == 1, var_code)
    values_vector = array[:, end]
    possible_value_ids = findall(x -> x == 1, values_vector)

    fg = GeometricFlux.FeaturedGraph(dense_adj, transpose(features))
    return CPGraph(fg, convert(Int64, var_code[1]), possible_value_ids)
end

"""
    function possible_values(cpgraph::CPGraph, g::CPLayerGraph)

Return the ids of the values that the variable denoted by `variable_id` can take.
It actually returns the id of every ValueVertex neighbors of the VariableVertex.
"""
function possible_values(variable_id::Int64, g::CPLayerGraph)
    possible_values = LightGraphs.neighbors(g, variable_id)
    filter!((id) -> isa(cpVertexFromIndex(g, convert(Int64, id)), ValueVertex), possible_values)
    return possible_values
end

#Base.ndims(g::CPGraph) = ndims(feature(g.featuredgraph))
#Base.size(g::CPGraph) = size(feature(g.featuredgraph))
#Base.reshape(g::CPGraph, t) = FeaturedGraph(graph(g.graoh), reshape(feature(g.featuredgraph), t))

"""
    update!(cpgraph::CPGraph, g::CPLayerGraph, x::AbstractIntVar)

Update a CPGraph instance thanks to a new CPLayerGraph and a new Variable. 
The only thing that stay identic is basically the feature matrix.

---------- WARNING : 
At the moment, we are using GeometricFlux.FeaturedGraph, which is immutable, so
we could change the pointer ref or change elements after elements in the sparse 
adjacency matrix. But in order to get the things done quickly, we will start by ignoring 
the update!() function and we will create a new FeaturedGraph when we want to update
CPGraph.
"""
function update_graph!(cpgraph::CPGraph, g::CPLayerGraph, x::AbstractIntVar)
    cpgraph.variable_id = indexFromCpVertex(g, VariableVertex(x))
    cpgraph.possible_value_ids = possible_values(cpgraph.variable_id, g)

    feature = cpgraph.featuredgraph.feature[]
    sparse_adj = LightGraphs.LinAlg.adjacency_matrix(g)

    cpgraph.featuredgraph = GeometricFlux.FeaturedGraph(sparse_adj, feature)
    nothing
end

"""
    to_array(cpg::CPGraph, rows=nothing::Union{Nothing, Int})

Takes a CPGraph and transform it to an array having `rows` rows, filling the remaining rows
with zeros if needed. If `rows` is not given, will return the minimum number of rows.
"""
function to_array(cpg::CPGraph, rows=nothing::Union{Nothing, Int})::Array{Float32, 2}
    adj = Matrix(cpg.featuredgraph.graph[])
    features = cpg.featuredgraph.feature[]
    var_id = cpg.variable_id

    var_code = zeros(Float32, size(adj, 1))
    var_code[var_id] = 1f0

    vector_values = zeros(Float32, size(adj, 1))
    for i in cpg.possible_value_ids
        vector_values[i] = 1.
    end

    
    if isnothing(rows)
        return hcat(ones(Float32, size(adj, 1), 1), adj, transpose(features), var_code, vector_values)
    end

    cp_graph_array = hcat(ones(Float32, size(adj, 1), 1), adj, zeros(Float32, size(adj, 1), rows - size(adj, 1)), transpose(features), var_code, vector_values)
    filler = zeros(Float32, rows - size(cp_graph_array, 1), size(cp_graph_array, 2))

    return vcat(cp_graph_array, filler)
end

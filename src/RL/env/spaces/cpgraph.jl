using SparseArrays

mutable struct CPGraph
    featuredgraph::GeometricFlux.FeaturedGraph
    variable_id::Int64
end

"""
    featurize(cpmodel::CPModel)

Create features that will be associated to every node of the graph. This is a default value
but a user might overwrite it if he wants.
"""
function featurize(g::CPLayerGraph)
    features = zeros(Float32, nv(g), nv(g))
    for i in 1:size(features)[1]
        features[i, i] = 1.0f0
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

    # all together
    CPGraph(GeometricFlux.FeaturedGraph(sparse_adj, transpose(feature)), variable_id)
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
    n = size(array, 1)
    dense_adj = array[:, 1:n]
    features = array[:, n+1:end-1]

    var_code = array[:, end]
    var_code = findall(x -> x == 1, var_code)

    fg = GeometricFlux.FeaturedGraph(dense_adj, transpose(features))
    return CPGraph(fg, convert(Int64, var_code[1]))
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

    feature = cpgraph.featuredgraph.feature[]
    sparse_adj = LightGraphs.LinAlg.adjacency_matrix(g)

    cpgraph.featuredgraph = GeometricFlux.FeaturedGraph(sparse_adj, feature)
    nothing
end

"""
    to_array(cpg::CPGraph)

Takes a CPGraph and transform it to an array.
"""
function to_array(cpg::CPGraph)::Array{Float32, 2}
    adj = Matrix(cpg.featuredgraph.graph[])
    features = cpg.featuredgraph.feature[]
    var_id = cpg.variable_id

    var_code = zeros(Float32, size(adj, 1))
    var_code[var_id] = 1f0

    return hcat(adj, transpose(features), var_code)
end

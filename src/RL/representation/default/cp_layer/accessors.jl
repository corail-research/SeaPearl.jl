
"""
    function arrayOfEveryValue(variables::Array{AbstractIntVar})

Return an array containing every possible values in the domain of every variable
in `variables`, without duplicates.
"""
function arrayOfEveryValue(variables::Array{AbstractIntVar})
    setOfValues = Set{Int}()
    for x in variables
        for value in x.domain
            push!(setOfValues, value)
        end
    end
    return collect(setOfValues)
end

"""
    function cpVertexFromIndex(graph::CPLayerGraph, id::Int)

Returns a `CPLayerVertex` corresponding to the index given.
"""
function cpVertexFromIndex(graph::CPLayerGraph, id::Int)
    return graph.idToNode[id]
end

"""
    function indexFromCpVertex(g::CPLayerGraph, v::CPLayerVertex)

Returns the integer corresponding to `v` in graph `g`.
"""
function indexFromCpVertex(g::CPLayerGraph, v::CPLayerVertex)
    return g.nodeToId[v]
end

Base.eltype(g::CPLayerGraph) = Int64
LightGraphs.edgetype(g::CPLayerGraph) = LightGraphs.SimpleEdge{eltype(g)}
LightGraphs.has_vertex(g::CPLayerGraph, v::Int) = 1 <= v && v <= g.totalLength

function LightGraphs.has_edge(g::CPLayerGraph, s::Int64, d::Int64)
    if d < s
        s, d = d, s
    end

    LightGraphs.has_edge(g, cpVertexFromIndex(g, s), cpVertexFromIndex(g, d))
end

LightGraphs.has_edge(g::CPLayerGraph, s::FixedEdgesVertex, d::FixedEdgesVertex) = LightGraphs.has_edge(g.fixedEdgesGraph, indexFromCpVertex(g, s), indexFromCpVertex(g, d))
LightGraphs.has_edge(g::CPLayerGraph, s::ConstraintVertex, d::ValueVertex) = false
LightGraphs.has_edge(g::CPLayerGraph, s::VariableVertex, d::ValueVertex) = d.value in s.variable.domain

LightGraphs.has_edge(g::CPLayerGraph, s::ValueVertex, d::ValueVertex) = false

function LightGraphs.edges(g::CPLayerGraph)
    if isnothing(g.cpmodel)
        return []
    end
    edgesSet = Set{LightGraphs.edgetype(g::CPLayerGraph)}()

    for id in (g.numberOfConstraints + 1):(g.numberOfConstraints + g.numberOfVariables)
        xVertex = cpVertexFromIndex(g, id)
        @assert isa(xVertex, VariableVertex)
        x = xVertex.variable
        # TODO: investigate this condition
        if is_branchable(g.cpmodel, x)
            union!(edgesSet, map(v -> LightGraphs.edgetype(g::CPLayerGraph)(id, g.nodeToId[ValueVertex(v)]), x.domain))
        end
    end

    union!(edgesSet, LightGraphs.edges(g.fixedEdgesGraph))

    return collect(edgesSet)
end

function LightGraphs.ne(g::CPLayerGraph)
    if isnothing(g.cpmodel)
        return 0
    end
    numberOfEdges = LightGraphs.ne(g.fixedEdgesGraph)
    for id in (g.numberOfConstraints + 1):(g.numberOfConstraints + g.numberOfVariables)
        xVertex = cpVertexFromIndex(g, id)
        if is_branchable(g.cpmodel, xVertex.variable)
            numberOfEdges += length(xVertex.variable.domain)
        end
    end
    return numberOfEdges
end

LightGraphs.nv(g::CPLayerGraph) = g.totalLength
LightGraphs.nv(::Nothing) = 0

function LightGraphs.inneighbors(g::CPLayerGraph, id::Int)
    if isnothing(g.cpmodel)
        return []
    end
    cpVertex = cpVertexFromIndex(g, id)
    LightGraphs.inneighbors(g, cpVertex)
end
LightGraphs.outneighbors(g::CPLayerGraph, id::Int) = LightGraphs.inneighbors(g, id)

LightGraphs.inneighbors(g::CPLayerGraph, v::ConstraintVertex) = LightGraphs.inneighbors(g.fixedEdgesGraph, g.nodeToId[v])
function LightGraphs.inneighbors(g::CPLayerGraph, vertex::VariableVertex)
    constraints = LightGraphs.inneighbors(g.fixedEdgesGraph, g.nodeToId[vertex])
    x = vertex.variable
    if !is_branchable(g.cpmodel, x)
        return constraints
    end
    values = zeros(length(x.domain))
    i = 1
    for v in x.domain
        values[i] = g.nodeToId[ValueVertex(v)]
        i += 1
    end
    return vcat(constraints, values)
end
function LightGraphs.inneighbors(g::CPLayerGraph, vertex::ValueVertex)
    value = vertex.value
    neigh = Int64[]
    for i in (g.numberOfConstraints + 1):(g.numberOfConstraints + g.numberOfVariables)
        xVertex = cpVertexFromIndex(g, i)
        x = xVertex.variable
        if is_branchable(g.cpmodel, x)
            if value in x.domain
                push!(neigh, indexFromCpVertex(g, VariableVertex(x)))
            end
        end
    end
    return neigh
end

LightGraphs.vertices(g::CPLayerGraph) = collect(1:(g.totalLength))

LightGraphs.is_directed(g::CPLayerGraph) = false
LightGraphs.is_directed(g::Type{CPLayerGraph}) = false

Base.zero(::Type{CPLayerGraph}) = CPLayerGraph()
Base.reverse(g::CPLayerGraph) = g

function LightGraphs.SimpleGraph(cplayergraph::CPLayerGraph)
    graph = LightGraphs.Graph(LightGraphs.edges(cplayergraph))
    n = LightGraphs.nv(cplayergraph)
    if LightGraphs.nv(graph) < n
        LightGraphs.add_vertices!(graph, n - LightGraphs.nv(graph))
    end
    return graph
end

function LightGraphs.adjacency_matrix(cplayergraph::CPLayerGraph)
    return LightGraphs.adjacency_matrix(Graph(cplayergraph))
end

function adjacency_matrices(cplayergraph::CPLayerGraph)
    g = LightGraphs.Graph(cplayergraph) # Update the graph with the new information
    nvar = cplayergraph.numberOfVariables
    ncon = cplayergraph.numberOfConstraints
    nval = cplayergraph.numberOfValues
    contovar = zeros(ncon, nvar)
    valtovar = zeros(nval, nvar)
    for (i, node) in enumerate(cplayergraph.idToNode)
        if isa(node, ConstraintVertex)
            neighbors = LightGraphs.outneighbors(g, i)
            for neighbor in neighbors
                contovar[i, neighbor - ncon] = 1
            end
        elseif isa(node, ValueVertex)
            neighbors = LightGraphs.outneighbors(g, i)
            for neighbor in neighbors
                valtovar[i - ncon - nvar, neighbor - ncon] = 1
            end
        end
    end
    return contovar, valtovar
end
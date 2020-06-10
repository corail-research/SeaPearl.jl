
abstract type CPLayerVertex end
abstract type FixedEdgesVertex <: CPLayerVertex end
struct ValueVertex <: CPLayerVertex 
    value       ::Int
end
struct ConstraintVertex <: FixedEdgesVertex
    constraint  ::Constraint
end
struct VariableVertex <: FixedEdgesVertex 
    variable    ::AbstractIntVar
end

struct CPLayerGraph <: AbstractGraph{Int} 
    inner                       ::Union{CPModel, Nothing}
    idToNode                    ::Array{CPLayerVertex}
    nodeToId                    ::Dict{CPLayerVertex, Int}
    fixedEdgesGraph             ::Graph
    numberOfConstraints         ::Int
    numberOfVariables           ::Int
    numberOfValues              ::Int
    totalLength                 ::Int

    function CPLayerGraph(cpmodel::CPModel)
        variables = collect(values(cpmodel.variables))
        valuesOfVariables = arrayOfEveryValue(variables)
        numberOfConstraints = length(cpmodel.constraints)
        numberOfVariables = length(variables)
        numberOfValues = length(valuesOfVariables)
        totalLength = numberOfConstraints + numberOfVariables + numberOfValues



        nodeToId = Dict{CPLayerVertex, Int}()
        idToNode = Array{CPLayerVertex}(undef, totalLength)

        # Filling constraints
        for i in 1:numberOfConstraints
            idToNode[i] = ConstraintVertex(cpmodel.constraints[i])
            nodeToId[ConstraintVertex(cpmodel.constraints[i])] = i
        end

        # Filling variables
        for i in 1:numberOfVariables
            idToNode[numberOfConstraints + i] = VariableVertex(variables[i])
            nodeToId[VariableVertex(variables[i])] = numberOfConstraints + i
        end

        # Filling values
        for i in 1:numberOfValues
            idToNode[numberOfConstraints + numberOfVariables + i] = ValueVertex(valuesOfVariables[i])
            nodeToId[ValueVertex(valuesOfVariables[i])] = numberOfConstraints + numberOfVariables + i
        end

        
        fixedEdgesGraph = Graph(numberOfConstraints + numberOfVariables)
        for id in 1:numberOfConstraints
            constraint = idToNode[id].constraint
            varArray = variablesArray(constraint)
            for x in varArray
                add_edge!(fixedEdgesGraph, id, nodeToId[VariableVertex(x)])
            end
        end

        return new(cpmodel, idToNode, nodeToId, fixedEdgesGraph, numberOfConstraints, numberOfVariables, numberOfValues, totalLength)
    end
    function CPLayerGraph()
        return new(nothing, CPLayerVertex[], Dict{CPLayerVertex, Int}(), Graph(0), 0, 0, 0, 0)
    end
end




function arrayOfEveryValue(variables::Array{AbstractIntVar})
    setOfValues = Set{Int}()
    for x in variables
        for value in x.domain
            push!(setOfValues, value)
        end
    end
    return collect(setOfValues)
end

function cpVertexFromIndex(graph::CPLayerGraph, id::Int)
    return graph.idToNode[id]
end
function index(g::CPLayerGraph, v::CPLayerVertex)
    return g.nodeToId[v]
end

Base.eltype(g::CPLayerGraph) = Int64
LightGraphs.edgetype(g::CPLayerGraph) = LightGraphs.SimpleEdge{eltype(g)}
LightGraphs.is_directed(::Type{CPLayerGraph}) = false
LightGraphs.has_vertex(g::CPLayerGraph, v::Int) = 1 <= v && v <= g.totalLength

function LightGraphs.has_edge(g::CPLayerGraph, s::Int64, d::Int64)
    if d > s
        s, d = d, s
    end

    LightGraphs.has_edge(g, cpVertexFromIndex(g, s), cpVertexFromIndex(g, d))
end

LightGraphs.has_edge(g::CPLayerGraph, s::FixedEdgesVertex, d::FixedEdgesVertex) = LightGraphs.has_edge(g.fixedEdgesGraph, index(g, s), index(g, d))
LightGraphs.has_edge(g::CPLayerGraph, s::ConstraintVertex, d::ValueVertex) = false
LightGraphs.has_edge(g::CPLayerGraph, s::VariableVertex, d::ValueVertex) = d in s.variable.domain
LightGraphs.has_edge(g::CPLayerGraph, s::ValueVertex, d::ValueVertex) = false

function LightGraphs.edges(g::CPLayerGraph)
    if isnothing(g.inner)
        return []
    end
    edgesSet = Set{edgetype(g::CPLayerGraph)}()

    for id in (g.numberOfConstraints + 1):(g.numberOfConstraints + g.numberOfVariables)
        xVertex = cpVertexFromIndex(g, id)
        @assert isa(xVertex, VariableVertex)
        x = xVertex.variable
        for v in x.domain
            push!(edgesSet, edgetype(g::CPLayerGraph)(id, g.nodeToId[ValueVertex(v)]))
        end
    end

    for edge in edges(g.fixedEdgesGraph)
        push!(edgesSet, edgetype(g::CPLayerGraph)(src(edge), dst(edge)))
    end

    return collect(edgesSet)
end

function LightGraphs.ne(g::CPLayerGraph)
    if isnothing(g.inner)
        return 0
    end
    numberOfEdges = LightGraphs.ne(g.fixedEdgesGraph)
    for id in (g.numberOfConstraints + 1):(g.numberOfConstraints + g.numberOfVariables)
        xVertex = cpVertexFromIndex(g, id)
        numberOfEdges += length(xVertex.variable.domain)
    end
    return numberOfEdges
end

LightGraphs.nv(g::CPLayerGraph) = g.totalLength

function LightGraphs.inneighbors(g::CPLayerGraph, id::Int)
    if isnothing(g.inner)
        return []
    end
    cpVertex = cpVertexFromIndex(g, id)
    LightGraphs.inneighbors(g, cpVertex)
end
LightGraphs.outneighbors(g::CPLayerGraph, id::Int) = inneighbors(g, id)

LightGraphs.inneighbors(g::CPLayerGraph, v::ConstraintVertex) = LightGraphs.inneighbors(g.fixedEdgesGraph, g.nodeToId[v])
function LightGraphs.inneighbors(g::CPLayerGraph, vertex::VariableVertex)
    constraints = LightGraphs.inneighbors(g.fixedEdgesGraph, g.nodeToId[vertex])
    x = vertex.variable
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
        if value in x.domain
            push!(neigh, index(g, VariableVertex(x)))
        end
    end
    return neigh
end

LightGraphs.vertices(g::CPLayerGraph) = collect(1:(g.totalLength))

LightGraphs.is_directed(g::CPLayerGraph) = false
LightGraphs.is_directed(g::Type{CPLayerGraph}) = false

Base.zero(::Type{CPLayerGraph}) = CPLayerGraph()
Base.reverse(g::CPLayerGraph) = g

function labelOfVertex(g::CPLayerGraph, d::Int64)
    cpVertex = cpVertexFromIndex(g, d)
    labelOfVertex(g, cpVertex)
end

labelOfVertex(g::CPLayerGraph, d::ConstraintVertex) = string(typeof(d.constraint)), 1
labelOfVertex(g::CPLayerGraph, d::VariableVertex) = "x"*d.variable.id, 2
labelOfVertex(g::CPLayerGraph, d::ValueVertex) = string(d.value), 3


struct CPLayerGraph <: AbstractGraph{Int} 
    inner                       ::Union{CPModel, Nothing}
    values                      ::Array{Int}
    valueToId                   ::Dict{Int, Int}
    numberOfConstraints         ::Int
    numberOfVariables           ::Int
    numberOfValues              ::Int
    constraintToId              ::Dict{Constraint, Int}
    variableToId                ::Dict{AbstractIntVar, Int}

    function CPLayerGraph(cpmodel::CPModel)
        values = arrayOfEveryValue(cpmodel.variables)
        numberOfConstraints = length(cpmodel.constraints)
        numberOfVariables = length(cpmodel.variables)


        valueToId = Dict{Int, Int}()
        for i in 1:length(values)
            valueToId[values[i]] = numberOfConstraints + numberOfVariables + i
        end

        constraintToId = Dict{Constraint, Int}()
        for i in 1:numberOfConstraints
            constraintToId[cpmodel.constraints[i]] = i
        end

        variableToId = Dict{AbstractIntVar, Int}()
        for i in 1:numberOfVariables
            variableToId[cpmodel.variables[i]] = numberOfConstraints + i
        end


        return new(cpmodel, values, valueToId, numberOfConstraints, numberOfVariables, length(values), constraintToId, variableToId)
    end
    function CPLayerGraph()
        return new(nothing, Int[], Dict{Int, Int}(), 0, 0, 0, Dict{Constraint, Int}(), Dict{AbstractIntVar, Int}())
    end
end

abstract type CPVertex end
struct ConstraintNode <: CPVertex end

function arrayOfEveryValue(variables::Array{AbstractIntVar})
    setOfValues = Set{Int}()
    for x in variables
        for value in x.domain
            push!(setOfValues, value)
        end
    end
    return collect(setOfValues)
end

function cpFromIndex(graph::CPLayerGraph, id::Int)
    if 1 <= id && id <= graph.numberOfConstraints
        return graph.inner.constraints[id]
    end
    id -= graph.numberOfConstraints
    if 1 <= id && id <= graph.numberOfVariables
        return graph.inner.variables[id]
    end
    id -= graph.numberOfVariables
    if 1 <= id && id <= graph.numberOfValues
        return graph.values[id]
    end
    throw(ErrorException("Index outside of possible values, must be between 1 and numberOfConstraints + numberOfVariables + numberOfValues"))
end

Base.eltype(g::CPLayerGraph) = Int
edgetype(g::CPLayerGraph) = LightGraphs.SimpleEdge{eltype(g)})
is_directed(::Type{CPLayerGraph}) = false
has_vertex(g::CPLayerGraph, v::Int) = 1 <= v && v <= g.numberOfConstraints + g.numberOfVariables + g.numberOfValues

function has_edge(g::CPLayerGraph, s::Int, d::Int)
    if !has_vertex(g, s) || !has_vertex(g, d)
        return false
    end
    if d > s
        s, d = d, s
    end

    has_edge(g, cpFromIndex(g, s), cpFromIndex(g, d))
end

has_edge(g::CPLayerGraph, s::Constraint, d::Int) = false
has_edge(g::CPLayerGraph, s::AbstractIntVar, d::Int) = d in s.domain
has_edge(g::CPLayerGraph, s::NotEqual, d::AbstractIntVar) = d == s.x || d == s.y
has_edge(g::CPLayerGraph, s::SumToZero, d::AbstractIntVar) = d in s.x

function edges(g::CPLayerGraph)
    if isnothing(g.inner)
        return []
    end
    edgesSet = Set{edgetype(g::CPLayerGraph)}()

    for id in 1:g.numberOfConstraints
        constraint = cpFromIndex(g, id)
        varArray = variablesArray(constraint)
        for x in varArray
            push!(edgesSet, edgetype(g::CPLayerGraph)(id, g.variableToId[x]))
        end
    end

    for id in g.numberOfConstraints:(g.numberOfConstraints + g.numberOfVariables)
        x = cpFromIndex(g, id)
        for v in x.domain
            push!(edgesSet, edgetype(g::CPLayerGraph)(id, g.valueToId[v]))
        end
    end
    return collect(edgesSet)
end

function ne(g::CPLayerGraph)
    if isnothing(g.inner)
        return 0
    end
    numberOfEdges = 0
    for id in 1:g.numberOfConstraints
        constraint = cpFromIndex(g, id)
        varArray = variablesArray(constraint)
        numberOfEdges += length(varArray)
    end
    for id in g.numberOfConstraints:(g.numberOfConstraints + g.numberOfVariables)
        x = cpFromIndex(g, id)
        numberOfEdges += length(x.domain)
    end
    return numberOfEdges
end

nv(g::CPLayerGraph) = g.numberOfConstraints + g.numberOfVariables + g.numberOfValues

function inneighbors(g::CPLayerGraph, id::Int)
    if isnothing(g.inner)
        return []
    end
    cpVertex = cpFromIndex(g, id)
    inneighbors(g, cpVertex)
end
outneighbors(g::CPLayerGraph, id::Int) = inneighbors(g, id)

inneighbors(g::CPLayerGraph, constraint::Constraint) = map((x) -> g.variableToId[x], variablesArray(constraint))
function inneighbors(g::CPLayerGraph, x::AbstractIntVar)
    constraints = map((x) -> g.constraintToId[x], getOnDomainChange(x))
    values = zeros(length(x.domain))
    i = 1
    for v in x.domain
        values[i] = g.valueToId[v]
        i += 1
    end
    return vcat(constraints, values)
end

vertices(g::CPLayerGraph) = 1:(g.numberOfConstraints + g.numberOfVariables + g.numberOfValues)

is_directed(g::CPLayerGraph) = false
is_directed(g::Type{CPLayerGraph}) = false

zero(::Type{CPLayerGraph}) = CPLayerGraph()
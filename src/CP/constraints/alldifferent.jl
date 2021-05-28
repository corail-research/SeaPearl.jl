include("algorithms/matching.jl")

@enum State begin
    used = 1
    unused = 2
    removed = 3
    vital = 4
end

"""
    AllDifferent(x::Array{<:AbstractIntVar}, trailer)

AllDifferent constraint, enforcing ∀ i ≠ j ∈ ⟦1, length(x)⟧, x[i] ≠ x[j].

The implementation of this contraint is inspired by:
 https://www.researchgate.net/publication/200034395_A_Filtering_Algorithm_for_Constraints_of_Difference_in_CSPs
Many of the functions below relate to algorithms depicted in the paper, and their
documentation refer to parts of the overall algorithm.
"""
struct AllDifferent <: Constraint
    x::Array{<:AbstractIntVar}
    active::StateObject{Bool}
    initialized::StateObject{Bool}
    matching::Vector{StateObject{Pair{Int, Int}}}
    edgesState::Dict{Edge{Int}, StateObject{State}}
    nodesMin::Int
    numberOfVars::Int
    numberOfVals::Int

    function AllDifferent(x::Array{<:AbstractIntVar}, trailer)::AllDifferent
        max = Base.maximum(var -> maximum(var.domain), x)
        min = Base.minimum(var -> minimum(var.domain), x)
        range = max - min + 1
        active = StateObject{Bool}(true, trailer)
        initialized = StateObject{Bool}(false, trailer)
        numberOfVars = length(x)
        matching = Vector{StateObject{Pair{Int, Int}}}(undef, numberOfVars)
        for i = 1:numberOfVars
            matching[i] = StateObject{Pair{Int, Int}}(Pair(0, 0), trailer)
        end
        edgesState = Dict{Edge{Int}, StateObject{State}}()
        constraint = new(x,
            active,
            initialized,
            matching,
            edgesState,
            min,
            numberOfVars,
            range)
        for (idx, var) in enumerate(x)
            addOnDomainChange!(var, constraint)
            for val in var.domain
                dst = numberOfVars + val - min + 1
                constraint.edgesState[Edge(idx, dst)] = StateObject(unused, trailer)
            end
        end
        return constraint
    end
end

"""
    valToNode(constraint, value)::Int

Return the node index of a value.
"""
function valToNode(con::AllDifferent, val::Int)
    return con.numberOfVars + val - con.nodesMin + 1
end

"""
    nodeToVal(constraint, node)::Int

Return the underlying value of a node.
"""
function nodeToVal(con::AllDifferent, node::Int)
    return node - con.numberOfVars + con.nodesMin - 1
end

"""
    orderEdge(edge)::Edge

Return the ordered version of an edge, i.e. with e.src ≤ e.dst.
"""
function orderEdge(e::Edge{Int})::Edge{Int}
    src, dst = e.src < e.dst ? (e.src, e.dst) : (e.dst, e.src)
    return Edge(src, dst)
end

"""
    initializeGraphs!(constraint)

Return the graph and the empty direct graph of a variable-value problem.
"""
function initializeGraphs!(con::AllDifferent)::Pair{Graph{Int}, DiGraph{Int}}
    graph = Graph(con.numberOfVars + con.numberOfVals)
    digraph = DiGraph(nv(graph))
    for (e, status) in con.edgesState
        if status.value != removed
            add_edge!(graph, e.src, e.dst)
        end
    end
    return Pair(graph, digraph)
end

"""
    getAllEdges(digraph, parents)::Set{Edge}

Return all the edges visited by a BFS on `digraph` encoded in `parents`.
"""
function getAllEdges(digraph::DiGraph{Int}, parents::Vector{Int})::Set{Edge{Int}}
    edgeSet = Set{Edge{Int}}()
    for i = 1:nv(digraph)
        if parents[i] > 0 && parents[i] != i
            validneighbors = filter(v -> parents[v] > 0, inneighbors(digraph, i))
            validedges = map(v -> orderEdge(Edge(v, i)), validneighbors)
            union!(edgeSet, validedges)
        end
    end
    return edgeSet
end

"""
    getAllEdges(digraph, vars, vals)

Return all the edges in a strongly connected component vars ∪ vars.
"""
function getAllEdges(digraph::DiGraph{Int}, vars::Vector{Int}, vals::Vector{Int})::Set{Edge{Int}}
    edgeSet = Set{Edge{Int}}()
    for var in vars
        for val in intersect(union(inneighbors(digraph, var), outneighbors(digraph, var)), vals)
            push!(edgeSet, orderEdge(Edge(var, val)))
        end
    end
    return edgeSet
end

"""
    removeEdges!(constraint, prunedValue, graph, digraph)

Remove all the unnecessary edges in graph and digraph as in the original paper.

Update `constraint.edgesState` with the new status of each edge, remove some
edges from `graph` and `digraph` and push the removed values in `prunedValue`.
Following exactly the procedure in the function with the same name in the original
paper.
"""
function removeEdges!(constraint::AllDifferent, prunedValues::Vector{Vector{Int}}, graph::Graph{Int}, digraph::DiGraph{Int})
    for e in edges(graph)
        if constraint.edgesState[orderEdge(e)] != removed
            setValue!(constraint.edgesState[orderEdge(e)], unused)
        end
    end

    allValues = constraint.numberOfVars+1:nv(digraph)
    freeValues = filter(v -> indegree(digraph,v) == 0, allValues)

    seen = fill(false, constraint.numberOfVals)
    components = filter(comp -> length(comp)>1, strongly_connected_components(digraph))
    for component in components
        variables = filter(v -> v <= constraint.numberOfVars, component)
        values = filter(v -> v > constraint.numberOfVars, component)
        edgeSet = getAllEdges(digraph, variables, values)
        for e in edgeSet
            setValue!(constraint.edgesState[e], used)
        end
    end
    for node in freeValues
        if seen[node - constraint.numberOfVars]
            continue
        end
        parents = bfs_parents(digraph, node; dir=:out)
        edgeSet = getAllEdges(digraph, parents)
        for e in edgeSet
            setValue!(constraint.edgesState[e], used)
        end
        reached = filter(v -> parents[v] > 0, allValues)
        for val in reached
            seen[val - constraint.numberOfVars] = true
        end
    end

    for pair in constraint.matching
        var, val = pair.value
        e = Edge(var, val)
        if constraint.edgesState[e].value == unused
            setValue!(constraint.edgesState[e], vital)
        end
    end

    rest = findall(state -> state.value == unused, constraint.edgesState)
    for e in rest
        rem_edge!(graph, e)
        rem_edge!(digraph, Edge(e.dst, e.src))
        setValue!(constraint.edgesState[e], removed)
        var, val = e.src < e.dst ? (e.src, e.dst) : (e.dst, e.src)
        push!(prunedValues[var], nodeToVal(constraint, val))
    end
end

"""
    updateEdgesState!(constraint)::Set{Edge}

Return all the pruned values not already encoded in the constraint state.
"""
function updateEdgesState!(constraint::AllDifferent)
    modif = Set{Edge}()
    for (edge, state) in constraint.edgesState
        if state.value != removed && !(nodeToVal(constraint, edge.dst)  in constraint.x[edge.src].domain)
            push!(modif, edge)
        end
    end
    return modif
end

"""
    propagate!(constraint::AllDifferent, toPropagate::Set{Constraint}, prunedDomains::CPModification)

`AllDifferent` propagation function. Implement the full procedure of the paper.
"""
function propagate!(constraint::AllDifferent, toPropagate::Set{Constraint}, prunedDomains::CPModification)
    if !constraint.active.value
        return true
    end

    # Variables Initialization
    graph, digraph = initializeGraphs!(constraint)
    #    Run only once, when constraint is first propagated
    if !constraint.initialized.value
        matching = maximumMatching!(graph, digraph, constraint.numberOfVars)
        if matching.size < constraint.numberOfVars
            return false
        end
        for (idx, match) in enumerate(matching.matches)
            setValue!(constraint.matching[idx], match)
        end
        setValue!(constraint.initialized, true)
    #    Otherwise just read the stored values
    else
        matching = Matching{Int}(length(constraint.matching), map(pair -> pair.value, constraint.matching))
        buildDigraph!(digraph, graph, matching)
    end

    modifications = updateEdgesState!(constraint)
    prunedValues = Vector{Vector{Int}}(undef, constraint.numberOfVars)
    for i = 1:constraint.numberOfVars
        prunedValues[i] = Int[]
    end

    removeEdges!(constraint, prunedValues, graph, digraph)
    needrematching = false
    for e in modifications
        rev_e = Edge(e.dst, e.src)
        if e in edges(graph)
            if constraint.edgesState[e].value == vital
                return false
            elseif e in edges(digraph)
                needrematching = true
                rem_edge!(digraph, e)
            else
                rem_edge!(digraph, rev_e)
            end
            rem_edge!(graph, e)
            setValue!(constraint.edgesState[e], removed)
        end
    end

    if needrematching
        matching = maximizeMatching!(digraph, constraint.numberOfVars)
        if matching.size < constraint.numberOfVars
            return false
        end
        for (idx, match) in enumerate(matching.matches)
            setValue!(constraint.matching[idx], match)
        end
    end
    removeEdges!(constraint, prunedValues, graph, digraph)

    for (prunedVar, var) in zip(prunedValues, constraint.x)
        if !isempty(prunedVar)
            for val in prunedVar
                remove!(var.domain, val)
            end
            triggerDomainChange!(toPropagate, var)
            addToPrunedDomains!(prunedDomains, var, prunedVar)
        end
    end

    if constraint in toPropagate
        pop!(toPropagate, constraint)
    end

    if all(var -> length(var.domain) <= 1, constraint.x)
        setValue!(constraint.active, false)
    end

    for var in constraint.x
        if isempty(var.domain)
            return false
        end
    end
    return true
end

variablesArray(constraint::AllDifferent) = constraint.x

function Base.show(io::IO, ::MIME"text/plain", con::AllDifferent)
    println(io, string(typeof(con)), ": ", join([var.id for var in con.x], " != "), ", active = ", con.active)
    for var in con.x
        println(io, "   ", var)
    end
end

function Base.show(io::IO, con::AllDifferent)
    println(io, string(typeof(con)), ": ", join([var.id for var in con.x], " != "))
end

include("algorithms/matching.jl")

@enum State begin
    used = 1
    unused = 2
    removed = 3
    vital = 4
end

"""
    AllDifferent(x::Vector{SeaPearl.AbstractIntVar}, trailer)

AllDifferent constraint, enforcing ∀ i ≠ j ∈ ⟦1, length(x)⟧, x[i] ≠ x[j].

The implementation of this contraint is inspired by:
 https://www.researchgate.net/publication/200034395_A_Filtering_Algorithm_for_Constraints_of_Difference_in_CSPs
Many of the functions below relate to algorithms depicted in the paper, and their
documentation refer to parts of the overall algorithm.
"""
struct AllDifferent <: Constraint
    x::Vector{SeaPearl.AbstractIntVar}
    active::StateObject{Bool}
    initialized::StateObject{Bool}
    minimum::StateObject{Int}
    maximum::StateObject{Int}
    matched::StateObject{Int}
    matching::Vector{StateObject{Pair{Int, Int}}}
    edgesState::Dict{Edge{Int}, StateObject{State}}
    nodesMin::Int
    numberOfVars::Int
    numberOfVals::Int

    function AllDifferent(x::Vector{SeaPearl.AbstractIntVar}, trailer)::AllDifferent
        max = Base.maximum(var -> maximum(var.domain), x)
        min = Base.minimum(var -> minimum(var.domain), x)
        range = max - min + 1
        active = StateObject{Bool}(true, trailer)
        initialized = StateObject{Bool}(false, trailer)
        numberOfVars = length(x)
        matched = StateObject{Int}(-1, trailer)
        matching = Vector{StateObject{Pair{Int, Int}}}(undef, numberOfVars)
        for i = 1:numberOfVars
            matching[i] = StateObject{Pair{Int, Int}}(Pair(0, 0), trailer)
        end
        edgesState = Dict{Edge{Int}, StateObject{State}}()
        constraint = new(x,
            active,
            initialized,
            StateObject{Int}(min, trailer),
            StateObject{Int}(max, trailer),
            matched,
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
    val2node(constraint, value)::Int

Return the node index of a value.
"""
function val2node(con::AllDifferent, val::Int)
    return con.numberOfVars + val - con.nodesMin + 1
end

"""
    node2val(constraint, node)::Int

Return the underlying value of a node.
"""
function node2val(con::AllDifferent, node::Int)
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
    getalledges(digraph, parents)::Set{Edge}

Return all the edges visited by a BFS on `digraph` encoded in `parents`.
"""
function getalledges(digraph::DiGraph{Int}, parents::Vector{Int})::Set{Edge{Int}}
    res = Set{Edge{Int}}()
    for i = 1:nv(digraph)
        if parents[i] > 0 && parents[i] != i
            validneighbors = filter(v -> parents[v] > 0, inneighbors(digraph, i))
            validedges = map(v -> orderEdge(Edge(v, i)), validneighbors)
            union!(res, validedges)
        end
    end
    return res
end

"""
    getalledges(digraph, vars, vals)

Return all the edges in a strongly connected component vars ∪ vars.
"""
function getalledges(digraph::DiGraph{Int}, vars::Vector{Int}, vals::Vector{Int})::Set{Edge{Int}}
    res = Set{Edge{Int}}()
    for var in vars
        for val in intersect(union(inneighbors(digraph, var), outneighbors(digraph, var)), vals)
            push!(res, orderEdge(Edge(var, val)))
        end
    end
    return res
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

    allvar = 1:constraint.numberOfVars
    allval = constraint.numberOfVars+1:nv(digraph)
    freeval = filter(v -> indegree(digraph,v) == 0, allval)

    seen = fill(false, constraint.numberOfVals)
    components = filter(comp -> length(comp)>1, strongly_connected_components(digraph))
    for component in components
        vars = filter(v -> v <= constraint.numberOfVars, component)
        vals = filter(v -> v > constraint.numberOfVars, component)
        edgeSet = getalledges(digraph, vars, vals)
        for e in edgeSet
            setValue!(constraint.edgesState[e], used)
        end
    end
    for node in freeval
        if seen[node - constraint.numberOfVars]
            continue
        end
        parents = bfs_parents(digraph, node; dir=:out)
        edgeSet = getalledges(digraph, parents)
        for e in edgeSet
            setValue!(constraint.edgesState[e], used)
        end
        reached = filter(v -> parents[v] > 0, allval)
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
        push!(prunedValues[var], node2val(constraint, val))
    end
end

"""
    updateEdgesState!(constraint)::Set{Edge}

Return all the pruned values not already encoded in the constraint state.
"""
function updateEdgesState!(constraint::AllDifferent)
    modif = Set{Edge}()
    for (edge, state) in constraint.edgesState
        if state.value != removed && !(node2val(constraint, edge.dst)  in constraint.x[edge.src].domain)
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
        matching = maximummatching!(graph, digraph, constraint.numberOfVars)
        if matching.size < constraint.numberOfVars
            return false
        end
        setValue!(constraint.matched, matching.size)
        for (idx, match) in enumerate(matching.matches)
            setValue!(constraint.matching[idx], match)
        end
        setValue!(constraint.initialized, true)
    #    Otherwise just read the stored values
    else
        matching = Matching{Int}(constraint.matched.value, map(pair -> pair.value, constraint.matching))
        builddigraph!(digraph, graph, matching)
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
        matching = maximizematching!(graph, digraph, constraint.numberOfVars)
        if matching.size < constraint.numberOfVars
            return false
        end
        setValue!(constraint.matched, matching.size)
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

AllDifferent(x::Vector{IntVar}, trailer) = AllDifferent(Vector{AbstractIntVar}(x), trailer)

variableArray(constraint::AllDifferent) = constraint.x

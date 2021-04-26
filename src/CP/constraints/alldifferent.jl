using LightGraphs
using Random

struct Matching{T}
    size::Int
    matches::Vector{Pair{T, T}}
end

function randommatching(graph::Graph{Int}, lastfirst::Int)::Matching{Int}
    seen = Set{Int}()
    match = Vector{Pair{Int, Int}}()
    for i = 1:lastfirst
        possible = setdiff(neighbors(graph, i), seen)
        if !isempty(possible)
            node = rand(possible)
            push!(match, Pair(i, node))
            push!(seen, node)
        end
    end
    return Matching{Int}(length(match), match)
end

function matchingfromdigraph(digraph::DiGraph{Int}, lastfirst::Int)::Matching{Int}
    matches = Vector{Pair{Int, Int}}()
    for i = 1:lastfirst
        possible = outneighbors(digraph, i)
        if !isempty(possible)
            push!(matches, Pair(i, possible[1]))
        end
    end
    return Matching(length(matches), matches)
end

function augmentmatching!(digraph::DiGraph{Int}, lastfirst::Int, start::Int, free::Vector{Int})::Union{Nothing, Pair{Int, Int}}
    parents = bfs_parents(digraph, start; dir=:out)
    success = sum(parents[free]) > 0
    if !success
        return nothing
    end

    node = free[findfirst(x -> x>0, parents[free])]
    currentnode = node
    parent = parents[currentnode]
    while currentnode != start
        add_edge!(digraph, currentnode, parent)
        rem_edge!(digraph, parent, currentnode)
        currentnode, parent = parent, parents[parent]
    end
    return Pair(node, start)
end

function builddigraph!(digraph::DiGraph{Int}, graph::Graph{Int}, match::Matching{Int})
    rem_edge!.([digraph], edges(digraph))
    for edge in edges(graph)
        src, dst = edge.src > edge.dst ? (edge.src, edge.dst) : (edge.dst, edge.src)
        add_edge!(digraph, src, dst)
    end
    for match in match.matches
        src, dst = match
        add_edge!(digraph, src, dst)
        rem_edge!(digraph, dst, src)
    end
end

function maximummatching!(graph::Graph{Int}, digraph::DiGraph{Int}, lastfirst::Int)::Matching{Int}
    first = randommatching(graph, lastfirst)
    builddigraph!(digraph, graph, first)
    stop = first.size == lastfirst
    freevar = filter(v -> outdegree(digraph, v) == 0, 1:lastfirst)
    freeval = filter(v -> indegree(digraph,v) == 0, lastfirst+1:nv(digraph))
    while !stop
        start = pop!(freeval)
        augment = augmentmatching!(digraph, lastfirst, start, freevar)
        if !isnothing(augment)
            deleteat!(freevar, findfirst(x -> x == augment[1], freevar))
        end
        stop = isempty(freeval) || isempty(freevar)
    end
    matching = matchingfromdigraph(digraph, lastfirst)
    return matching
end


@enum State begin
    used = 1
    unused = 2
    removed = 3
    vital = 4
end

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

function val2node(con::AllDifferent, val::Int)
    return con.numberOfVars + val - con.nodesMin + 1
end

function node2val(con::AllDifferent, node::Int)
    return node - con.numberOfVars + con.nodesMin - 1
end

function orderEdge(e::Edge{Int})::Edge{Int}
    src, dst = e.src < e.dst ? (e.src, e.dst) : (e.dst, e.src)
    return Edge(src, dst)
end

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

function getalledges(digraph::DiGraph{Int}, parents::Vector{Int})::Set{Edge{Int}}
    res = Set{Edge{Int}}()
    reached = findall(v -> parents[v] > 0, 1:nv(digraph))
    for i = 1:nv(digraph)
        if parents[i] > 0 && parents[i] != i
            validneighbors = intersect(reached, inneighbors(digraph, i))
            validedges = map(v -> orderEdge(Edge(v, i)), validneighbors)
            union!(res, validedges)
        end
    end
    return res
end

function getalledges(digraph::DiGraph{Int}, vars::Vector{Int}, vals::Vector{Int})::Set{Edge{Int}}
    res = Set{Edge{Int}}()
    for var in vars
        for val in intersect(union(inneighbors(digraph, var), outneighbors(digraph, var)), vals)
            push!(res, orderEdge(Edge(var, val)))
        end
    end
    return res
end

function removeEdges!(constraint::AllDifferent, prunedValues::Vector{Vector{Int}}, graph::Graph{Int}, digraph::DiGraph{Int})
    for e in edges(graph)
        if constraint.edgesState[orderEdge(e)] != removed
            setValue!(constraint.edgesState[orderEdge(e)], unused)
        end
    end

    allvar = 1:constraint.numberOfVars
    allval = constraint.numberOfVars+1:nv(digraph)
    freevar = filter(v -> outdegree(digraph, v) == 0, allvar)
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

function updateEdgesState!(constraint::AllDifferent)
    modif = Set{Edge}()
    for (edge, state) in constraint.edgesState
        if state.value != removed && !(node2val(constraint, edge.dst)  in constraint.x[edge.src].domain)
            push!(modif, edge)
            setValue!(constraint.edgesState[edge], removed)
        end
    end
    return modif
end


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
        matching = maximummatching!(graph, digraph, constraint.numberOfVars)
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

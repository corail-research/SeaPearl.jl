
struct Matching{T}
    size::Int
    matches::Vector{Pair{T, T}}
end

"""
    randomMatching(graph, lastfirst)::Matching{Int}

Compute a random matching in a bipartite graph, between 1:lastfirst and (lastfirst + 1):nv(graph).
"""
function randomMatching(graph::LightGraphs.Graph{Int}, lastfirst::Int)::Matching{Int}
    nodesSeen = Set{Int}()
    match = Vector{Pair{Int, Int}}()
    for i = 1:lastfirst
        nodesPossible = setdiff(LightGraphs.neighbors(graph, i), nodesSeen)
        if !isempty(nodesPossible)
            node = rand(nodesPossible)
            push!(match, Pair(i, node))
            push!(nodesSeen, node)
        end
    end
    return Matching{Int}(length(match), match)
end

"""
    matchingFromDigraph(digraph, lastfirst)::Matching{Int}

Compute a matching from a directed bipartite graph.

The graph must be bipartite with variables in 1:lastfirst and values in
(lastfirst + 1):nv(digraph). A variable is assigned to a value if the directed
edge (Var => Val) exists.
"""
function matchingFromDigraph(digraph::LightGraphs.DiGraph{Int}, lastfirst::Int)::Matching{Int}
    matches = Vector{Pair{Int, Int}}()
    for i = 1:lastfirst
        nodesPossible = LightGraphs.outneighbors(digraph, i)
        if !isempty(nodesPossible)
            push!(matches, Pair(i, nodesPossible[1]))
        end
    end
    return Matching(length(matches), matches)
end

"""
    augmentMatching!(digraph, lastfirst, start, free)::Union{Nothing, Pair{Int, Int}}

Find an alternating path in a directed graph and augment the current matching.

From a directed bipartite graph, the boundary between the 2 groups, a free value
and an array of the free variables, find an alternating path from a free value to
a free variable and augment the matching.

# Arguments
- `digraph::LightGraphs.DiGraph{Int}`: the directed graph encoding the problem state.
- `lastfirst::Int`: the last element of the first group of nodes.
- `start::Int`: the free value node to start the search from.
- `free::Vector{Int}`: the list of all the free variables indexes.
"""
function augmentMatching!(digraph::LightGraphs.DiGraph{Int}, start::Int, free::Set{Int})::Union{Nothing, Pair{Int, Int}}
    parents = LightGraphs.bfs_parents(digraph, start; dir=:out)
    nodesReached = intersect(free, findall(v -> v > 0, parents))
    if isempty(nodesReached)
        return nothing
    end

    node = pop!(nodesReached)
    currentNode = node
    parent = parents[currentNode]
    while currentNode != start
        LightGraphs.add_edge!(digraph, currentNode, parent)
        LightGraphs.rem_edge!(digraph, parent, currentNode)
        currentNode, parent = parent, parents[parent]
    end
    return Pair(node, start)
end

"""
    buildDigraph!(digraph, graph, matching)

Build a directed bipartite graph, from a graph and a matching solution.

Copy the structure of `graph` into a pre-allocated `digraph` and orient the
edges using the matches contained in `matching`.
"""
function buildDigraph!(digraph::LightGraphs.DiGraph{Int}, graph::LightGraphs.Graph{Int}, match::Matching{Int})
    LightGraphs.rem_edge!.([digraph], LightGraphs.edges(digraph))
    for edge in LightGraphs.edges(graph)
        src, dst = edge.src > edge.dst ? (edge.src, edge.dst) : (edge.dst, edge.src)
        LightGraphs.add_edge!(digraph, src, dst)
    end
    for match in match.matches
        src, dst = match
        LightGraphs.add_edge!(digraph, src, dst)
        LightGraphs.rem_edge!(digraph, dst, src)
    end
end

"""
    maximizematching!(graph, digraph, lastfirst)

Transform a directed graph, which encodes a matching, to encode a maximal matching.

The problem must be encoded in the 2 bipartite graph, and `digraph` must already
encode a partial matching at least. Lastfirst is the index of the last node of
the first group.
"""
function maximizeMatching!(digraph::LightGraphs.DiGraph{Int}, lastfirst::Int)::Matching{Int}
    currentMatching = matchingFromDigraph(digraph, lastfirst)
    stop = currentMatching.size == lastfirst
    freeVariables = Set(filter(v -> LightGraphs.outdegree(digraph, v) == 0, 1:lastfirst))
    freeValues = Set(filter(v -> LightGraphs.indegree(digraph,v) == 0, lastfirst+1:LightGraphs.nv(digraph)))
    while !stop
        start = pop!(freeValues)
        augment = augmentMatching!(digraph, start, freeVariables)
        if !isnothing(augment)
            pop!(freeVariables, augment[1])
        end
        stop = isempty(freeValues) || isempty(freeVariables)
    end
    return matchingFromDigraph(digraph, lastfirst)
end

"""
    maximumMatching!(graph, digraph, lastfirst)::Matching{Int}

Compute a maximum matching from a given bipartite graph.

From a variables-values problem encoded in `graph`, a pre-allocated `digraph` of
the same size, and the index of the last node of the first group, compute a maximum
matching and encode it in `digraph`.
"""
function maximumMatching!(graph::LightGraphs.Graph{Int}, digraph::LightGraphs.DiGraph{Int}, lastfirst::Int)::Matching{Int}
    first = randomMatching(graph, lastfirst)
    buildDigraph!(digraph, graph, first)
    return maximizeMatching!(digraph, lastfirst)
end

using LightGraphs
using Random

struct Matching{T}
    size::Int
    matches::Vector{Pair{T, T}}
end

"""
    randommatching(graph, lastfirst)::Matching{Int}

Compute a random matching in a bipartite graph, between 1:lastfirst and (lastfirst + 1):nv(graph).
"""
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

"""
    matchingfromdigraph(digraph, lastfirst)::Matching{Int}

Compute a matching from a directed bipartite graph.

The graph must be bipartite with variables in 1:lastfirst and values in
(lastfirst + 1):nv(digraph). A variable is assigned to a value if the directed
edge (Var => Val) exists.
"""
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

"""
    augmentmatching!(digraph, lastfirst, start, free)::Union{Nothing, Pair{Int, Int}}

Find an alternating path in a directed graph and augment the current matching.

From a directed bipartite graph, the boundary between the 2 groups, a free value
and an array of the free variables, find an alternating path from a free value to
a free variable and augment the mathcing.

# Arguments
- `digraph::DiGraph{Int}`: the directed graph encoding the problem state.
- `lastfirst::Int`: the last element of the first group of nodes.
- `start::Int`: the free value node to start the search from.
- `free::Vector{Int}`: the list of all the free variables indexes.
"""
function augmentmatching!(digraph::DiGraph{Int}, lastfirst::Int, start::Int, free::Set{Int})::Union{Nothing, Pair{Int, Int}}
    parents = bfs_parents(digraph, start; dir=:out)
    reached = intersect(free, findall(v -> v > 0, parents))
    if isempty(reached)
        return nothing
    end

    node = pop!(reached)
    currentnode = node
    parent = parents[currentnode]
    while currentnode != start
        add_edge!(digraph, currentnode, parent)
        rem_edge!(digraph, parent, currentnode)
        currentnode, parent = parent, parents[parent]
    end
    return Pair(node, start)
end

"""
    builddigraph!(digraph, graph, matching)

Build a directed bipartite graph, from a graph and a matching solution.

Copy the structure of `graph` into a pre-allocated `digraph` and orient the
edges using the matches contained in `matching`.
"""
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

"""
    maximizematching!(graph, digraph, lastfirst)

Transform a directed graph, which encodes a matching, to encode a maximal matching.

The problem must be encoded in the 2 bipartite graph, and `digraph` must already
encode a partial matching at least. Lastfirst is the index of the last node of
the first group.
"""
function maximizematching!(graph::Graph{Int}, digraph::DiGraph{Int}, lastfirst::Int)::Matching{Int}
    currentmatching = matchingfromdigraph(digraph, lastfirst)
    stop = currentmatching.size == lastfirst
    freevar = Set(filter(v -> outdegree(digraph, v) == 0, 1:lastfirst))
    freeval = Set(filter(v -> indegree(digraph,v) == 0, lastfirst+1:nv(digraph)))
    while !stop
        start = pop!(freeval)
        augment = augmentmatching!(digraph, lastfirst, start, freevar)
        if !isnothing(augment)
            pop!(freevar, augment[1])
        end
        stop = isempty(freeval) || isempty(freevar)
    end
    return matchingfromdigraph(digraph, lastfirst)
end

"""
    maximummatching!(graph, digraph, lastfirst)::Matching{Int}

Compute a maximum matching from a given bipartite graph.

From a variables-values problem encoded in `graph`, a pre-allocated `digraph` of
the same size, and the index of the last node of the first group, compute a maximum
matching and encode it in `digraph`.
"""
function maximummatching!(graph::Graph{Int}, digraph::DiGraph{Int}, lastfirst::Int)::Matching{Int}
    first = randommatching(graph, lastfirst)
    builddigraph!(digraph, graph, first)
    return maximizematching!(graph, digraph, lastfirst)
end

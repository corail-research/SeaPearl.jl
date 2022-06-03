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
    matching::Vector{StateObject{Tuple{Int, Int, Bool}}}
    remainingEdges::RSparseBitSet{UInt64}
    edgeToIndex::Dict{Edge{Int}, Int}
    indexToEdge::Vector{Edge{Int}}
    nodesMin::Int
    numberOfVars::Int
    numberOfVals::Int
    numberOfEdges::Int

    function AllDifferent(x::Array{<:AbstractIntVar}, trailer)::AllDifferent
        max = Base.maximum(var -> maximum(var.domain), x)
        min = Base.minimum(var -> minimum(var.domain), x)
        range = max - min + 1
        active = StateObject{Bool}(true, trailer)
        initialized = StateObject{Bool}(false, trailer)
        numberOfVars = length(x)
        numberOfEdges = sum(var -> length(var.domain), x)
        matching = Vector{StateObject{Tuple{Int, Int, Bool}}}(undef, numberOfVars)
        for i = 1:numberOfVars
            matching[i] = StateObject{Tuple{Int, Int, Bool}}((0, 0, false), trailer)
        end
        remainingEdges = RSparseBitSet{UInt64}(numberOfEdges, trailer)
        edgeToIndex = Dict{Edge{Int}, Int}()
        indexToEdge = Vector{Edge{Int}}(undef, numberOfEdges)
        constraint = new(x,
            active,
            initialized,
            matching,
            remainingEdges,
            edgeToIndex,
            indexToEdge,
            min,
            numberOfVars,
            range,
            numberOfEdges
        )
        counter = 1
        for (idx, var) in enumerate(x)
            addOnDomainChange!(var, constraint)
            for val in var.domain
                dst = numberOfVars + val - min + 1
                constraint.edgeToIndex[LightGraphs.Edge(idx, dst)] = counter
                constraint.indexToEdge[counter] = LightGraphs.Edge(idx, dst)
                counter += 1
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
function orderEdge(e::LightGraphs.Edge{Int})::Edge{Int}
    src, dst = e.src < e.dst ? (e.src, e.dst) : (e.dst, e.src)
    return LightGraphs.Edge(src, dst)
end

function updateremaining!(constraint::AllDifferent, removed::BitVector)
    clearMask!(constraint.remainingEdges)
    addToMask!(constraint.remainingEdges, bitVectorToUInt64Vector(removed))
    reverseMask!(constraint.remainingEdges)
    intersectWithMask!(constraint.remainingEdges)
end

function updatevital!(constraint::AllDifferent, vital::BitVector)
    for match in constraint.matching
        e = LightGraphs.Edge(match.value[1], match.value[2])
        idx = constraint.edgeToIndex[e]
        setValue!(match, (e.src, e.dst, vital[idx]))
    end
end

function getvital(constraint)
    vital = BitVector(undef, constraint.numberOfEdges) .= false
    for match in constraint.matching
        if match.value[3]
            vital[constraint.edgeToIndex[LightGraphs.Edge(match.value[1], match.value[2])]] = true
        end
    end
    return vital
end


"""
    initializeGraphs!(constraint)

Return the graph and the empty directed graph of a variable-value problem.
"""
function initializeGraphs!(con::AllDifferent)::Pair{Graph{Int}, DiGraph{Int}}
    numberOfNodes = con.numberOfVars + con.numberOfVals
    edgeFilter = BitVector(con.remainingEdges)[1:con.numberOfEdges]
    allEdges = con.indexToEdge[edgeFilter]
    graph = Graph(allEdges)
    digraph = LightGraphs.DiGraph(LightGraphs.nv(graph))
    if LightGraphs.nv(graph) < numberOfNodes
        LightGraphs.add_vertices!(graph, numberOfNodes - LightGraphs.nv(graph))
    end
    return Pair(graph, digraph)
end

"""
    getAllEdges(digraph, parents)::Set{Edge}

Return all the edges visited by a BFS on `digraph` encoded in `parents`.
"""
function getAllEdges(digraph::DiGraph{Int}, parents::Vector{Int})::Set{Edge{Int}}
    edgeSet = Set{Edge{Int}}()
    for i = 1:LightGraphs.nv(digraph)
        if parents[i] > 0 && parents[i] != i
            validneighbors = filter(v -> parents[v] > 0, LightGraphs.inneighbors(digraph, i))
            validedges = map(v -> orderEdge(LightGraphs.Edge(v, i)), validneighbors)
            union!(edgeSet, validedges)
        end
    end
    return edgeSet
end

remapedge(edge::Edge{Int}, component::Vector{Int}) = LightGraphs.Edge(component[edge.src], component[edge.dst])

"""
    removeEdges!(constraint, prunedValue, graph, digraph)

Remove all the unnecessary edges in graph and digraph as in the original paper.

Update `constraint.edgesState` with the new status of each edge, remove some
edges from `graph` and `digraph` and push the removed values in `prunedValue`.
Following exactly the procedure in the function with the same name in the original
paper.
"""
function removeEdges!(constraint::AllDifferent, prunedValues::Vector{Vector{Int}}, graph::Graph{Int}, digraph::DiGraph{Int})

    unused = BitVector(constraint.remainingEdges)[1:constraint.numberOfEdges]
    vital = BitVector(undef, constraint.numberOfEdges) .= false
    removed = BitVector(undef, constraint.numberOfEdges) .= .~ unused
    used = BitVector(undef, constraint.numberOfEdges) .= false

    allValues = constraint.numberOfVars+1:LightGraphs.nv(digraph)
    freeValues = filter(v -> LightGraphs.indegree(digraph,v) == 0, allValues)

    seen = fill(false, constraint.numberOfVals)
    components = filter(comp -> length(comp)>1, LightGraphs.strongly_connected_components(digraph))
    for component in components
        edgeSet = orderEdge.(remapedge.(LightGraphs.edges(digraph[component]), [component]))
        edgeIndices = getindex.([constraint.edgeToIndex], edgeSet)
        used[edgeIndices] .= true
        unused[edgeIndices] .= false
    end

    for node in freeValues
        if seen[node - constraint.numberOfVars]
            continue
        end
        parents = LightGraphs.bfs_parents(digraph, node; dir=:out)
        edgeSet = getAllEdges(digraph, parents)
        edgeIndices = getindex.([constraint.edgeToIndex], edgeSet)
        used[edgeIndices] .= true
        unused[edgeIndices] .= false
        reached = filter(v -> parents[v] > 0, allValues)
        seen[reached .- constraint.numberOfVars] .= true
    end

    edgeIndices = map(constraint.matching) do pair
        var, val = pair.value
        e = LightGraphs.Edge(var, val)
        return constraint.edgeToIndex[e]
    end
    vital[edgeIndices] .= true .& unused[edgeIndices]
    unused[edgeIndices] .= false

    rest = constraint.indexToEdge[unused]
    reversedRest = map(e -> LightGraphs.Edge(e.dst, e.src), rest)
    LightGraphs.rem_edge!.([graph], rest)
    LightGraphs.rem_edge!.([digraph], reversedRest)
    removed[unused] .= true
    foreach(rest) do e
        var, val = e.src, e.dst
        push!(prunedValues[var], nodeToVal(constraint, val))
    end

    updateremaining!(constraint, removed)
    updatevital!(constraint, vital)
end

"""
    updateEdgesState!(constraint)::Set{Edge}

Return all the pruned values not already encoded in the constraint state.
"""
function updateEdgesState!(constraint::AllDifferent, prunedDomains::CPModification)
    modif = Set{Edge}()
    for (idx, var) in enumerate(constraint.x)
        if haskey(prunedDomains, var.id)
            union!(modif, Edge.([idx], valToNode.([constraint], prunedDomains[var.id])))
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
            setValue!(constraint.matching[idx], (match..., false))
        end
        setValue!(constraint.initialized, true)
    #    Otherwise just read the stored values
    else
        matching = Matching{Int}(length(constraint.matching), map(match -> (match.value[1] => match.value[2]), constraint.matching))
        buildDigraph!(digraph, graph, matching)
    end

    # TODO change this with the CPModification
    modifications = updateEdgesState!(constraint, prunedDomains)
    prunedValues = Vector{Vector{Int}}(undef, constraint.numberOfVars)
    for i = 1:constraint.numberOfVars
        prunedValues[i] = Int[]
    end

    removed = .~ BitVector(constraint.remainingEdges)[1:constraint.numberOfEdges]
    vital = getvital(constraint)
    needrematching = false
    for e in modifications
        rev_e = LightGraphs.Edge(e.dst, e.src)
        idx = constraint.edgeToIndex[e]
        if e in LightGraphs.edges(graph)
            if vital[idx]
                return false
            elseif e in LightGraphs.edges(digraph)
                needrematching = true
                LightGraphs.rem_edge!(digraph, e)
            else
                LightGraphs.rem_edge!(digraph, rev_e)
            end
            LightGraphs.rem_edge!(graph, e)
            # TODO get rid of edgesState
            removed[idx] = true
        end
    end

    updateremaining!(constraint, removed)

    if needrematching
        matching = maximizeMatching!(digraph, constraint.numberOfVars)
        if matching.size < constraint.numberOfVars
            return false
        end
        for (idx, match) in enumerate(matching.matches)
            setValue!(constraint.matching[idx], (match..., false))
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
    print(io, string(typeof(con)), ": ", join([var.id for var in con.x], " != "), ", active = ", con.active)
    for var in con.x
        print(io, "\n   ", var)
    end
end

function Base.show(io::IO, con::AllDifferent)
    print(io, string(typeof(con)), ": ", join([var.id for var in con.x], " != "))
end

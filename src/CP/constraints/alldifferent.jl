using MatrixNetworks
using SparseArrays

"""
    AllDifferent(x::SeaPearl.AbstractIntVar)

AllDifferent constraint, states that `x[1] != x[2] != ... != x[length(x)]`
"""
struct AllDifferent <: Constraint
    x::Array{AbstractIntVar}
    active::StateObject{Bool}
    numberOfVars::Int
    numberOfFreeVars::StateObject{Int}
    freeIds::Array{Int}
    function AllDifferent(x::Array{AbstractIntVar}, trailer)
        @assert !isempty(x)

        numberOfFreeVars = StateObject{Int}(length(x), trailer)
        numberOfVars = length(x)
        freeIds = zeros(Int, numberOfVars)
        for i in 1:numberOfVars
            freeIds[i] = i
        end

        constraint = new(x, StateObject{Bool}(true, trailer), numberOfVars, numberOfFreeVars, freeIds)
        for xi in x
            addOnDomainChange!(xi, constraint)
        end
        return constraint
    end
end

"""
    propagate!(constraint::AllDifferent, toPropagate::Set{Constraint}, prunedDomains::CPModification)

Arc-consistent `AllDifferent` propagation function. Implementation of the algorithm described in "A filtering algorithm for constraints of difference in CSPs" J-C. Régin, AAAI-94 
"""
function propagate!(constraint::AllDifferent, toPropagate::Set{Constraint}, prunedDomains::CPModification)

    # Stop propagation if constraint not active
    if !constraint.active.value
        return false
    end

    # Computing minVal, maxVal and numberOfVals
    newNumberOfFreeVars = constraint.numberOfFreeVars.value
    minVal = minimum(constraint.x[1].domain)    # Not Inf to keep an Int
    maxVal = maximum(constraint.x[1].domain)
    for i in newNumberOfFreeVars:-1:1
        currentId = constraint.freeIds[i]
        if minVal > minimum(constraint.x[currentId].domain)
            minVal = minimum(constraint.x[currentId].domain)
        end
        if maxVal < maximum(constraint.x[currentId].domain)
            maxVal = maximum(constraint.x[currentId].domain)
        end
        if isbound(constraint.x[currentId])
            constraint.freeIds[i] = constraint.freeIds[newNumberOfFreeVars]
            constraint.freeIds[newNumberOfFreeVars] = currentId
            newNumberOfFreeVars -= 1
        end
    end
    setValue!(constraint.numberOfFreeVars, newNumberOfFreeVars)
    if newNumberOfFreeVars == 0
        setValue!(constraint.active, false)
    end
    numberOfVals = maxVal - minVal + 1

    # Creating the matrix of the variable-value bipartite graph
    #   `I`: Array of variable vertices (1 to `constraint.numberOfVars`)
    #   `J`: Array of value vertices (1 to `numberOfVals`)
    #   `V`: Array of weights (always one in this graph)
    #   An edge exists between a variable vertex `i` and a (shifted) value
    #   vertex `j` if the value `j+minVal-1` is in the domain of `x[i]`
    I, J, V = Int[], Int[], Bool[]
    for i in 1:constraint.numberOfVars, j in constraint.x[i].domain
        if j in constraint.x[i].domain
            push!(I, i)                  # First endpoint: variable
            push!(J, j - minVal + 1)     # Second endpoint: value
            push!(V, true)               # Weight of the edge: always one
        end
    end
    bipartiteMatrix = sparse(I, J, V, constraint.numberOfVars, numberOfVals)

    # Computing a maximum matching in the bipartite graph and
    # checking feasibility based on the cardinality of this matching
    matching = bipartite_matching(bipartiteMatrix)
    if matching.cardinality < constraint.numberOfVars
        return false
    end

    ### Filtering ###

    # `numberOfNodes`: Counts all variable-value vertices and a sink
    # `nodesOut`:      Array indexed by `numberOfNodes`. `nodesOut[i]` contains
    #                  the set of nodes that point out `x[i]`
    numberOfNodes = constraint.numberOfVars + numberOfVals + 1
    nodesOut = [Set{Int}() for _ in 1:numberOfNodes]

    # `matchingMatrix` is the adjacency matrix of the directed residual graph
    #       For a variable vertex `i` (between 1 and `constraint.numberOfVars`) and
    #       a (shifted) value vertex `j` (between 1 and numberOfVals), we have
    #       `matchingMatrix[i,j]==1` iff the edge (i,j) is in the maximum matching 
    matchingMatrix = create_sparse(matching)

    # Creating the residual graph of the previous matching
    I, J = Int[], Int[]
    for i in 1:constraint.numberOfVars, j in constraint.x[i].domain
        shiftedValue = j - minVal + 1
        if matchingMatrix[i, shiftedValue] == 1
            push!(I, shiftedValue + constraint.numberOfVars)
            push!(J, i)
            push!(nodesOut[shiftedValue + constraint.numberOfVars], i)
        else
            push!(J, shiftedValue + constraint.numberOfVars)
            push!(I, i)
            push!(nodesOut[i], shiftedValue + constraint.numberOfVars)
        end
    end

    # Connecting values to the sink
    for j in minVal:maxVal
        shiftedValue = j - minVal + 1
        if isempty(nodesOut[shiftedValue + constraint.numberOfVars])
            push!(I, shiftedValue + constraint.numberOfVars)
            push!(J, numberOfNodes)     # numberOfNodes: index of the sink
            push!(nodesOut[shiftedValue + constraint.numberOfVars], numberOfNodes)
        else
            push!(J, shiftedValue + constraint.numberOfVars)
            push!(I, numberOfNodes)
            push!(nodesOut[numberOfNodes], shiftedValue + constraint.numberOfVars)
        end
    end

    # Computing the strongly connected components of the residual graph
    strongComponentsMap = strong_components_map(I, J)

    # If a variable vertex `i` and a value vertex `j` do not match
    # and if they are not in the same strongly connected component 
    # of the residual graph, then `x[i]=j' is impossible
    pruned = [Int[] for _ in 1:constraint.numberOfVars]
    for i in 1:constraint.numberOfVars
        for j in constraint.x[i].domain
            shiftedValue = j - minVal + 1
            if matchingMatrix[i,shiftedValue] != 1
                if strongComponentsMap[i] != strongComponentsMap[shiftedValue + constraint.numberOfVars]
                    push!(pruned[i], j)
                end
            end
        end
    end

    # Update domains and trigger domain changes
    # TODO: Can be improved with `freeIds`....
    for i in 1:constraint.numberOfVars
        if !isempty(pruned[i])
            addToPrunedDomains!(prunedDomains, constraint.x[i], pruned[i])
            for j in pruned[i]
                remove!(constraint.x[i].domain, j)
                triggerDomainChange!(toPropagate, constraint.x[i])
            end
        end
    end

    return true
end

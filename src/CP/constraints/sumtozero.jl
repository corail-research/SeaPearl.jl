"""
    SumToZero(x<:AbstractIntVar, v::Int)

Summing constraint, states that `x[1] + x[2] + ... + x[length(x)] == 0`
"""
struct SumToZero <: Constraint
    x                   ::Array{<:AbstractIntVar}
    active              ::StateObject{Bool}
    numberOfFreeVars    ::StateObject{Int}
    sumOfFixedVars      ::StateObject{Int}
    freeIds             ::Array{Int}
    function SumToZero(x::Array{<:AbstractIntVar}, trailer)
        @assert !isempty(x)

        freeIds = zeros(length(x))
        for i in 1:length(x)
            freeIds[i] = i
        end

        constraint = new(x, StateObject{Bool}(true, trailer), StateObject{Int}(length(x), trailer), StateObject{Int}(0, trailer), freeIds)
        for xi in x
            addOnDomainChange!(xi, constraint)
        end
        return constraint
    end
end

"""
    propagate!(constraint::SumToZero, toPropagate::Set{Constraint}, prunedDomains::CPModification)

`SumToZero` propagation function. The pruning is quite superficial.
"""
function propagate!(constraint::SumToZero, toPropagate::Set{Constraint}, prunedDomains::CPModification)
    # Computing maxSum, minSum, and refreshing other variables
    newNumberOfFreeVars = constraint.numberOfFreeVars.value
    sumOfMax, sumOfMin = constraint.sumOfFixedVars.value, constraint.sumOfFixedVars.value
    for i in newNumberOfFreeVars:-1:1
        currentId = constraint.freeIds[i]
        sumOfMin += minimum(constraint.x[currentId].domain)
        sumOfMax += maximum(constraint.x[currentId].domain)

        if isbound(constraint.x[currentId])
            setValue!(constraint.sumOfFixedVars, constraint.sumOfFixedVars.value + assignedValue(constraint.x[currentId]))
            constraint.freeIds[i] = constraint.freeIds[newNumberOfFreeVars]
            constraint.freeIds[newNumberOfFreeVars] = currentId
            newNumberOfFreeVars -= 1
        end
    end
    setValue!(constraint.numberOfFreeVars, newNumberOfFreeVars)

    # Checking feasibility
    if sumOfMin > 0 || sumOfMax < 0
        return false
    end

    ### Filtering ###
    # Here we must have: x_i = - sum(x_j for j != i)
    # But we know that: - sum(x_j for j != i) <= - sum(min(x_j) for j != i)
    # And: - sum(min(x_j) for j != i) = min(x_i) - sumOfMin
    # Hence we remove everything above that last value from the domain of x_i
    # The reasoning is equivalent for the minimization
    for i in newNumberOfFreeVars:-1:1
        currentId = constraint.freeIds[i]
        currentMin = minimum(constraint.x[currentId].domain)
        currentMax = maximum(constraint.x[currentId].domain)
        pruned = vcat(removeAbove!(constraint.x[currentId].domain, currentMin - sumOfMin), removeBelow!(constraint.x[currentId].domain, currentMax - sumOfMax))
        if !isempty(pruned)
            addToPrunedDomains!(prunedDomains, constraint.x[currentId], pruned)
            triggerDomainChange!(toPropagate, constraint.x[currentId])
            
        end
    end

    if newNumberOfFreeVars == 0
        setValue!(constraint.active, false)
    end

    return true
end

variablesArray(constraint::SumToZero) = constraint.x
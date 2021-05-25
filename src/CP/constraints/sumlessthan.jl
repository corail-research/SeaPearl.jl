"""
    SumLessThan(x<:AbstractIntVar, v::Int)

Summing constraint, states that `x[1] + x[2] + ... + x[length(x)] <= v`
"""
struct SumLessThan <: Constraint
    x                   ::Array{<:AbstractIntVar}
    upper               ::Int
    active              ::StateObject{Bool}
    numberOfFreeVars    ::StateObject{Int}
    sumOfFixedVars      ::StateObject{Int}
    freeIds             ::Array{Int}
    function SumLessThan(x::Array{<:AbstractIntVar}, upper,  trailer)
        @assert !isempty(x)

        freeIds = zeros(length(x))
        for i in 1:length(x)
            freeIds[i] = i
        end

        constraint = new(x, upper, StateObject{Bool}(true, trailer), StateObject{Int}(length(x), trailer), StateObject{Int}(0, trailer), freeIds)
        for xi in x
            addOnDomainChange!(xi, constraint)
        end
        return constraint
    end
end

"""
    propagate!(constraint::SumLessThan, toPropagate::Set{Constraint}, prunedDomains::CPModification)

`SumLessThan` propagation function. The pruning is quite superficial.
"""
function propagate!(constraint::SumLessThan, toPropagate::Set{Constraint}, prunedDomains::CPModification)
    # Stop propagation if constraint not active
    if !constraint.active.value
        return false
    end

    # Computing maxSum, minSum, and refreshing other variables
    newNumberOfFreeVars = constraint.numberOfFreeVars.value
    sumOfMin = constraint.sumOfFixedVars.value
    for i in newNumberOfFreeVars:-1:1
        currentId = constraint.freeIds[i]
        sumOfMin += minimum(constraint.x[currentId].domain)

        if isbound(constraint.x[currentId])
            setValue!(constraint.sumOfFixedVars, constraint.sumOfFixedVars.value + assignedValue(constraint.x[currentId]))
            constraint.freeIds[i] = constraint.freeIds[newNumberOfFreeVars]
            constraint.freeIds[newNumberOfFreeVars] = currentId
            newNumberOfFreeVars -= 1
        end
    end
    setValue!(constraint.numberOfFreeVars, newNumberOfFreeVars)

    # Checking feasibility
    if sumOfMin > constraint.upper
        return false
    end

    ### Filtering ###
    # Here we must have: x_i = - sum(x_j for j != i) + upper
    # But we know that: - sum(x_j for j != i) <= - sum(min(x_j) for j != i)
    # And: - sum(min(x_j) for j != i) = min(x_i) - sumOfMin
    # Hence x_i <= upper + min(x_i) _ sumOfMin
    # Hence we remove everything above that last value from the domain of x_i
    # The reasoning is equivalent for the minimization
    for i in newNumberOfFreeVars:-1:1
        currentId = constraint.freeIds[i]
        currentMin = minimum(constraint.x[currentId].domain)
        pruned = vcat(removeAbove!(constraint.x[currentId].domain, constraint.upper + currentMin - sumOfMin))
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

function Base.show(io::IO, ::MIME"text/plain", con::SumLessThan)
    ids = [var.id for var in con.x]
    print(io, typeof(con), ": ", join(ids, " + "), " ≤ ", con.upper, ", active = ", con.active)
    for var in con.x
        print(io, "\n   ", var)
    end
end

function Base.show(io::IO, con::SumLessThan)
    ids = [var.id for var in con.x]
    print(io, typeof(con), ": ", join(ids, " + "), " ≤ ", con.upper)
end

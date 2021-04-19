"""
    SumGreaterThan(x::SeaPearl.AbstractIntVar, v::Int)

Summing constraint, states that `x[1] + x[2] + ... + x[length(x)] >= lower`
"""
struct SumGreaterThan <: Constraint
    x                   ::Array{AbstractIntVar}
    lower               ::Int
    active              ::StateObject{Bool}
    numberOfFreeVars    ::StateObject{Int}
    sumOfFixedVars      ::StateObject{Int}
    freeIds             ::Array{Int}
    function SumGreaterThan(x::Array{AbstractIntVar}, lower, trailer)
        @assert !isempty(x)

        freeIds = zeros(length(x))
        for i in 1:length(x)
            freeIds[i] = i
        end

        constraint = new(x, lower, StateObject{Bool}(true, trailer), StateObject{Int}(length(x), trailer), StateObject{Int}(0, trailer), freeIds)
        for xi in x
            addOnDomainChange!(xi, constraint)
        end
        return constraint
    end
end

"""
    propagate!(constraint::SumGreaterThan, toPropagate::Set{Constraint}, prunedDomains::CPModification)

`SumGreaterThan` propagation function. The pruning is quite superficial.
"""
function propagate!(constraint::SumGreaterThan, toPropagate::Set{Constraint}, prunedDomains::CPModification)
    # Stop propagation if constraint not active
    if !constraint.active.value
        return false
    end

    # Computing maxSum, minSum, and refreshing other variables
    newNumberOfFreeVars = constraint.numberOfFreeVars.value
    sumOfMax, sumOfMin = constraint.sumOfFixedVars.value, constraint.sumOfFixedVars.value
    for i in newNumberOfFreeVars:-1:1
        currentId = constraint.freeIds[i]
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
    if sumOfMax < constraint.lower
        return false
    end

    ### Filtering ###
    # Here we must have: x_i = - sum(x_j for j != i)
    # But we know that: - sum(x_j for j != i) >= - sum(max(x_j) for j != i)
    # And: - sum(max(x_j) for j != i) = max(x_i) - sumOfMax
    # Hence x_i >= lower + max(x_i) - sumOfMax
    # Hence we remove everything below that last value from the domain of x_i
    # The reasoning is equivalent for the minimization
    for i in newNumberOfFreeVars:-1:1
        currentId = constraint.freeIds[i]
        currentMax = maximum(constraint.x[currentId].domain)
        pruned = vcat(removeBelow!(constraint.x[currentId].domain, constraint.lower + currentMax - sumOfMax))
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

function Base.show(io::IO, ::MIME"text/plain", con::SumGreaterThan)
    ids = [var.id for var in con.x]
    println(io, typeof(con), ": ", join(ids, " + "), " >= ", con.lower, ", active = ", con.active)
    for var in con.x
        println(io, "   ", con.var)
    end
end

function Base.show(io::IO, con::SumGreaterThan)
    ids = [var.id for var in con.x]
    print(io, typeof(con), ": ", join(ids, " + "), " >= ", con.lower)
end

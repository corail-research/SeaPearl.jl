
"""
    NotEqualConstant(x::CPRL.IntVar, v::Int)

Inequality constraint, `x != v`
"""
mutable struct NotEqualConstant <: Constraint
    x       ::IntVar
    v       ::Int
    active  ::Bool
    function NotEqualConstant(x, v)
        constraint = new(x, v, true)
        push!(x.onDomainChange, constraint)
        return constraint
    end
end

"""
    propagate!(constraint::NotEqualConstant, toPropagate::Set{Constraint}, prunedDomains::CPModification)

`NotEqualConstant` propagation function. Basically remove the constant value from the domain of the variable.
"""
function propagate!(constraint::NotEqualConstant, toPropagate::Set{Constraint}, prunedDomains::CPModification)
    if !constraint.active
        return true
    end

    if constraint.v in constraint.x.domain
        addToPrunedDomains!(prunedDomains, constraint.x, remove!(constraint.x.domain, constraint.v))
        union!(toPropagate, constraint.x.onDomainChange)
        pop!(toPropagate, constraint)
        return !isempty(constraint.x.domain)
    end
    return true
end

"""
    NotEqual(x::CPRL.IntVar, y::CPRL.IntVar)

Inequality constraint between two variables, stating that `x != y`.
"""
mutable struct NotEqual <: Constraint
    x       ::CPRL.IntVar
    y       ::CPRL.IntVar
    active  ::Bool

    function NotEqual(x::CPRL.IntVar, y::CPRL.IntVar)
        constraint = new(x, y, true)
        push!(x.onDomainChange, constraint)
        push!(y.onDomainChange, constraint)
        return constraint
    end
end

"""
    propagate!(constraint::NotEqual, toPropagate::Set{Constraint}, prunedDomains::CPModification)

`NotEqual` propagation function.
"""
function propagate!(constraint::NotEqual, toPropagate::Set{Constraint}, prunedDomains::CPModification)
    if !constraint.active
        return true
    end

    if isbound(constraint.x)
        constraint.active = false
        pruned = remove!(constraint.y.domain, constraint.x.domain.max.value)
        if isempty(constraint.y.domain)
            return false
        end
        if !isempty(pruned)
            union!(toPropagate, constraint.y.onDomainChange)
            pop!(toPropagate, constraint)
            addToPrunedDomains!(prunedDomains, constraint.y, pruned)
        end
        return true
    end
    if isbound(constraint.y)
        constraint.active = false
        pruned = remove!(constraint.x.domain, constraint.y.domain.max.value)
        if isempty(constraint.x.domain)
            return false
        end
        if !isempty(pruned)
            union!(toPropagate, constraint.x.onDomainChange)
            pop!(toPropagate, constraint)
            addToPrunedDomains!(prunedDomains, constraint.x, pruned)
        end
        return true
    end
    return true
end


abstract type NotEqualConstraint <: Constraint end

"""
    NotEqualConstant(x::CPRL.IntVar, v::Int)

Inequality constraint, `x != v`
"""
mutable struct NotEqualConstant <: NotEqualConstraint
    x       ::IntVar
    v       ::Int
    active  ::StateObject{Bool}
    function NotEqualConstant(x, v, trailer)
        constraint = new(x, v, StateObject(true, trailer))
        push!(x.onDomainChange, constraint)
        return constraint
    end
end

"""
    propagate!(constraint::NotEqualConstant, toPropagate::Set{Constraint}, prunedDomains::CPModification)

`NotEqualConstant` propagation function. Basically remove the constant value from the domain of the variable.
"""
function propagate!(constraint::NotEqualConstant, toPropagate::Set{Constraint}, prunedDomains::CPModification)
    if !constraint.active.value
        return true
    end
    setValue!(constraint.active, false)

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
mutable struct NotEqual <: NotEqualConstraint
    x       ::CPRL.IntVar
    y       ::CPRL.IntVar
    active  ::StateObject{Bool}

    function NotEqual(x::CPRL.IntVar, y::CPRL.IntVar, trailer::Trailer)
        constraint = new(x, y, StateObject(true, trailer))
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
    if !constraint.active.value
        return false
    end

    if isempty(constraint.x.domain) || isempty(constraint.y.domain)
        return false
    end

    if isbound(constraint.x)
        setValue!(constraint.active, false)
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
        setValue!(constraint.active, false)
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


abstract type NotEqualConstraint <: Constraint end

"""
    NotEqualConstant(x::CPRL.IntVar, v::Int)

Inequality constraint, `x != v`
"""
struct NotEqualConstant <: NotEqualConstraint
    x       ::AbstractIntVar
    v       ::Int
    active  ::StateObject{Bool}
    function NotEqualConstant(x, v, trailer)
        constraint = new(x, v, StateObject(true, trailer))
        addOnDomainChange!(x, constraint)
        return constraint
    end
end

"""
    propagate!(constraint::NotEqualConstant, toPropagate::Set{Constraint}, prunedDomains::CPModification)

`NotEqualConstant` propagation function. Basically remove the constant value from the domain of the variable.
"""
function propagate!(constraint::NotEqualConstant, toPropagate::Set{Constraint}, prunedDomains::CPModification)
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
struct NotEqual <: NotEqualConstraint
    x       ::CPRL.AbstractIntVar
    y       ::CPRL.AbstractIntVar
    active  ::StateObject{Bool}

    function NotEqual(x::CPRL.AbstractIntVar, y::CPRL.AbstractIntVar, trailer::Trailer)
        constraint = new(x, y, StateObject(true, trailer))
        addOnDomainChange!(x, constraint)
        addOnDomainChange!(y, constraint)
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
        pruned = remove!(constraint.y.domain, maximum(constraint.x.domain))
        if isempty(constraint.y.domain)
            return false
        end
        if !isempty(pruned)
            triggerDomainChange!(toPropagate, constraint.y)
            addToPrunedDomains!(prunedDomains, constraint.y, pruned)
        end
        return true
    end
    if isbound(constraint.y)
        setValue!(constraint.active, false)
        pruned = remove!(constraint.x.domain, maximum(constraint.y.domain))
        if isempty(constraint.x.domain)
            return false
        end
        if !isempty(pruned)
            triggerDomainChange!(toPropagate, constraint.x)
            addToPrunedDomains!(prunedDomains, constraint.x, pruned)
        end
        return true
    end
    return true
end

variablesArray(constraint::NotEqual) = [constraint.x, constraint.y]


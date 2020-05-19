abstract type GreaterOrEqualConstraint <: Constraint end

"""
    GreaterOrEqualConstant(x::CPRL.AbstractIntVar, v::Int)

Inequality constraint, `x >= v`
"""
struct GreaterOrEqualConstant <: GreaterOrEqualConstraint
    x       ::AbstractIntVar
    v       ::Int
    active  ::StateObject{Bool}
    function GreaterOrEqualConstant(x, v, trailer)
        constraint = new(x, v, StateObject(true, trailer))
        addOnDomainChange!(x, constraint)
        return constraint
    end
end

"""
    propagate!(constraint::GreaterOrEqualConstant, toPropagate::Set{Constraint}, prunedDomains::CPModification)

`GreaterOrEqualConstant` propagation function. Basically remove the values above `v`.
"""
function propagate!(constraint::GreaterOrEqualConstant, toPropagate::Set{Constraint}, prunedDomains::CPModification)
    if !constraint.active.value
        return true
    end
    setValue!(constraint.active, false)

    addToPrunedDomains!(prunedDomains, constraint.x, removeBelow!(constraint.x.domain, constraint.v))
    triggerDomainChange!(toPropagate, constraint.x)
    pop!(toPropagate, constraint)
    return !isempty(constraint.x.domain)
end


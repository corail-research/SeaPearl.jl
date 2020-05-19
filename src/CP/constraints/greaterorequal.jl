abstract type GreaterOrEqualConstraint <: Constraint end

"""
    GreaterOrEqualConstant(x::CPRL.IntVar, v::Int)

Inequality constraint, `x >= v`
"""
struct GreaterOrEqualConstant <: GreaterOrEqualConstraint
    x       ::IntVar
    v       ::Int
    active  ::StateObject{Bool}
    function GreaterOrEqualConstant(x, v, trailer)
        constraint = new(x, v, StateObject(true, trailer))
        push!(x.onDomainChange, constraint)
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
    union!(toPropagate, constraint.x.onDomainChange)
    pop!(toPropagate, constraint)
    return !isempty(constraint.x.domain)
end


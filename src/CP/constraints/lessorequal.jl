abstract type LessOrEqualConstraint <: Constraint end

"""
    LessOrEqualConstant(x::CPRL.IntVar, v::Int)

Inequality constraint, `x <= v`
"""
struct LessOrEqualConstant <: LessOrEqualConstraint
    x       ::IntVar
    v       ::Int
    active  ::StateObject{Bool}
    function LessOrEqualConstant(x, v, trailer)
        constraint = new(x, v, StateObject(true, trailer))
        push!(x.onDomainChange, constraint)
        return constraint
    end
end

"""
    propagate!(constraint::LessOrEqualConstant, toPropagate::Set{Constraint}, prunedDomains::CPModification)

`LessOrEqualConstant` propagation function. Basically remove the values above `v`.
"""
function propagate!(constraint::LessOrEqualConstant, toPropagate::Set{Constraint}, prunedDomains::CPModification)
    if !constraint.active.value
        return true
    end
    setValue!(constraint.active, false)

    addToPrunedDomains!(prunedDomains, constraint.x, removeAbove!(constraint.x.domain, constraint.v))
    union!(toPropagate, constraint.x.onDomainChange)
    pop!(toPropagate, constraint)
    return !isempty(constraint.x.domain)
end


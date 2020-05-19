abstract type LessOrEqualConstraint <: Constraint end

"""
    LessOrEqualConstant(x::CPRL.AbstractIntVar, v::Int)

Inequality constraint, `x <= v`
"""
struct LessOrEqualConstant <: LessOrEqualConstraint
    x       ::AbstractIntVar
    v       ::Int
    active  ::StateObject{Bool}
    function LessOrEqualConstant(x, v, trailer)
        constraint = new(x, v, StateObject(true, trailer))
        addOnDomainChange!(x, constraint)
        return constraint
    end
end

Base.show(io::IO, c::LessOrEqualConstant) = write(io, "LessOrEqualConstant constraint")

"""
    propagate!(constraint::LessOrEqualConstant, toPropagate::Set{Constraint}, prunedDomains::CPModification)

`LessOrEqualConstant` propagation function. Basically remove the values above `v`.
"""
function propagate!(constraint::LessOrEqualConstant, toPropagate::Set{Constraint}, prunedDomains::CPModification)
    if !constraint.active.value
        return false
    end
    setValue!(constraint.active, false)
    
    addToPrunedDomains!(prunedDomains, constraint.x, removeAbove!(constraint.x.domain, constraint.v))
    triggerDomainChange!(toPropagate, constraint.x)
    if constraint in toPropagate
        pop!(toPropagate, constraint)
    end
    return !isempty(constraint.x.domain)
end


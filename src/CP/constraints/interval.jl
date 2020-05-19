abstract type IntervalConstraint <: Constraint end

"""
    IntervalConstant(x::CPRL.IntVar, lower::Int, upper::Int)

Inequality constraint, `lower <= x <= upper`
"""
struct IntervalConstant <: LessOrEqualConstraint
    x::IntVar
    lower::Int
    upper::Int
    active::StateObject{Bool}
    function IntervalConstant(x, lower, upper, trailer)
        constraint = new(x, lower, upper, StateObject(true, trailer))
        push!(x.onDomainChange, constraint)
        return constraint
    end
end

"""
    propagate!(constraint::IntervalConstant, toPropagate::Set{Constraint}, prunedDomains::CPModification)

`IntervalConstant` propagation function. Basically remove the values above `upper` and below `lower`.
"""
function propagate!(constraint::IntervalConstant, toPropagate::Set{Constraint}, prunedDomains::CPModification)
    if !constraint.active.value
        return true
    end
    setValue!(constraint.active, false)

    addToPrunedDomains!(prunedDomains, constraint.x, vcat(removeBelow!(constraint.x.domain, constraint.lower), removeAbove!(constraint.x.domain, constraint.upper)))
    union!(toPropagate, constraint.x.onDomainChange)
    pop!(toPropagate, constraint)
    return !isempty(constraint.x.domain)
end
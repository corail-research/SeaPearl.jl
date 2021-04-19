"""
    IntervalConstant(x::SeaPearl.IntVar, lower::Int, upper::Int)

Inequality constraint, `lower <= x <= upper`
"""
struct IntervalConstant <: OnePropagationConstraint
    x::AbstractIntVar
    lower::Int
    upper::Int
    active::StateObject{Bool}
    function IntervalConstant(x, lower, upper, trailer)
        constraint = new(x, lower, upper, StateObject(true, trailer))
        addOnDomainChange!(x, constraint)
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
    triggerDomainChange!(toPropagate, constraint.x)
    if constraint in toPropagate
        pop!(toPropagate, constraint)
    end
    return !isempty(constraint.x.domain)
end

function Base.show(io::IO, ::MIME"text/plain", con::IntervalConstant)
    println(io, typeof(con), ": ", con.lower, " <= ", con.x.id, " <= ", con.upper, ", active = ", con.active)
    println(io, "   ", con.x)
end

function Base.show(io::IO, con::IntervalConstant)
    print(io, typeof(con), ": ", con.lower, " <= ", con.x.id, " <= ", con.upper)
end

"""
    GreaterOrEqualConstant(x::SeaPearl.AbstractIntVar, v::Int)

Inequality constraint, `x >= v`
"""
struct GreaterOrEqualConstant <: OnePropagationConstraint
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
    setValue!(constraint.active, false)

    addToPrunedDomains!(prunedDomains, constraint.x, removeBelow!(constraint.x.domain, constraint.v))
    triggerDomainChange!(toPropagate, constraint.x)
    return !isempty(constraint.x.domain)
end

function Base.show(io::IO, ::MIME"text/plain", con::GreaterOrEqualConstant)
    println(io, typeof(con), ": ", con.x.id, " >= ", con.v, ", active = ", con.active)
    println(io, "   ", con.x)
end

function Base.show(io::IO, con::GreaterOrEqualConstant)
    print(io, typeof(con), ": ", con.x.id, " >= ", con.v)
end

"""
    LessOrEqualConstant(x::SeaPearl.AbstractIntVar, v::Int, trailer::SeaPearl.Trailer)

Inequality constraint, `x <= v`
"""
struct LessOrEqualConstant <: OnePropagationConstraint
    x       ::AbstractIntVar
    v       ::Int
    active  ::StateObject{Bool}
    function LessOrEqualConstant(x::AbstractIntVar, v::Int, trailer)
        constraint = new(x, v, StateObject(true, trailer))
        addOnDomainChange!(x, constraint)
        return constraint
    end
end

# Base.show(io::IO, c::LessOrEqualConstant) = write(io, "LessOrEqualConstant constraint: ", c.x, " <= ", c.v)

"""
    propagate!(constraint::LessOrEqualConstant, toPropagate::Set{Constraint}, prunedDomains::CPModification)

`LessOrEqualConstant` propagation function. Basically remove the values above `v`.
"""
function propagate!(constraint::LessOrEqualConstant, toPropagate::Set{Constraint}, prunedDomains::CPModification)
    setValue!(constraint.active, false)

    addToPrunedDomains!(prunedDomains, constraint.x, removeAbove!(constraint.x.domain, constraint.v))
    triggerDomainChange!(toPropagate, constraint.x)
    if constraint in toPropagate
        pop!(toPropagate, constraint)
    end
    return !isempty(constraint.x.domain)
end

variablesArray(constraint::LessOrEqualConstant) = [constraint.x]

function Base.show(io::IO, ::MIME"text/plain", con::LessOrEqualConstant)
    println(io, typeof(con), ": ", con.x.id, " <= ", con.v, ", active = ", con.active)
    println(io, "   ", con.x)
end

function Base.show(io::IO, con::LessOrEqualConstant)
    print(io, typeof(con), ": ", con.x.id, " <= ", con.v)
end

struct LessOrEqual <: Constraint
    x       ::AbstractIntVar
    y       ::AbstractIntVar
    active  ::StateObject{Bool}

    """
        LessOrEqual(x::AbstractIntVar, y::AbstractIntVar, trailer::Trailer)

    Inequality between variables constraint, states that `x <= y`
    """
    function LessOrEqual(x::AbstractIntVar, y::AbstractIntVar, trailer)
        constraint = new(x, y, StateObject(true, trailer))
        addOnDomainChange!(x, constraint)
        addOnDomainChange!(y, constraint)
        return constraint
    end
end

"""
    propagate!(constraint::LessOrEqual, toPropagate::Set{Constraint}, prunedDomains::CPModification)

`LessOrEqual` propagation function.
"""
function propagate!(constraint::LessOrEqual, toPropagate::Set{Constraint}, prunedDomains::CPModification)


    if maximum(constraint.x.domain) <= minimum(constraint.y.domain)
        setValue!(constraint.active, false)
    end

    prunedX = removeAbove!(constraint.x.domain, maximum(constraint.y.domain))
    if !isempty(prunedX)
        addToPrunedDomains!(prunedDomains, constraint.x, prunedX)
        triggerDomainChange!(toPropagate, constraint.x)
    end

    prunedY = removeBelow!(constraint.y.domain, minimum(constraint.x.domain))
    if !isempty(prunedY)
        addToPrunedDomains!(prunedDomains, constraint.y, prunedY)
        triggerDomainChange!(toPropagate, constraint.y)
    end
    return !isempty(constraint.x.domain) && !isempty(constraint.y.domain)
end

variablesArray(constraint::LessOrEqual) = [constraint.x, constraint.y]

function Base.show(io::IO, ::MIME"text/plain", con::LessOrEqual)
    println(io, typeof(con), ": ", con.x.id, " ≤ ", con.y.id, ", active = ", con.active)
    println(io, "   ", con.x)
    println(io, "   ", con.y)
end

function Base.show(io::IO, con::LessOrEqual)
    print(io, typeof(con), ": ", con.x.id, " ≤ ", con.y.id)
end

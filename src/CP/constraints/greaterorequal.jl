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
    println(io, typeof(con), ": ", con.x.id, " ≥ ", con.v, ", active = ", con.active)
    print(io, "   ", con.x)
end

function Base.show(io::IO, con::GreaterOrEqualConstant)
    print(io, typeof(con), ": ", con.x.id, " ≥ ", con.v)
end





"""
    GreaterOrEqual(x::AbstractIntVar, y::AbstractIntVar, trailer::Trailer)

Inequality between variables constraint, states that `x >= y`
"""
struct GreaterOrEqual <: Constraint
    x       ::AbstractIntVar
    y       ::AbstractIntVar
    active  ::StateObject{Bool}

    """
        GreaterOrEqual(x::AbstractIntVar, y::AbstractIntVar, trailer::Trailer)

    Inequality between variables constraint, states that `x >= y`
    """
    function GreaterOrEqual(x::AbstractIntVar, y::AbstractIntVar, trailer)
        constraint = new(x, y, StateObject(true, trailer))
        addOnDomainChange!(x, constraint)
        addOnDomainChange!(y, constraint)
        return constraint
    end
end

"""
    propagate!(constraint::GreaterOrEqual, toPropagate::Set{Constraint}, prunedDomains::CPModification)

`GreaterOrEqual` propagation function.
"""
function propagate!(constraint::GreaterOrEqual, toPropagate::Set{Constraint}, prunedDomains::CPModification)


    if minimum(constraint.x.domain) >= maximum(constraint.y.domain)
        setValue!(constraint.active, false)
    end

    prunedX = removeBelow!(constraint.x.domain, minimum(constraint.y.domain))
    if !isempty(prunedX)
        addToPrunedDomains!(prunedDomains, constraint.x, prunedX)
        triggerDomainChange!(toPropagate, constraint.x)
    end

    prunedY = removeAbove!(constraint.y.domain, maximum(constraint.x.domain))
    if !isempty(prunedY)
        addToPrunedDomains!(prunedDomains, constraint.y, prunedY)
        triggerDomainChange!(toPropagate, constraint.y)
    end
    return !isempty(constraint.x.domain) && !isempty(constraint.y.domain)
end

variablesArray(constraint::GreaterOrEqual) = [constraint.x, constraint.y]

function Base.show(io::IO, ::MIME"text/plain", con::GreaterOrEqual)
    println(io, typeof(con), ": ", con.x.id, " ≥ ", con.y.id, ", active = ", con.active)
    println(io, "   ", con.x)
    println(io, "   ", con.y)
end

function Base.show(io::IO, con::GreaterOrEqual)
    print(io, typeof(con), ": ", con.x.id, " ≥ ", con.y.id)
end

"""
    Greater(x::AbstractIntVar, y::AbstractIntVar, trailer::Trailer)

Inequality between variables constraint, states that `x > y`
"""
struct Greater <: Constraint
    x       ::AbstractIntVar
    y       ::AbstractIntVar
    active  ::StateObject{Bool}

    """
        Greater(x::AbstractIntVar, y::AbstractIntVar, trailer::Trailer)

    Inequality between variables constraint, states that `x > y`
    """
    function Greater(x::AbstractIntVar, y::AbstractIntVar, trailer)
        constraint = new(x, y, StateObject(true, trailer))
        addOnDomainChange!(x, constraint)
        addOnDomainChange!(y, constraint)
        return constraint
    end
end

"""
    propagate!(constraint::Greater, toPropagate::Set{Constraint}, prunedDomains::CPModification)

`Greater` propagation function.
"""
function propagate!(constraint::Greater, toPropagate::Set{Constraint}, prunedDomains::CPModification)


    if minimum(constraint.x.domain) > maximum(constraint.y.domain)
        setValue!(constraint.active, false)
    end

    prunedX = removeBelow!(constraint.x.domain, minimum(constraint.y.domain)+1)
    if !isempty(prunedX)
        addToPrunedDomains!(prunedDomains, constraint.x, prunedX)
        triggerDomainChange!(toPropagate, constraint.x)
    end

    prunedY = removeAbove!(constraint.y.domain, maximum(constraint.x.domain)-1)
    if !isempty(prunedY)
        addToPrunedDomains!(prunedDomains, constraint.y, prunedY)
        triggerDomainChange!(toPropagate, constraint.y)
    end
    return !isempty(constraint.x.domain) && !isempty(constraint.y.domain)
end

variablesArray(constraint::Greater) = [constraint.x, constraint.y]

function Base.show(io::IO, ::MIME"text/plain", con::Greater)
    println(io, typeof(con), ": ", con.x.id, " > ", con.y.id, ", active = ", con.active)
    println(io, "   ", con.x)
    println(io, "   ", con.y)
end

function Base.show(io::IO, con::Greater)
    print(io, typeof(con), ": ", con.x.id, " > ", con.y.id)
end

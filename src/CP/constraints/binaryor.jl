"""
    BinaryOr(x::BoolVar, y::BoolVar, trailer::SeaPearl.Trailer)

Binary Or constraint, states that `x || y`.
"""
struct BinaryOr <: Constraint
    x::AbstractBoolVar
    y::AbstractBoolVar
    active::StateObject{Bool}

    function BinaryOr(x::AbstractBoolVar, y::AbstractBoolVar, trailer)
        constraint = new(x, y, StateObject{Bool}(true, trailer))
        addOnDomainChange!(x, constraint)
        addOnDomainChange!(y, constraint)
        return constraint
    end
end

"""
    propagate!(constraint::BinaryOr, toPropagate::Set{Constraint}, prunedDomains::CPModification)

`BinaryOr` propagation function.
"""
function propagate!(constraint::BinaryOr, toPropagate::Set{Constraint}, prunedDomains::CPModification)

    if isbound(constraint.x) && !assignedValue(constraint.x)
        prunedY = remove!(constraint.y.domain, false)
        if !isempty(prunedY)
            addToPrunedDomains!(prunedDomains, constraint.y, prunedY)
            triggerDomainChange!(toPropagate, constraint.y)
        end
        setValue!(constraint.active, false)
        return !isempty(constraint.y.domain)
    elseif isbound(constraint.y) && !assignedValue(constraint.y)
        prunedX = remove!(constraint.x.domain, false)
        if !isempty(prunedX)
            addToPrunedDomains!(prunedDomains, constraint.x, prunedX)
            triggerDomainChange!(toPropagate, constraint.x)
        end
        setValue!(constraint.active, false)
        return !isempty(constraint.x.domain)
    elseif (isbound(constraint.x) && assignedValue(constraint.x)) || (isbound(constraint.y) && assignedValue(constraint.y))
        setValue!(constraint.active, false)
    end

    return true
end

variablesArray(constraint::BinaryOr) = [constraint.x, constraint.y]

function Base.show(io::IO, ::MIME"text/plain", con::BinaryOr)
    println(io, string(typeof(con)), ": ", con.x.id, " ∨ ", con.y.id, ", active = ", con.active)
    println(io, "   ", con.x)
    print(io, "   ", con.y)
end

function Base.show(io::IO, con::BinaryOr)
    print(io, typeof(con), ": ", con.x.id, " ∨ ", con.y.id)
end

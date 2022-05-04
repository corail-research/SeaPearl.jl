"""
    BinaryImplication(x::BoolVar, y::BoolVar)

Binary implication constraint, states that `x => y`.
"""
struct BinaryImplication <: Constraint
    x::AbstractBoolVar
    y::AbstractBoolVar
    active::StateObject{Bool}

    function BinaryImplication(x::AbstractBoolVar, y::AbstractBoolVar, trailer)
        constraint = new(x, y, StateObject{Bool}(true, trailer))
        addOnDomainChange!(x, constraint)
        addOnDomainChange!(y, constraint)
        return constraint
    end
end

"""
    propagate!(constraint::BinaryImplication, toPropagate::Set{Constraint}, prunedDomains::CPModification)

`BinaryImplication` propagation function.
"""
function propagate!(constraint::BinaryImplication, toPropagate::Set{Constraint}, prunedDomains::CPModification)

    if isbound(constraint.x) && assignedValue(constraint.x)
        prunedY = remove!(constraint.y.domain, false)
        if !isempty(prunedY)
            addToPrunedDomains!(prunedDomains, constraint.y, prunedY)
            triggerDomainChange!(toPropagate, constraint.y)
        end
        setValue!(constraint.active, false)
        return !isempty(constraint.y.domain)
    elseif isbound(constraint.y) && !assignedValue(constraint.y)
        prunedX = remove!(constraint.x.domain, true)
        if !isempty(prunedX)
            addToPrunedDomains!(prunedDomains, constraint.x, prunedX)
            triggerDomainChange!(toPropagate, constraint.x)
        end
        setValue!(constraint.active, false)
        return !isempty(constraint.x.domain)
    elseif (isbound(constraint.x) && !assignedValue(constraint.x))
        setValue!(constraint.active, false)
    end

    return true
end

variablesArray(constraint::BinaryImplication) = [constraint.x, constraint.y]

function Base.show(io::IO, ::MIME"text/plain", con::BinaryImplication)
    println(io, string(typeof(con)), ": ", con.x.id, " => ", con.y.id, ", active = ", con.active)
    println(io, "   ", con.x)
    print(io, "   ", con.y)
end

function Base.show(io::IO, con::BinaryImplication)
    print(io, typeof(con), ": ", con.x.id, " => ", con.y.id)
end

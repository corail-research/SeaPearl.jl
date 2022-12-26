"""
    BinaryEquivalence(x::BoolVar, y::BoolVar, trailer::SeaPearl.Trailer)

Binary equivalence constraint, states that `x <=> y`.
"""
struct BinaryEquivalence <: Constraint
    x::AbstractBoolVar
    y::AbstractBoolVar
    active::StateObject{Bool}

    function BinaryEquivalence(x::AbstractBoolVar, y::AbstractBoolVar, trailer)
        constraint = new(x, y, StateObject{Bool}(true, trailer))
        addOnDomainChange!(x, constraint)
        addOnDomainChange!(y, constraint)
        return constraint
    end
end

"""
    propagate!(constraint::BinaryEquivalence, toPropagate::Set{Constraint}, prunedDomains::CPModification)

`BinaryEquivalence` propagation function.
"""
function propagate!(constraint::BinaryEquivalence, toPropagate::Set{Constraint}, prunedDomains::CPModification)

    if isbound(constraint.x)
        if assignedValue(constraint.x)
            prunedY = remove!(constraint.y.domain, false)
            if !isempty(prunedY)
                addToPrunedDomains!(prunedDomains, constraint.y, prunedY)
                triggerDomainChange!(toPropagate, constraint.y)
            end
            setValue!(constraint.active, false)
            return !isempty(constraint.y.domain)
        else
            prunedY = remove!(constraint.y.domain, true)
            if !isempty(prunedY)
                addToPrunedDomains!(prunedDomains, constraint.y, prunedY)
                triggerDomainChange!(toPropagate, constraint.y)
            end
            setValue!(constraint.active, false)
            return !isempty(constraint.y.domain)
        end
    elseif isbound(constraint.y)
        if assignedValue(constraint.y)
            prunedX = remove!(constraint.x.domain, false)
            if !isempty(prunedX)
                addToPrunedDomains!(prunedDomains, constraint.x, prunedX)
                triggerDomainChange!(toPropagate, constraint.x)
            end
            setValue!(constraint.active, false)
            return !isempty(constraint.x.domain)
        else
            prunedX = remove!(constraint.x.domain, true)
            if !isempty(prunedX)
                addToPrunedDomains!(prunedDomains, constraint.x, prunedX)
                triggerDomainChange!(toPropagate, constraint.x)
            end
            setValue!(constraint.active, false)
            return !isempty(constraint.x.domain)
        end
    end
    return true
end

variablesArray(constraint::BinaryEquivalence) = [constraint.x, constraint.y]

function Base.show(io::IO, ::MIME"text/plain", con::BinaryEquivalence)
    println(io, string(typeof(con)), ": ", con.x.id, " <=> ", con.y.id, ", active = ", con.active)
    println(io, "   ", con.x)
    print(io, "   ", con.y)
end

function Base.show(io::IO, con::BinaryEquivalence)
    print(io, typeof(con), ": ", con.x.id, " <=> ", con.y.id)
end

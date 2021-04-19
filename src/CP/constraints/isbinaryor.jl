"""
    isBinaryOr(b::AbstractBoolVar, x::AbstractBoolVar, y::AbstractBoolVar)

Is Or constraint, states that `b <=> x or y`.
"""
struct isBinaryOr <: Constraint
    b::AbstractBoolVar
    x::AbstractBoolVar
    y::AbstractBoolVar
    active::StateObject{Bool}

    function isBinaryOr(b::AbstractBoolVar, x::AbstractBoolVar, y::AbstractBoolVar, trailer)
        constraint = new(b, x, y, StateObject{Bool}(true, trailer))
        addOnDomainChange!(b, constraint)
        addOnDomainChange!(x, constraint)
        addOnDomainChange!(y, constraint)
        return constraint
    end
end

"""
    propagate!(constraint::isBinaryOr, toPropagate::Set{Constraint}, prunedDomains::CPModification)

`isBinaryOr` propagation function.
"""
function propagate!(constraint::isBinaryOr, toPropagate::Set{Constraint}, prunedDomains::CPModification)
    if isbound(constraint.b)
        if !assignedValue(constraint.b)
            prunedX = remove!(constraint.x.domain, true)
            prunedY = remove!(constraint.y.domain, true)
            if !isempty(prunedX)
                addToPrunedDomains!(prunedDomains, constraint.x, prunedX)
                triggerDomainChange!(toPropagate, constraint.x)
            end
            if !isempty(prunedY)
                addToPrunedDomains!(prunedDomains, constraint.y, prunedY)
                triggerDomainChange!(toPropagate, constraint.y)
            end
            setValue!(constraint.active, false)
            return !isempty(constraint.x.domain) && !isempty(constraint.y.domain)
        else # b is true
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
        end
    else # b not bound
        if (isbound(constraint.x) && assignedValue(constraint.x)) || (isbound(constraint.y) && assignedValue(constraint.y))
            prunedB = remove!(constraint.b.domain, false)
            addToPrunedDomains!(prunedDomains, constraint.b, prunedB)
            triggerDomainChange!(toPropagate, constraint.b)
            setValue!(constraint.active, false)
            return true
        elseif (isbound(constraint.x) && !assignedValue(constraint.x)) && (isbound(constraint.y) && !assignedValue(constraint.y))
            prunedB = remove!(constraint.b.domain, true)
            addToPrunedDomains!(prunedDomains, constraint.b, prunedB)
            triggerDomainChange!(toPropagate, constraint.b)
            setValue!(constraint.active, false)
            return true
        end
    end

    return true
end

variablesArray(constraint::isBinaryOr) = [constraint.b, constraint.x, constraint.y]

function Base.show(io::IO, ::MIME"text/plain", con::isBinaryOr)
    println(io, typeof(con), ": ", con.b.id, " <=> ", con.x.id, " || ", con.y.id, ", active = ", con.active)
    println(io, "   ", con.x)
end

function Base.show(io::IO, con::isBinaryOr)
    print(io, typeof(con), ": ", con.b.id, " <=> ", con.x.id, " || ", con.y.id)
end

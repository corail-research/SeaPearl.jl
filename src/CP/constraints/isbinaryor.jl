"""
    isBinaryOr(b::BoolVar, x::BoolVar, y::BoolVar)

Is Or constraint, states that `b <=> x or y`.
"""
struct isBinaryOr <: Constraint
    b::BoolVar
    x::BoolVar
    y::BoolVar
    active::StateObject{Bool}

    function isBinaryOr(b::BoolVar, x::BoolVar, y::BoolVar, trailer)
        constraint = new(b, x, y, StateObject{Bool}(true, trailer))
        addOnDomainChange!(b, constraint)
        addOnDomainChange!(x, constraint)
        addOnDomainChange!(y, constraint)
        return constraint
    end
end

"""
    propagate!(constraint::isBinaryOr, toPropagate::Set{Constraint}, prunedDomains::CPModification)

`isBinaryOr` propagation function. The pruning is quite superficial.
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
            end
        end
    else # b not bound
        if isbound(constraint.x) && isbound(constraint.y)
            if assignedValue(constraint.x) || assignedValue(constraint.y)
                prunedB = remove!(constraint.b.domain, false)
                addToPrunedDomains!(prunedDomains, constraint.b, prunedB)
                triggerDomainChange!(toPropagate, constraint.b)
                setValue!(constraint.active, false)
                return true
            elseif !assignedValue(constraint.x) && !assignedValue(constraint.y)
                prunedB = remove!(constraint.b.domain, true)
                addToPrunedDomains!(prunedDomains, constraint.b, prunedB)
                triggerDomainChange!(toPropagate, constraint.b)
                setValue!(constraint.active, false)
                return true
            end
        end
    end

    return true
end

variablesArray(constraint::isBinaryOr) = [constraint.b, constraint.x, constraint.y]
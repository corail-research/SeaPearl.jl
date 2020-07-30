"""
    isOr(x::BoolVar, y::BoolVar)

Is Or constraint, states that `x || y`.
"""
struct isOr <: Constraint
    x::BoolVar
    y::BoolVar
    active::StateObject{Bool}

    function isOr(x::BoolVar, y::BoolVar, trailer)
        constraint = new(x, y, StateObject{Bool}(true, trailer))
        addOnDomainChange!(x, constraint)
        addOnDomainChange!(y, constraint)
        return constraint
    end
end

"""
    propagate!(constraint::isOr, toPropagate::Set{Constraint}, prunedDomains::CPModification)

`isOr` propagation function. The pruning is quite superficial.
"""
function propagate!(constraint::isOr, toPropagate::Set{Constraint}, prunedDomains::CPModification)
    
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

variablesArray(constraint::isBinaryOr) = [constraint.x, constraint.y]
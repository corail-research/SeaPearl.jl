
struct isLessOrEqual <: Constraint
    b       ::BoolVar
    x       ::AbstractIntVar
    y       ::AbstractIntVar
    active  ::StateObject{Bool}

    """
        isLessOrEqual(b::BoolVar, x::AbstractIntVar, y::AbstractIntVar, trailer::Trailer)

    Equivalence between a boolean variable and the inequality between variables, states that `b <=> x <= y`
    """
    function isLessOrEqual(b, x, y, trailer)
        constraint = new(b, x, y, StateObject(true, trailer))
        addOnDomainChange!(b, constraint)
        addOnDomainChange!(x, constraint)
        addOnDomainChange!(y, constraint)
        return constraint
    end
end

"""
    propagate!(constraint::isLessOrEqual, toPropagate::Set{Constraint}, prunedDomains::CPModification)

`isLessOrEqual` propagation function.
"""
function propagate!(constraint::isLessOrEqual, toPropagate::Set{Constraint}, prunedDomains::CPModification)
    
    if !isbound(constraint.b)
        if maximum(constraint.x.domain) <= minimum(constraint.y.domain)
            prunedB = remove!(constraint.b.domain, false)
            if !isempty(prunedB)
                addToPrunedDomains!(prunedDomains, constraint.b, prunedB)
                triggerDomainChange!(toPropagate, constraint.b)
            end
            setValue!(constraint.active, false)
        elseif minimum(constraint.x.domain) > maximum(constraint.y.domain)
            prunedB = remove!(constraint.b.domain, true)
            if !isempty(prunedB)
                addToPrunedDomains!(prunedDomains, constraint.b, prunedB)
                triggerDomainChange!(toPropagate, constraint.b)
            end
        end
        return true
    else
        if assignedValue(constraint.b) 
            # propagate constraint x <= y
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
        else
            # propagate constraint x > y which is y <= x -1
            if maximum(constraint.y.domain) <= minimum(constraint.x.domain) - 1
                setValue!(constraint.active, false)
            end
        
            prunedY = removeAbove!(constraint.y.domain, maximum(constraint.x.domain) - 1)
            if !isempty(prunedY)
                addToPrunedDomains!(prunedDomains, constraint.y, prunedY)
                triggerDomainChange!(toPropagate, constraint.y)
            end
            
            prunedX = removeBelow!(constraint.x.domain, minimum(constraint.x.domain) - 1)
            if !isempty(prunedX)
                addToPrunedDomains!(prunedDomains, constraint.x, prunedX)
                triggerDomainChange!(toPropagate, constraint.x)
            end
            return !isempty(constraint.x.domain) && !isempty(constraint.y.domain)
        end
    end
    # should not get there
    return false 
end

variablesArray(constraint::isLessOrEqual) = [constraint.b, constraint.x, constraint.y]

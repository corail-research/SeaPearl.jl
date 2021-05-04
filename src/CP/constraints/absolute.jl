"""
    Absolute(x::SeaPearl.AbstractIntVar, y::SeaPearl.AbstractIntVar)

Absolute value constraint, enforcing y = |x|.
"""
struct Absolute <: Constraint
    x::AbstractIntVar
    y::AbstractIntVar
    active::StateObject{Bool}

    function Absolute(x, y, trailer)
        constraint = new(x, y, StateObject(true, trailer))
        removeBelow!(y.domain, 0) # y cannot take a negative value
        addOnDomainChange!(x, constraint)
        addOnDomainChange!(y, constraint)
        return constraint
    end
end


"""
    propagate!(constraint::Absolute, toPropagate::Set{Constraint}, prunedDomains::CPModification)

"Propagate the 'Absolute' constraint.
"""
function propagate!(constraint::Absolute, toPropagate::Set{Constraint}, prunedDomains::CPModification)

    if isbound(constraint.x) 
        prunedY = assign!(constraint.y, abs(assignedValue(constraint.x)))
        addToPrunedDomains!(prunedDomains, constraint.y, prunedY)
        triggerDomainChange!(toPropagate, constraint.y)
        setValue!(constraint.active, false)

    elseif isbound(constraint.y) # x is equal to y or -y
    
        for v in minimum(constraint.x.domain):maximum(constraint.x.domain)
            if v != assignedValue(constraint.y) && v != -assignedValue(constraint.y)
                # remove everything in x domain except y and -y
                prunedX = remove!(constraint.x.domain,v)
                addToPrunedDomains!(prunedDomains, constraint.x, prunedX)
                triggerDomainChange!(toPropagate, constraint.x)
            end
        end
        setValue!(constraint.active, false)
    else # no variable is bound

        prunedValuesX = Int[]
        prunedValuesY = Int[]
        if minimum(constraint.x.domain) >= 0
            append!(prunedValuesY, removeBelow!(constraint.y.domain, minimum(constraint.x.domain)))
            append!(prunedValuesY, removeAbove!(constraint.y.domain, maximum(constraint.x.domain)))
            append!(prunedValuesX, removeBelow!(constraint.x.domain, minimum(constraint.y.domain)))
            append!(prunedValuesX, removeAbove!(constraint.x.domain, maximum(constraint.y.domain)))

        elseif maximum(constraint.x.domain) <= 0
            append!(prunedValuesY, removeBelow!(constraint.y.domain, -maximum(constraint.x.domain)))
            append!(prunedValuesY, removeAbove!(constraint.y.domain, -minimum(constraint.x.domain)))
            append!(prunedValuesX, removeBelow!(constraint.x.domain, -maximum(constraint.y.domain)))
            append!(prunedValuesX, removeAbove!(constraint.x.domain, -minimum(constraint.y.domain)))

        else 
            maxAbs = max(maximum(constraint.x.domain), -minimum(constraint.x.domain))
            append!(prunedValuesY, removeAbove!(constraint.y.domain, maxAbs))
            append!(prunedValuesX, removeBelow!(constraint.x.domain, -maximum(constraint.y.domain)))
            append!(prunedValuesX, removeAbove!(constraint.x.domain, maximum(constraint.y.domain)))
        end
        addToPrunedDomains!(prunedDomains, constraint.x, prunedValuesX)
        addToPrunedDomains!(prunedDomains, constraint.y, prunedValuesY)
        triggerDomainChange!(toPropagate, constraint.x)
        triggerDomainChange!(toPropagate, constraint.y)
    end

    return true

end

variablesArray(constraint::Absolute) = [constraint.x, constraint.y]

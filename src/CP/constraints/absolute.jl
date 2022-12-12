"""
    Absolute(x::SeaPearl.AbstractIntVar, y::SeaPearl.AbstractIntVar, ::SeaPearl.Trailer)

Absolute value constraint, enforcing y = |x|.
"""
struct Absolute <: Constraint
    x::AbstractIntVar
    y::AbstractIntVar
    active::StateObject{Bool}
    initialized::StateObject{Bool}

    function Absolute(x, y, trailer)
        constraint = new(x, y, StateObject(true, trailer), StateObject(false, trailer))
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

    if !constraint.initialized.value
        setValue!(constraint.initialized, true)
        prunedY = removeBelow!(constraint.y.domain, 0) # y cannot take a negative value
        addToPrunedDomains!(prunedDomains, constraint.y, prunedY)
        triggerDomainChange!(toPropagate, constraint.y)
    end

    if isbound(constraint.x) 
        value = abs(assignedValue(constraint.x))
        if !(value in constraint.y.domain)
            return false
        end

        prunedY = assign!(constraint.y, value)
        addToPrunedDomains!(prunedDomains, constraint.y, prunedY)
        triggerDomainChange!(toPropagate, constraint.y)
        setValue!(constraint.active, false)

    elseif isbound(constraint.y) # x is equal to y or -y
        value = assignedValue(constraint.y)
        if !(value in constraint.x.domain || -value in constraint.x.domain)
            return false
        end
    
        for v in minimum(constraint.x.domain):maximum(constraint.x.domain)
            if v != value && v != -value
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

    if isempty(constraint.x.domain) || isempty(constraint.y.domain)
        return false
    end

    if constraint in toPropagate
        pop!(toPropagate, constraint)
    end

    return true

end

variablesArray(constraint::Absolute) = [constraint.x, constraint.y]

function Base.show(io::IO, ::MIME"text/plain", con::Absolute)
    println(io, string(typeof(con)), ": |", con.x.id, "| = ", con.y.id, ", active = ", con.active.value)
    println(io, "   ", con.x)
    print(io, "   ", con.y)
end

function Base.show(io::IO, con::Absolute)
    print(io, string(typeof(con)), ": |", con.x.id, "| = ", con.y.id)
end
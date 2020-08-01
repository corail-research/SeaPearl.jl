"""
    BinaryMaximum(x::AbstractIntVar, y::AbstractIntVar, z::AbstractIntVar, trailer)

BinaryMaximum constraint, states that `x == max(y, z)`
"""
struct BinaryMaximumBC <: Constraint
    x::AbstractIntVar
    y::AbstractIntVar
    z::AbstractIntVar
    active::StateObject{Bool}

    function BinaryMaximumBC(x::AbstractIntVar, y::AbstractIntVar, z::AbstractIntVar, trailer)
        constraint = new(x, y, z, StateObject{Bool}(true, trailer))
        for xi in [x, y, z]
            addOnDomainChange!(xi, constraint)
        end
        return constraint
    end
end
        
"""
    propagate!(constraint::BinaryMaximumBC, toPropagate::Set{Constraint}, prunedDomains::CPModification)

`BinaryMaximumBC` propagation function. 
"""
function propagate!(constraint::BinaryMaximumBC, toPropagate::Set{Constraint}, prunedDomains::CPModification)
    min_x, min_y, min_z = minimum(constraint.x.domain), minimum(constraint.y.domain), minimum(constraint.z.domain)
    max_x, max_y, max_z = minimum(constraint.x.domain), maximum(constraint.y.domain), maximum(constraint.z.domain)
    max_of_min = max(min_y, min_z)
    max_of_max = max(max_y, max_z)
    
    # feasibility
    if min_x > max_of_max
        return false 
    end

    # bound pruning
    if min_x < max_of_min || max_x > max_of_max
        prunedX = vcat(removeBelow!(constraint.x, max_of_min), removeAbove!(constraint.x, max_of_max))
        addToPrunedDomains!(prunedDomains, constraint.x, prunedX)
        triggerDomainChange!(toPropagate, constraint.x)
    end

    # if one of y, z dominate the other, the dominant can help assign x and x can help prune the dominant one 
    if min_y > max_z # y is dominant on z 
        # y try to assign a value to x 
        if isbound(constraint.y)
            prunedX = assign!(constraint.x, assignedValue(constraint.y))
            if !isempty(prunedX)
                addToPrunedDomains!(prunedDomains, constraint.x, prunedX)
                triggerDomainChange!(toPropagate, constraint.x)
            end
            setValue!(constraint.active, false)
        end
        # x trying to prune y 
        prunedY = removeBelow!(constraint.y.domain, min_x)
        if !isempty(prunedY)
            addToPrunedDomains!(prunedDomains, constraint.y, prunedY)
            triggerDomainChange!(toPropagate, constraint.y)
        end
    elseif min_z > max_y # z is dominant on y 
        # 
        if isbound(constraint.z)
            prunedX = assign!(constraint.x, assignedValue(constraint.z))
            if !isempty(prunedX)
                addToPrunedDomains!(prunedDomains, constraint.x, prunedX)
                triggerDomainChange!(toPropagate, constraint.x)
            end
            setValue!(constraint.active, false)
        end
        prunedZ = removeBelow!(constraint.z.domain, min_x)
        if !isempty(prunedZ)
            addToPrunedDomains!(prunedDomains, constraint.z, prunedZ)
            triggerDomainChange!(toPropagate, constraint.z)
        end
    end

    return true
end

variablesArray(constraint::BinaryMaximumBC) = [constraint.x, constraint.y, constraint.z]
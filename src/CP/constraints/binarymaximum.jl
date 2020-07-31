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
    if min_x < max_of_min
        prunedX = removeBelow!(constraint.x, max_of_min)
        addToPrunedDomains!(prunedDomains, constraint.x, prunedX)
        triggerDomainChange!(toPropagate, constraint.x)
    end

    return true
end

variablesArray(constraint::BinaryMaximumBC) = [constraint.x, constraint.y, constraint.z]
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
    max_x, max_y, max_z = maximum(constraint.x.domain), maximum(constraint.y.domain), maximum(constraint.z.domain)
    max_of_min = max(min_y, min_z)
    max_of_max = max(max_y, max_z)
    min_of_min = min(min_y, min_z)

    # feasibility
    if min_x > max_of_max || max_x < min_of_min
        return false
    end

    # y & z pruning x
    if min_x < max_of_min || max_x > max_of_max
        prunedX = vcat(removeBelow!(constraint.x.domain, max_of_min), removeAbove!(constraint.x.domain, max_of_max))
        addToPrunedDomains!(prunedDomains, constraint.x, prunedX)
        triggerDomainChange!(toPropagate, constraint.x)
    end

    # x pruning y & z
    if min_x > max_z # if x can only be associated to y
        # x trying to prune y
        prunedY = vcat(removeBelow!(constraint.y.domain, min_x), removeAbove!(constraint.y.domain, max_x))
        if !isempty(prunedY)
            addToPrunedDomains!(prunedDomains, constraint.y, prunedY)
            triggerDomainChange!(toPropagate, constraint.y)
        end
    elseif min_x > max_y # if x can only be associated to z
        # x trying to prune z
        prunedZ = vcat(removeBelow!(constraint.z.domain, min_x), removeAbove!(constraint.z.domain, max_x))
        if !isempty(prunedZ)
            addToPrunedDomains!(prunedDomains, constraint.z, prunedZ)
            triggerDomainChange!(toPropagate, constraint.z)
        end
    end

    # deactivation
    if isbound(constraint.x) + isbound(constraint.y) + isbound(constraint. z) >= 2
        setValue!(constraint.active, false)
    end

    return !isempty(constraint.x.domain) & !isempty(constraint.y.domain) & !isempty(constraint.z.domain)
end

variablesArray(constraint::BinaryMaximumBC) = [constraint.x, constraint.y, constraint.z]

function Base.show(io::IO, ::MIME"text/plain", con::BinaryMaximumBC)
    println(io, string(typeof(con)), ": ", con.x.id, " == max(", con.y.id, con.z.id, "), ", "active = ", con.active)
    println(io, "   ", con.x)
    println(io, "   ", con.y)
    print(io, "   ", con.z)
end

function Base.show(io::IO, con::BinaryMaximumBC)
    print(io, typeof(con), ": ", con.x.id, " == max(", con.y.id, con.z.id, ")")
end

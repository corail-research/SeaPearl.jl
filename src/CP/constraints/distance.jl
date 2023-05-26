"""
    Distance(x::SeaPearl.AbstractIntVar, y::SeaPearl.AbstractIntVar, z::SeaPearl.AbstractIntVar,trailer::SeaPearl.Trailer)

Distance constraint, `z == |x - y|`
"""
struct Distance <: Constraint
    x       ::AbstractIntVar
    y       ::AbstractIntVar
    z       ::AbstractIntVar
    active  ::StateObject{Bool}
    function Distance(x::AbstractIntVar, y::AbstractIntVar, z::AbstractIntVar, trailer)
        constraint = new(x, y, z, StateObject(true, trailer))
        addOnDomainChange!(x, constraint)
        addOnDomainChange!(y, constraint)
        addOnDomainChange!(z, constraint)
        return constraint
    end
end

"""
    distanceBounds!(xMin::Int, xMax::Int, yMin::Int, yMax::Int)

Bounds for the new distance variable z = |x - y|
"""
function distanceBounds!(xMin::Int, xMax::Int, yMin::Int, yMax::Int)
    zMax1 = xMax - yMin
    zMax2 = yMax - xMin
    zMax = max(zMax1, zMax2)

    # z is a positive variable
    zMin = 0

    # If x and y domains are disjunctive
    zMin1 = xMin - yMax
    if zMin1 > 0
        zMin = zMin1
    end

    # If x and y domains are disjunctive
    zMin2 = yMin - xMax
    if zMin2 > 0 & (zMin1 < 0 || zMin2 < zMin1)
        zMin = zMin2
    end

    return zMin, zMax
end

"""
    propagate!(constraint::Distance, toPropagate::Set{Constraint}, prunedDomains::CPModification)

`Distance` propagation function.
"""
function propagate!(constraint::Distance, toPropagate::Set{Constraint}, prunedDomains::CPModification)
    if !constraint.active.value
        return true
    end

    xDomain = constraint.x.domain
    yDomain = constraint.y.domain
    zDomain = constraint.z.domain

    # Prune z domain
    zMin, zMax = distanceBounds!(minimum(xDomain), maximum(xDomain), minimum(yDomain), maximum(yDomain))

    prunedZ = vcat(removeBelow!(zDomain, zMin), removeAbove!(zDomain, zMax))

    if !isempty(prunedZ)
        triggerDomainChange!(toPropagate, constraint.z)
        addToPrunedDomains!(prunedDomains, constraint.z, prunedZ)
    end

    # Prune x domain

    xMax1 = maximum(zDomain) + maximum(yDomain)
    xMax2 = maximum(yDomain) - minimum(zDomain)
    xMax = max(xMax1, xMax2)

    xMin1 = minimum(zDomain) + minimum(yDomain)
    xMin2 = minimum(yDomain) - maximum(zDomain)
    xMin = min(xMin1, xMin2)

    prunedX = vcat(removeBelow!(xDomain, xMin), removeAbove!(xDomain, xMax))

    if !isempty(prunedX)
        triggerDomainChange!(toPropagate, constraint.x)
        addToPrunedDomains!(prunedDomains, constraint.x, prunedX)
    end

    # Prune y domain

    yMax1 = maximum(xDomain) + maximum(zDomain)
    yMax2 = maximum(xDomain) - minimum(zDomain)
    yMax = max(yMax1, yMax2)

    yMin1 = minimum(xDomain) + minimum(zDomain)
    yMin2 = minimum(xDomain) - maximum(zDomain)
    yMin = min(yMin1, yMin2)

    prunedY = vcat(removeBelow!(yDomain, yMin), removeAbove!(yDomain, yMax))

    if !isempty(prunedY)
        triggerDomainChange!(toPropagate, constraint.y)
        addToPrunedDomains!(prunedDomains, constraint.y, prunedY)
    end

    if isbound(constraint.x) & isbound(constraint.y) & isbound(constraint.z)
        setValue!(constraint.active, false)
    end
    if isempty(constraint.x.domain) || isempty(constraint.y.domain) || isempty(constraint.z.domain)
        return false
    end
    return true


end

variablesArray(constraint::Distance) = [constraint.x, constraint.y, constraint.z]

function Base.show(io::IO, ::MIME"text/plain", con::Distance)
    println(io, typeof(con), ": ", con.z.id, " == |", con.x.id, " - ", con.y.id, "|",", active = ", con.active)
    println(io, "   ", con.x)
end

function Base.show(io::IO, con::Distance)
    print(io, typeof(con), ": ", con.z.id, " == |", con.x.id, " - ", con.y.id, "|")
end
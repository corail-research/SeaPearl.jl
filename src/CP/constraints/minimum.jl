"""
    MinimumConstraint(x::Array{<:AbstractIntVar},y::AbstractIntVar, trailer::SeaPearl.Trailer) <: Constraint
    
Minimum constraint, states that `y = max(x)`
"""
struct MinimumConstraint <: Constraint
    x                   :: Array{<:AbstractIntVar}
    y                   :: AbstractIntVar
    active              :: StateObject{Bool}
    function MinimumConstraint(x::Array{<:AbstractIntVar},y::AbstractIntVar, trailer)
        @assert !isempty(x)
        
        constraint = new(x, y, StateObject(true,trailer))
        for i in 1:length(x)
            addOnDomainChange!(x[i], constraint)
        end
        addOnDomainChange!(y, constraint)
        return constraint
    end
end

"""
    propagate!(constraint::MinimumConstraint, toPropagate::Set{Constraint}, prunedDomains::CPModification)

`MinimumConstraint` propagation function.
"""
function propagate!(constraint::MinimumConstraint, toPropagate::Set{Constraint}, prunedDomains::CPModification)
    max = typemax(Int)
    min = typemax(Int)
    nSupport = 0
    supportIdx = -1
    for i in 1:length(constraint.x)
        prunedX = removeBelow!(constraint.x[i].domain, minimum(constraint.y.domain))
        if !isempty(prunedX)
            addToPrunedDomains!(prunedDomains, constraint.x[i], prunedX)
            triggerDomainChange!(toPropagate, constraint.x[i])
        end
        if maximum(constraint.x[i].domain) < max
            max = maximum(constraint.x[i].domain)
        end
        if minimum(constraint.x[i].domain) < min
            min = minimum(constraint.x[i].domain)
        end
        if minimum(constraint.x[i].domain) <= maximum(constraint.y.domain)
            nSupport += 1
            supportIdx = i
        end
    end

    if nSupport == 0 
        return false

    elseif nSupport == 1
        prunedX = removeAbove!(constraint.x[supportIdx].domain, maximum(constraint.y.domain))
        if !isempty(prunedX)
            addToPrunedDomains!(prunedDomains, constraint.x[supportIdx], prunedX)
            triggerDomainChange!(toPropagate, constraint.x[supportIdx])
        end
        prunedY1 = removeAbove!(constraint.y.domain, maximum(constraint.x[supportIdx].domain))

    else 
        prunedY1 = removeAbove!(constraint.y.domain, max)
    end

    prunedY2 = removeBelow!(constraint.y.domain, min)
    prunedY = vcat(prunedY1, prunedY2)
    if !isempty(prunedY)
        addToPrunedDomains!(prunedDomains, constraint.y, prunedY)
        triggerDomainChange!(toPropagate, constraint.y)
    end
    if all(isbound.(constraint.x))
        setValue!(constraint.active, false)
    end
    return !isempty(constraint.y.domain)
end

function variablesArray(constraint::MinimumConstraint)
    variables = AbstractIntVar[]
    append!(variables, constraint.x)
    push!(variables, constraint.y)
    return variables
end

function Base.show(io::IO, ::MIME"text/plain", con::MinimumConstraint)
    ids = [var.id for var in con.x]
    yid = con.y.id
    print(io, typeof(con), ": ", yid, " = max(" ,join(ids, " , "), "), active = ", con.active)
    for var in con.x
        print(io, "\n   ", var)
    end
end

function Base.show(io::IO, con::MinimumConstraint)
    ids = [var.id for var in con.x]
    yid = con.y.id
    print(io, typeof(con), ": ", yid, " = max(" , join(ids, " , "), ")")
end
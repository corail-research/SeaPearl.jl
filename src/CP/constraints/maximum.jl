"""
    maximum(x<:AbstractIntVar, v::Int)

Maximum constraint, states that `y = max(x)`
"""
struct MaximumConstraint <: Constraint
    x                   :: Array{<:AbstractIntVar}
    y                   :: AbstractIntVar
    active              :: StateObject{Bool}
    function MaximumConstraint(x::Array{<:AbstractIntVar},y::AbstractIntVar, trailer)
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
    propagate!(constraint::MaximumConstraint, toPropagate::Set{Constraint}, prunedDomains::CPModification)

`MaximumConstraint` propagation function.
"""
function propagate!(constraint::MaximumConstraint, toPropagate::Set{Constraint}, prunedDomains::CPModification)
    max = typemin(Int)
    min = typemin(Int)
    nSupport = 0
    supportIdx = -1
    for i in 1:length(constraint.x)
        prunedX = removeAbove!(constraint.x[i].domain, maximum(constraint.y.domain))
        if !isempty(prunedX)
            addToPrunedDomains!(prunedDomains, constraint.x[i], prunedX)
            triggerDomainChange!(toPropagate, constraint.x[i])
        end
        if maximum(constraint.x[i].domain) > max
            max = maximum(constraint.x[i].domain)
        end
        if minimum(constraint.x[i].domain) > min
            min = minimum(constraint.x[i].domain)
        end
        if maximum(constraint.x[i].domain) >= minimum(constraint.y.domain)
            nSupport += 1
            supportIdx = i
        end
    end
    if nSupport == 1
        prunedX = removeBelow!(constraint.x[supportIdx].domain, minimum(constraint.y.domain))
        if !isempty(prunedX)
            addToPrunedDomains!(prunedDomains, constraint.x[supportIdx], prunedX)
            triggerDomainChange!(toPropagate, constraint.x[supportIdx])
        end
    end
    prunedY1 = removeAbove!(constraint.y.domain, max)
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

function variablesArray(constraint::MaximumConstraint)
    variables = AbstractIntVar[]
    append!(variables, constraint.x)
    push!(variables, constraint.y)
    return variables
end

function Base.show(io::IO, ::MIME"text/plain", con::MaximumConstraint)
    ids = [var.id for var in con.x]
    yid = con.y.id
    print(io, typeof(con), ": ", yid, " = max(" ,join(ids, " , "), "), active = ", con.active)
    for var in con.x
        print(io, "\n   ", var)
    end
end

function Base.show(io::IO, con::MaximumConstraint)
    ids = [var.id for var in con.x]
    yid = con.y.id
    print(io, typeof(con), ": ", yid, " = max(" , join(ids, " , "), ")")
end

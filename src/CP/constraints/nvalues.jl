"""
    NValuesConstraint(x::Array{<:AbstractIntVar},y::AbstractIntVar, trailer::SeaPearl.Trailer) <: Constraint
    
N-Values constraint, states that `y = |∪ D(x_i)|`
"""
struct NValuesConstraint <: Constraint
    x                   :: Array{<:AbstractIntVar}
    y                   :: AbstractIntVar
    active              :: StateObject{Bool}
    function NValuesConstraint(x::Array{<:AbstractIntVar},y::AbstractIntVar, trailer)
        @assert !isempty(x)
        
        constraint = new(x, y, StateObject(true,trailer))
        for i in 1:length(x)
            addOnDomainChange!(x[i], constraint)
        end
        return constraint
    end
end

"""
    propagate!(constraint::NValuesConstraint, toPropagate::Set{Constraint}, prunedDomains::CPModification)

`NValuesConstraint` propagation function.
"""
function propagate!(constraint::NValuesConstraint, toPropagate::Set{Constraint}, prunedDomains::CPModification)

    support = Dict{Int, Bool}()
    counter = 0

    for i in 1:length(constraint.x)
        for v in constraint.x[i].domain
            if !haskey(support, v)
                support[v] = true
                counter += 1
            end
        end
    end
    
    prunedY = removeAbove!(constraint.y.domain, counter)
    if !isempty(prunedY)
        addToPrunedDomains!(prunedDomains, constraint.y, prunedY)
        triggerDomainChange!(toPropagate, constraint.y)
    end
    
    if all(isbound.(constraint.x))
        setValue!(constraint.active, false)
    end
    return !isempty(constraint.y.domain)
end

function variablesArray(constraint::NValuesConstraint)
    variables = AbstractIntVar[]
    append!(variables, constraint.x)
    push!(variables, constraint.y)
    return variables
end

function Base.show(io::IO, ::MIME"text/plain", con::NValuesConstraint)
    ids = [var.id for var in con.x]
    yid = con.y.id
    print(io, typeof(con), ": ", yid, " = |D(" ,join(ids, ") ∪ D("), ")|, active = ", con.active)
    for var in con.x
        print(io, "\n   ", var)
    end
end

function Base.show(io::IO, con::NValuesConstraint)
    ids = [var.id for var in con.x]
    yid = con.y.id
    print(io, typeof(con), ": ", yid, " = |D(" ,join(ids, ") ∪ D("), ")|")
end

function init_nValues_variable(x::Array{<:AbstractIntVar}, id::String, trailer::SeaPearl.Trailer)
    min_values = typemax(Int)
    max_values = typemin(Int)
    for i in 1:length(x)
        m = x[i].domain.min.value
        M = x[i].domain.max.value
        if m < min_values
            min_values = m
        end
        if M > max_values
            max_values = M
        end
    end

    return SeaPearl.IntVar(1, max_values-min_values+1, id, trailer)
end

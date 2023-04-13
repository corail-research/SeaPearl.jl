abstract type EqualConstraint <: Constraint end

"""
    EqualConstant(x::SeaPearl.AbstractIntVar, v::Int, SeaPearl.trailer)

Equality constraint, putting a constant value `v` for the variable `x` i.e. `x == v`.
"""
struct EqualConstant <: EqualConstraint
    x       ::SeaPearl.AbstractIntVar
    v       ::Int
    active  ::StateObject{Bool}
    function EqualConstant(x::SeaPearl.AbstractIntVar, v::Int, trailer)
        constraint = new(x, v, StateObject{Bool}(true, trailer))
        addOnDomainChange!(x, constraint)
        return constraint
    end
end

"""
    propagate!(constraint::EqualConstant, toPropagate::Set{Constraint}, prunedDomains::CPModification)

`EqualConstant` propagation function. Basically set the `x` domain to the constant value.
"""
function propagate!(constraint::EqualConstant, toPropagate::Set{Constraint}, prunedDomains::CPModification)
    # Reduce the domain to a singleton if possible
    if constraint.v in constraint.x.domain
        removed = assign!(constraint.x.domain, constraint.v)
        setValue!(constraint.active, false)
        triggerDomainChange!(toPropagate, constraint.x)
        addToPrunedDomains!(prunedDomains, constraint.x, removed)
        return true
    end

    # Reduce the domain to an empty set if value not in domain, not feasible => no propagation
    removed = removeAll!(constraint.x.domain)
    setValue!(constraint.active, false)
    addToPrunedDomains!(prunedDomains, constraint.x, removed)
    return false
end

variablesArray(constraint::EqualConstant) = [constraint.x]

function Base.show(io::IO, ::MIME"text/plain", con::EqualConstant)
    println(io, typeof(con), ": ", con.x.id, " == ", con.v, ", active = ", con.active)
    println(io, "   ", con.x)
end

function Base.show(io::IO, con::EqualConstant)
    print(io, typeof(con), ": ", con.x.id, " == ", con.v)
end

"""
    Equal(x::SeaPearl.AbstractIntVar, y::SeaPearl.AbstractIntVar)

Equality constraint between two variables, stating that `x == y`.
"""
struct Equal <: EqualConstraint
    x       ::SeaPearl.AbstractIntVar
    y       ::SeaPearl.AbstractIntVar
    active  ::StateObject{Bool}

    function Equal(x::SeaPearl.AbstractIntVar, y::SeaPearl.AbstractIntVar, trailer::Trailer)
        constraint = new(x, y, StateObject(true, trailer))
        addOnDomainChange!(x, constraint)
        addOnDomainChange!(y, constraint)
        return constraint
    end
end

"""
    propagate!(constraint::Equal, toPropagate::Set{Constraint}, prunedDomains::CPModification)

`Equal` propagation function.
"""
function propagate!(constraint::Equal, toPropagate::Set{Constraint}, prunedDomains::CPModification)
    if !constraint.active.value
        return true
    end
    xFormerLength = length(constraint.x.domain)
    yFormerLength = length(constraint.y.domain)

    prunedX = pruneEqual!(constraint.x, constraint.y)
    prunedY = pruneEqual!(constraint.y, constraint.x)

    if !isempty(prunedX)
        triggerDomainChange!(toPropagate, constraint.x)
        addToPrunedDomains!(prunedDomains, constraint.x, prunedX)
    end
    if !isempty(prunedY)
        triggerDomainChange!(toPropagate, constraint.y)
        addToPrunedDomains!(prunedDomains, constraint.y, prunedY)
    end

    if constraint in toPropagate
        pop!(toPropagate, constraint)
    end

    if length(constraint.x.domain) <= 1
        setValue!(constraint.active, false)
    end
    if isempty(constraint.x.domain) || isempty(constraint.y.domain)
        return false
    end
    return true
end

"""
    pruneEqual!(x::AbstractIntVar, y::AbstractIntVar)

Remove the values from the domain of `x` that are not in the domain of `y`.
"""
function pruneEqual!(x::AbstractIntVar, y::AbstractIntVar)
    toRemove = Int[]
    for val in x.domain
        if !(val in y.domain)
            push!(toRemove, val)
        end
    end

    for val in toRemove
        remove!(x.domain, val)
    end

    return toRemove
end

variablesArray(constraint::Equal) = [constraint.x, constraint.y]

function Base.show(io::IO, ::MIME"text/plain", con::Equal)
    println(io, typeof(con), ": ", con.x.id, " == ", con.y.id, ", active = ", con.active)
    println(io, "   ", con.x)
    print(io, "   ", con.y)
end

function Base.show(io::IO, con::Equal)
    print(io, typeof(con), ": ", con.x.id, " == ", con.y.id)
end


"""
    AllEqual(x::Array{<:AbstractIntVar}, trailer::SeaPearl.Trailer)

Equality constraint between array variables, stating that `x[1] == x[2] == ... == x[n]`.
"""
struct AllEqual <: EqualConstraint
    x       ::Array{<:AbstractIntVar}
    active  ::StateObject{Bool}
    function AllEqual(x::Array{<:AbstractIntVar}, trailer::Trailer)
        constraint = new(x, StateObject(true, trailer))
        for i in 1:length(x)
            addOnDomainChange!(x[i], constraint)
        end
        return constraint
    end
end

"""
    propagate!(constraint::AllEqual, toPropagate::Set{Constraint}, prunedDomains::CPModification)

`AllEqual` propagation function.
"""
function propagate!(constraint::AllEqual, toPropagate::Set{Constraint}, prunedDomains::CPModification)
    if !constraint.active.value
        return true
    end

    prunedX = pruneAllEqual!(constraint.x)

    for i in 1:length(constraint.x)
        if !isempty(prunedX[i])
            triggerDomainChange!(toPropagate, constraint.x[i])
            addToPrunedDomains!(prunedDomains, constraint.x[i], prunedX[i])
        end
    end

    if constraint in toPropagate
        pop!(toPropagate, constraint)
    end

    if length(constraint.x[1].domain) <= 1
        setValue!(constraint.active, false)
    end
    
    if isempty(constraint.x[1].domain)
        return false
    end
    return true
end

function pruneAllEqual!(x::Array{<:AbstractIntVar})
    valuecounts = Dict{Int64,Int64}()
    n = length(x)
    for i in 1:n
        for val in x[i].domain
            if haskey(valuecounts, val)
                valuecounts[val] += 1
            else
                valuecounts[val] = 1
            end
        end
    end
    toRemove = Dict{Int, Array{Int}}()
    for i in 1:n
        toRemove[i] = Int[]
        for val in x[i].domain
            if valuecounts[val] != n
                push!(toRemove[i], val)
            end
        end
        for val in toRemove[i]
            remove!(x[i].domain, val)
        end
    end
    return toRemove
end


variablesArray(constraint::AllEqual) = constraint.x

function Base.show(io::IO, ::MIME"text/plain", con::AllEqual)
    print(io, string(typeof(con)), ": ", join([var.id for var in con.x], " == "), ", active = ", con.active)
    for var in con.x
        print(io, "\n   ", var)
    end
end

function Base.show(io::IO, con::AllEqual)
    print(io, string(typeof(con)), ": ", join([var.id for var in con.x], " == "))
end

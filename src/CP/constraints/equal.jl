abstract type EqualConstraint <: Constraint end

"""
    EqualConstant(x::CPRL.AbstractIntVar, v::Int)

Equality constraint, putting a constant value `v` for the variable `x` i.e. `x == v`
"""
struct EqualConstant <: EqualConstraint
    x       ::CPRL.AbstractIntVar
    v       ::Int
    active  ::StateObject{Bool}
    function EqualConstant(x::CPRL.AbstractIntVar, v::Int, trailer)
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
    # Stop propagation if constraint not active
    if !constraint.active.value
        return true
    end

    # Reduce the domain to a singleton if possible
    if constraint.v in constraint.x.domain
        removed = assign!(constraint.x.domain, constraint.v)
        setValue!(constraint.active, false)
        triggerDomainChange!(toPropagate, constraint.x)
        addToPrunedDomains!(prunedDomains, constraint.x, removed)
        return true
    end

    # Reduce the domain to an empty set if value not in domain
    removed = removeAll!(constraint.x.domain)
    setValue!(constraint.active, false)
    triggerDomainChange!(toPropagate, constraint.x)
    addToPrunedDomains!(prunedDomains, constraint.x, removed)
    return false
end

"""
    Equal(x::CPRL.AbstractIntVar, y::CPRL.AbstractIntVar)

Equality constraint between two variables, stating that `x == y`.
"""
struct Equal <: EqualConstraint
    x       ::CPRL.AbstractIntVar
    y       ::CPRL.AbstractIntVar
    active  ::StateObject{Bool}

    function Equal(x::CPRL.AbstractIntVar, y::CPRL.AbstractIntVar, trailer::Trailer)
        constraint = new(x, y, StateObject(true, trailer))
        addOnDomainChange!(x, constraint)
        addOnDomainChange!(y, constraint)
        return constraint
    end
end

function Base.show(io::IO, constraint::Equal)
    write(io, "Equal constraint:\n")
    show(io, constraint.x)
    
    show(io, constraint.y)
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
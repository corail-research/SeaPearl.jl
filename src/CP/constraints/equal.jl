abstract type EqualConstraint <: Constraint end

"""
    EqualConstant(x::CPRL.IntVar, v::Int)

Equality constraint, putting a constant value `v` for the variable `x` i.e. `x == v`
"""
mutable struct EqualConstant <: EqualConstraint
    x       ::CPRL.IntVar
    v       ::Int
    active  ::Bool
    function EqualConstant(x::CPRL.IntVar, v::Int)
        constraint = new(x, v, true)
        push!(x.onDomainChange, constraint)
        return constraint
    end
end

"""
    propagate!(constraint::EqualConstant, toPropagate::Set{Constraint}, prunedDomains::CPModification)

`EqualConstant` propagation function. Basically set the `x` domain to the constant value.
"""
function propagate!(constraint::EqualConstant, toPropagate::Set{Constraint}, prunedDomains::CPModification)
    # Stop propagation if constraint not active
    if !constraint.active
        return true
    end

    # Reduce the domain to a singleton if possible
    if constraint.v in constraint.x.domain
        removed = assign!(constraint.x.domain, constraint.v)
        constraint.active = false
        union!(toPropagate, constraint.x.onDomainChange)
        addToPrunedDomains!(prunedDomains, constraint.x, removed)
        return true
    end

    # Reduce the domain to an empty set if value not in domain
    removed = removeAll!(constraint.x.domain)
    constraint.active = false
    addToPrunedDomains!(prunedDomains, constraint.x, removed)
    return false
end

"""
    Equal(x::CPRL.IntVar, y::CPRL.IntVar)

Equality constraint between two variables, stating that `x == y`.
"""
mutable struct Equal <: EqualConstraint
    x       ::CPRL.IntVar
    y       ::CPRL.IntVar
    active  ::Bool

    function Equal(x::CPRL.IntVar, y::CPRL.IntVar)
        constraint = new(x, y, true)
        push!(x.onDomainChange, constraint)
        push!(y.onDomainChange, constraint)
        return constraint
    end
end

function Base.show(io::IO, constraint::Equal)
    println("Equal constraint:")
    println(constraint.x)
    
    println(constraint.y)
end

"""
    propagate!(constraint::Equal, toPropagate::Set{Constraint}, prunedDomains::CPModification)

`Equal` propagation function.
"""
function propagate!(constraint::Equal, toPropagate::Set{Constraint}, prunedDomains::CPModification)
    if !constraint.active
        return true
    end
    xFormerLength = length(constraint.x.domain)
    yFormerLength = length(constraint.y.domain)

    prunedX = pruneEqual!(constraint.x, constraint.y)
    prunedY = pruneEqual!(constraint.y, constraint.x)

    if !isempty(prunedX)
        union!(toPropagate, constraint.x.onDomainChange)
        addToPrunedDomains!(prunedDomains, constraint.x, prunedX)
    end
    if !isempty(prunedY)
        union!(toPropagate, constraint.y.onDomainChange)
        addToPrunedDomains!(prunedDomains, constraint.y, prunedY)
    end

    if constraint in toPropagate
        pop!(toPropagate, constraint)
    end

    if length(constraint.x.domain) <= 1
        constraint.active = false
    end
    if isempty(constraint.x.domain) || isempty(constraint.y.domain)
        return false
    end
    return true
end

"""
    pruneEqual!(x::IntVar, y::IntVar)

Remove the values from the domain of `x` that are not in the domain of `y`.
"""
function pruneEqual!(x::IntVar, y::IntVar)
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
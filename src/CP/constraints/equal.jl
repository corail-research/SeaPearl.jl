abstract type EqualConstraint <: Constraint end

"""
    EqualConstant(x::CPRL.IntVar, v::Int)

Equality constraint, putting a constant value `v` for the variable `x`.
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
    propagate!(constraint::EqualConstant, toPropagate::Set{Constraint})

`EqualConstant` propagation function. Basically set the `x` domain to the constant value.
"""
function propagate!(constraint::EqualConstant, toPropagate::Set{Constraint})
    # Stop propagation if constraint not active
    if !constraint.active
        return
    end

    # Reduce the domain to a singleton if possible
    if constraint.v in constraint.x.domain
        assign!(constraint.x.domain, constraint.v)
        constraint.active = false
        union!(toPropagate, constraint.x.onDomainChange)
        return
    end

    # Reduce the domain to an empty set if value not in domain
    removeAll!(constraint.x.domain)
    constraint.active = false
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

"""
    propagate!(constraint::Equal, toPropagate::Set{Constraint})

`Equal` propagation function.
"""
function propagate!(constraint::Equal, toPropagate::Set{Constraint})
    if !constraint.active
        return
    end
    xFormerLength = length(constraint.x.domain)
    yFormerLength = length(constraint.y.domain)

    pruneEqual!(constraint.x, constraint.y)
    pruneEqual!(constraint.y, constraint.x)

    if xFormerLength > length(constraint.x.domain)
        union!(toPropagate, constraint.x.onDomainChange)
    end
    if yFormerLength > length(constraint.y.domain)
        union!(toPropagate, constraint.y.onDomainChange)
    end

    pop!(toPropagate, constraint)

    if length(constraint.x.domain) <= 1
        constraint.active = false
    end
    return
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

    return x
end
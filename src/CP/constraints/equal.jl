abstract type EqualConstraint <: Constraint end

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
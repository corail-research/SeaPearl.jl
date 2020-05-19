

include("equal.jl")
include("notequal.jl")
include("lessorequal.jl")
include("greaterorequal.jl")

"""
    addOnDomainChange!(x::AbstractIntVar, constraint::Constraint)

Make sure `constraint` will be propagated if `x`'s domain changes.
"""
addOnDomainChange!(x::IntVar, constraint::Constraint) = push!(x.onDomainChange, constraint)
addOnDomainChange!(x::IntVarView, constraint::Constraint) = addOnDomainChange!(x.x, constraint)

"""
    addToPropagate!(toPropagate::Set{Constraint}, constraints::Array{Constraint})

Add the constraints to `toPropagate` only if they are active.
"""
function addToPropagate!(toPropagate::Set{Constraint}, constraints::Array{Constraint})
    for constraint in constraints
        if constraint.active.value
            push!(toPropagate, constraint)
        end
    end
end

"""
    triggerDomainChange!(toPropagate::Set{Constraint}, x::AbstractIntVar)

Add the constraints that have to be propagated when the domain of `x` changes to `toPropagate`.
"""
triggerDomainChange!(toPropagate::Set{Constraint}, x::IntVar) = addToPropagate!(toPropagate, x.onDomainChange)
triggerDomainChange!(toPropagate::Set{Constraint}, x::IntVarView) = triggerDomainChange!(toPropagate, x.x)

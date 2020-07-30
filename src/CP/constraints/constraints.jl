
include("equal.jl")
include("notequal.jl")
include("lessorequal.jl")
include("greaterorequal.jl")
include("interval.jl")
include("sumtozero.jl")
include("sumlessthan.jl")
include("sumgreaterthan.jl")
include("islessorequal.jl")

"""
    addOnDomainChange!(x::AbstractIntVar, constraint::Constraint)

Make sure `constraint` will be propagated if `x`'s domain changes. 
"""
function addOnDomainChange!(x::Union{IntVar, BoolVar, IntSetVar}, constraint::Constraint)
    if !(constraint in x.onDomainChange)
        push!(x.onDomainChange, constraint)
    end
end

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
triggerDomainChange!(toPropagate::Set{Constraint}, x::Union{AbstractIntVar, BoolVar, IntSetVar}) = addToPropagate!(toPropagate, getOnDomainChange(x))
getOnDomainChange(x::Union{IntVar, BoolVar}) = x.onDomainChange
getOnDomainChange(x::IntVarView) = getOnDomainChange(x.x)

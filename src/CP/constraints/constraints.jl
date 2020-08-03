
include("equal.jl")
include("notequal.jl")
include("lessorequal.jl")
include("greaterorequal.jl")
include("interval.jl")
include("sumtozero.jl")
include("sumlessthan.jl")
include("sumgreaterthan.jl")
include("islessorequal.jl")
include("inset.jl")
include("reifiedinset.jl")
include("binaryor.jl")
include("isbinaryor.jl")
include("setdiffsingleton.jl")
include("element2d.jl")
include("binarymaximum.jl")
include("setequalconstant.jl")

"""
    addOnDomainChange!(x::AbstractIntVar, constraint::Constraint)

Make sure `constraint` will be propagated if `x`'s domain changes. 
"""
function addOnDomainChange!(x::Union{IntVar, BoolVar, IntSetVar}, constraint::Constraint)
    if !(constraint in x.onDomainChange)
        push!(x.onDomainChange, constraint)
    end
end

addOnDomainChange!(x::Union{IntVarView, BoolVarView}, constraint::Constraint) = addOnDomainChange!(x.x, constraint)

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
triggerDomainChange!(toPropagate::Set{Constraint}, x::Union{AbstractIntVar, AbstractBoolVar, IntSetVar}) = addToPropagate!(toPropagate, getOnDomainChange(x))
getOnDomainChange(x::Union{IntVar, BoolVar, IntSetVar}) = x.onDomainChange
getOnDomainChange(x::Union{IntVarView, BoolVarView}) = getOnDomainChange(x.x)

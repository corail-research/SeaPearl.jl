include("datasstructures/rsparsebitset.jl")
include("absolute.jl")
include("disjunctive.jl")
include("datasstructures/timeline.jl")
include("alldifferent.jl")
include("compacttable.jl")
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
include("binaryxor.jl")
include("isbinaryxor.jl")
include("setdiffsingleton.jl")
include("element2d.jl")
include("element1d.jl")
include("binarymaximum.jl")
include("setequalconstant.jl")
include("isbinaryand.jl")
include("binaryimplication.jl")
include("binaryequivalence.jl")
include("maximum.jl")

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
function addToPropagate!(toPropagate::Set{<:Constraint}, constraints::Array{<:Constraint})
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
function triggerDomainChange!(toPropagate::Set{<:Constraint}, x::Union{AbstractIntVar, AbstractBoolVar, IntSetVar})
    addToPropagate!(toPropagate, getOnDomainChange(x))
    x.is_impacted = true
end

getOnDomainChange(x::Union{IntVar, BoolVar, IntSetVar}) = x.onDomainChange
getOnDomainChange(x::Union{IntVarView, BoolVarView}) = getOnDomainChange(x.x)

variablesArray(constraint::Constraint) = throw(ErrorException("missing function variablesArray(::$(typeof(constraint)))."))


struct ViewConstraint <: Constraint
    parent  ::Union{SeaPearl.AbstractIntVar, SeaPearl.AbstractBoolVar}
    child   ::Union{SeaPearl.IntVarView, SeaPearl.BoolVarView}
end

variablesArray(constraint::ViewConstraint) = [constraint.parent, constraint.child]
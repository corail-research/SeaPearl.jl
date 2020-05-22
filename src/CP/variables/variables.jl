include("IntDomain.jl")
include("IntVar.jl")

abstract type IntVarView <: AbstractIntVar end
abstract type IntDomainView <: AbstractIntDomain end

include("IntVarView.jl")
"""
    abstract type AbstractIntVar end

Abstract type for integer variables.
"""
abstract type AbstractIntVar end

"""
    function id(x::AbstractIntVar)

Return the `string` identifier of `x`. Every variable must be assigned a unique identifier upon creation, that
will be used as a key to identify the variable in the `CPModel` object.
"""
id(x::AbstractIntVar) = x.id

include("IntDomain.jl")
include("IntVar.jl")

abstract type IntVarView <: AbstractIntVar end
abstract type IntDomainView <: AbstractIntDomain end

include("IntVarView.jl")
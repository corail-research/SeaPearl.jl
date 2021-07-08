abstract type AbstractVar end
abstract type AbstractDomain end

abstract type AbstractSetVar <: AbstractVar end

"""
    abstract type AbstractIntVar end

Abstract type for integer variables.
"""
abstract type AbstractIntVar <: AbstractVar end

"""
    abstract type AbstractBoolVar <: AbstractVar end

Abstract type for all boolean variables.
"""
abstract type AbstractBoolVar <: AbstractVar end

"""
    function id(x::AbstractVar)

Return the `string` identifier of `x`. Every variable must be assigned a unique identifier upon creation, that
will be used as a key to identify the variable in the `CPModel` object.
"""
id(x::AbstractVar) = x.id
parentId(x::AbstractVar) = rootVariable(x).id

include("IntDomain.jl")
include("IntVar.jl")

include("BoolDomain.jl")
include("BoolVar.jl")

abstract type IntVarView <: AbstractIntVar end
abstract type IntDomainView <: AbstractIntDomain end

include("IntVarView.jl")

abstract type BoolVarView <: AbstractBoolVar end
abstract type BoolDomainView <: AbstractBoolDomain end

include("BoolVarView.jl")

include("IntSetDomain.jl")
include("IntSetVar.jl")
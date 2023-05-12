"""
    struct BoolVar <: AbstractVar

A "simple" boolean variable.
The constraints that affect this variable are stored in the `onDomainChange` array.
"""
mutable struct BoolVar <: AbstractBoolVar
    onDomainChange      ::Array{Constraint}
    domain              ::SeaPearl.BoolDomain
    id                  ::String
    children            ::Set{AbstractBoolVar}
    is_impacted         ::Bool
end

"""
    function BoolVar(id::String, trailer::Trailer)

Create a `BoolVar` with a domain being equal to [false, true] with the `id` string identifier
and that will be backtracked by `trailer`.
"""
function BoolVar(id::String, trailer::Trailer)
    dom = BoolDomain(trailer)

    return BoolVar(Constraint[], dom, id, Set{AbstractBoolVar}(), false)
end

function Base.show(io::IO, var::BoolVar)
    print(io, var.id, " = ", var.domain)
end

function Base.show(io::IO, ::MIME"text/plain", var::BoolVar)
    print(io, typeof(var), ": ", var.id, " = ", var.domain)
end

"""
    isbound(x::AbstractBoolVar)

Check whether x has an assigned value.
"""
isbound(x::AbstractBoolVar) = length(x.domain) == 1

"""
    assign!(x::BoolVar, value::Bool)

Remove everything from the domain of `x` but `value`.
"""
assign!(x::BoolVar, value::Bool) = assign!(x.domain, value)

"""
    assignedValue(x::BoolVar)

Return the assigned value of `x`. Throw an error if `x` is not bound.
"""
function assignedValue(x::BoolVar)
    @assert isbound(x)

    return convert(Bool, minimum(x.domain.inner))
end

"""
    rootVariable(x::BoolVar)

Return the "true" variable behind `x`. For a `BoolVar`, it simply returns `x`.
"""
rootVariable(x::BoolVar) = x

"""
    struct IntVar <: AbstractIntVar

A "simple" integer variable, whose domain can be any set of integers.
The constraints that affect this variable are stored in the `onDomainChange` array.
"""
struct IntVar <: AbstractIntVar
    onDomainChange      ::Array{Constraint}
    domain              ::SeaPearl.IntDomain
    id                  ::String
    children            ::Set{AbstractIntVar}
end

"""
    function IntVar(min::Int, max::Int, id::String, trailer::Trailer)

Create an `IntVar` with a domain being the integer range [`min`, `max`] with the `id` string identifier
and that will be backtracked by `trailer`.
"""
function IntVar(min::Int, max::Int, id::String, trailer::Trailer)
    offset = min - 1
    dom = IntDomain(trailer, max - min + 1, offset)

    return IntVar(Constraint[], dom, id, Set{AbstractIntVar}())
end

function Base.show(io::IO, var::IntVar)
    print(io, var.id, " = ", var.domain)
end

function Base.show(io::IO, ::MIME"text/plain", var::IntVar)
    print(io, typeof(var), ": ", var.id, " = ", var.domain)
end

"""
    isbound(x::AbstractIntVar)

Check whether x has an assigned value.
"""
isbound(x::AbstractIntVar) = length(x.domain) == 1

"""
    assign!(x::AbstractIntVar, value::Int)

Remove everything from the domain of `x` but `value`.
"""
assign!(x::AbstractIntVar, value::Int) = assign!(x.domain, value)

"""
    assignedValue(x::AbstractIntVar)

Return the assigned value of `x`. Throw an error if `x` is not bound.
"""
function assignedValue(x::AbstractIntVar)
    @assert isbound(x)
    return minimum(x.domain)
end

"""
    rootVariable(x::IntVar)

Return the "true" variable behind `x`. For a `IntVar`, it simply returns `x`.
"""
rootVariable(x::IntVar) = x

"""
Overloads the * operator to easily generate a multiple of a variable: y = ax
"""
Base.:*(a::Int, x::IntVar) = IntVarViewMul(x, a, string(a," * ",x.id))

"""
    -(x::IntVar)

Simple way to generate the opposite of a variable (y = -x).
Return a `IntVarViewOpposite` of `x`.
"""
Base.:-(x::IntVar) = IntVarViewOpposite(x, string("-(", x.id, ")"))


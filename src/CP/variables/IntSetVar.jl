"""
    struct IntSetVar <: AbstractIntSetVar

A set variable, that can be a subset of an integer interval.
"""
struct IntSetVar <: AbstractVar
    onDomainChange      ::Array{Constraint}
    domain              ::IntSetDomain
    id                  ::String
end

"""
    function IntSetVar(min::Int, max::Int, id::String, trailer::Trailer)

Create an `IntSetVar` with a domain being the subsets of the integer range [`min`, `max`] with the `id` string identifier
and that will be backtracked by `trailer`.
"""
function IntSetVar(min::Int, max::Int, id::String, trailer::Trailer)
    offset = min - 1

    dom = IntSetDomain(trailer, min, max)

    return IntSetVar(Constraint[], dom, id)
end

# TODO define SetModification

"""
    isbound(x::IntSetVar)

Check whether x has an assigned value (meaning its domain only contains one subset)
"""
isbound(x::IntSetVar) = x.domain.requiring_index.value - 1 == x.domain.excluding_index.value

"""
    assignedValue(x::IntSetVar)

Return the assigned value of `x`, i.e. the only subset it contains. Throw an error if `x` is not bound.
"""
function assignedValue(x::IntSetVar)
    @assert isbound(x)

    return required_values(x.domain)
end

function Base.show(io::IO, var::IntSetVar)
    print(io, var.id, ": ", var.domain)
end

function Base.show(io::IO, ::MIME"text/plain", var::IntSetVar)
    println(io, typeof(var), ": ", var.id)
    print(io, "   ", var.domain)
end

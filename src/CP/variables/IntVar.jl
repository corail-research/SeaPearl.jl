"""
    struct IntVar <: AbstractIntVar

A "simple" integer variable, whose domain can be any set of integers.
The constraints that affect this variable are stored in the `onDomainChange` array.
"""
struct IntVar <: AbstractIntVar
    onDomainChange      ::Array{Constraint}
    domain              ::CPRL.IntDomain
    id                  ::String
end

"""
    function IntVar(min::Int, max::Int, id::String, trailer::Trailer)

Create an `IntVar` with a domain being the integer range [`min`, `max`] with the `id` string identifier
and that will be backtracked by `trailer`.
"""
function IntVar(min::Int, max::Int, id::String, trailer::Trailer)
    offset = min - 1

    dom = IntDomain(trailer, max - min + 1, offset)

    return IntVar(Constraint[], dom, id)
end

function Base.show(io::IO, var::IntVar)
    write(io, var.id, "=")
    show(io, var.domain)
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

Return the assigened value of `x`. Throw an error if `x` is not bound.
"""
function assignedValue(x::AbstractIntVar)
    @assert isbound(x)

    return minimum(x.domain)
end

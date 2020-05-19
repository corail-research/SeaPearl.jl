abstract type AbstractIntVar end

struct IntVar <: AbstractIntVar
    onDomainChange      ::Array{Constraint}
    domain              ::CPRL.IntDomain
    id                  ::String

    function IntVar(min::Int, max::Int, id::String, trailer::Trailer)
        offset = min - 1

        dom = IntDomain(trailer, max - min + 1, offset)

        return new(Constraint[], dom, id)
    end
end

function Base.show(io::IO, var::IntVar)
    write(io, var.id, "=")
    show(io, var.domain)
end

"""
    isbound(x::IntVar)

Check whether x has an assigned value.
"""
isbound(x::AbstractIntVar) = length(x.domain) == 1



"""
    assign!(x::IntVar, value::Int)

Remove everything from the domain of `x` but `value`.
"""
assign!(x::AbstractIntVar, value::Int) = assign!(x.domain, value)

"""
    assignedValue(x::IntVar)

Return the assigened value of `x`. Throw an error if `x` is not bound.
"""
function assignedValue(x::IntVar)
    @assert isbound(x)

    return x.domain.values[1] + x.domain.offset
end

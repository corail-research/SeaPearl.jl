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

"""
    SetModification(; excluded::Array{Int}, required::Array{Int})

Stock the two types of modification of a IntSetVar.
"""
struct SetModification
    excluded::Array{Int}
    required::Array{Int}
    
    function SetModification(;excluded::Union{Nothing,Array{Int}}=nothing, required::Union{Nothing,Array{Int}}=nothing)
        if isnothing(excluded)
            excluded = Int[]
        end
        if isnothing(required)
            required = Int[]
        end
        return new(excluded, required)
    end
end

"""
    Base.length(set::SetModification)

a generic function length is needed for all modifications. 
"""
function Base.length(set::SetModification)
    return length(set.excluded) + length(set.required)
end

"""
    mergeSetModifications!(modif1, modif2)

Add the modifications in `modif2` at the end of `modif1`
"""
function mergeSetModifications!(modif1::SetModification, modif2::SetModification)
    append!(modif1.required, modif2.required)
    append!(modif1.excluded, modif2.excluded)
    return
end

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

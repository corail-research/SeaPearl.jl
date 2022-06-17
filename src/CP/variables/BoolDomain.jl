abstract type AbstractBoolDomain <: AbstractIntDomain end

"""
    struct BoolDomain <: AbstractDomain

Boolean domain, uses a IntDomain in it. (true is 1 and false is 0)
"""

struct BoolDomain <: AbstractBoolDomain
    inner::IntDomain

    function BoolDomain(trailer::Trailer)
        return new(IntDomain(trailer, 2, -1))
    end
end

"""
    reset_domain!(dom::BoolDomain)

Used in `reset_model!`. 
"""
reset_domain!(dom::BoolDomain) = reset_domain!(dom.inner)

function Base.show(io::IO, dom::BoolDomain)
    print(io, "[", join(dom, " "), "]")
end

function Base.show(io::IO, ::MIME"text/plain", dom::BoolDomain)
    print(io, typeof(dom), ": [", join(dom, " "), "]")
end

"""
    isempty(dom::BoolDomain)

Return `true` iff `dom` is an empty set. Done in constant time.
"""
Base.isempty(dom::BoolDomain) = Base.isempty(dom.inner)

"""
    length(dom::BoolDomain)

Return the size of `dom`. Done in constant time.
"""
Base.length(dom::SeaPearl.BoolDomain) = Base.length(dom.inner)

"""
    Base.in(value::Int, dom::BoolDomain)

Check if an integer is in the domain. Done in constant time.
"""
function Base.in(value::Bool, dom::BoolDomain)
    intValue = convert(Int, value)
    return Base.in(intValue, dom.inner)
end

"""
    remove!(dom::BoolDomain, value::Bool)

Remove `value` from `dom`. Done in constant time.
"""
function remove!(dom::BoolDomain, value::Bool)
    if !(value in dom)
        return Bool[]
    end
    
    intValue = convert(Int, value)

    remove!(dom.inner, intValue)
    return [value]
end

"""
    remove!(dom::BoolDomain, value::Int)

Remove `value` from `dom`. Done in constant time.
"""
remove!(dom::BoolDomain, value::Int) = convert.(Bool, remove!(dom.inner, value))

"""
    removeAll!(dom::BoolDomain)

Remove every value from `dom`. Return the removed values. Done in constant time.
"""
removeAll!(dom::BoolDomain) = convert.(Bool, removeAll!(dom.inner))

"""
    removeAbove!(dom::IntDomain, value::Int)

Remove every integer of `dom` that is *strictly* above `value`. Done in *linear* time.
"""
removeAbove!(dom::BoolDomain, value::Int) = convert.(Bool, removeAbove!(dom.inner, value))

"""
    removeBelow!(dom::IntDomain, value::Int)

Remove every integer of `dom` that is *strictly* below `value`. Return the pruned values.
Done in *linear* time.
"""
removeBelow!(dom::BoolDomain, value::Int) = convert.(Bool, removeBelow!(dom.inner, value))

"""
    assign!(dom::BoolDomain, value::Bool)

Remove everything from the domain but `value`. Return the removed values. Return the pruned values.
Done in *constant* time.
"""
function assign!(dom::BoolDomain, value::Bool)
    @assert value in dom

    return convert.(Bool, assign!(dom.inner, convert(Int, value)))
end

"""
    assign!(dom::BoolDomain, value::Int)

Remove everything from the domain but `value`. Return the removed values. Return the pruned values.
Done in *constant* time.
"""
assign!(dom::BoolDomain, value::Int) = convert.(Bool, assign!(dom.inner, convert(Int, value)))

"""
    Base.iterate(dom::BoolDomain, state=1)

Iterate over the domain in an efficient way. The order may not be consistent.
WARNING: Do **NOT** update the domain you are iterating on.
"""
function Base.iterate(dom::BoolDomain, state=1)
    returned = iterate(dom.inner, state)
    if isnothing(returned)
        return nothing
    end

    value, newState = returned
    return convert(Bool, value), newState
end

"""
    minimum(dom::BoolDomain)

Return the minimum value of `dom`.
Done in *constant* time.
"""
minimum(dom::BoolDomain) = minimum(dom.inner)

"""
    maximum(dom::BoolDomain)

Return the maximum value of `dom`.
Done in *constant* time.
"""
maximum(dom::BoolDomain) = maximum(dom.inner)
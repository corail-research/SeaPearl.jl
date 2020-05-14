struct IntDomain
    values          ::Array{Int}
    indexes         ::Array{Int}
    offset          ::Int
    initSize        ::Int
    size            ::CPRL.StateInt
    trailer         ::CPRL.Trailer

    """
        IntDomain(trailer::Trailer, n::Int, offset::Int)

    Create an integer domain going from `ofs + 1` to `ofs + n`.
    """
    function IntDomain(trailer::Trailer, n::Int, offset::Int)

        size = CPRL.StateInt(n, trailer)
        values = zeros(n)
        indexes = zeros(n)
        for i in 1:n
            values[i] = i
            indexes[i] = i
        end
        return new(values, indexes, offset, n, size, trailer)
    end
end

struct IntVar
    onDomainChange     ::Array{Constraint}
    domain             ::CPRL.IntDomain

    function IntVar(min::Int, max::Int, trailer::Trailer)
        offset = min - 1

        dom = IntDomain(trailer, max - min + 1, offset)

        return new(Constraint[], dom)
    end
end

"""
    isbound(x::IntVar)

Check whether x has an assigned value.
"""
isbound(x::IntVar) = length(x.domain) == 1

"""
    isempty(dom::IntDomain)

Return `true` iff `dom` is an empty set.
"""
Base.isempty(dom::CPRL.IntDomain) = dom.size.value == 0

"""
    length(dom::IntDomain)

Return the size of `dom`.
"""
Base.length(dom::CPRL.IntDomain) = dom.size.value

"""
    Base.in(value::Int, dom::IntDomain)

Check if an integer is in the domain.
"""
function Base.in(value::Int, dom::IntDomain)
    value -= dom.offset
    if value < 1 || value > dom.initSize
        return false
    end
    return dom.indexes[value] <= length(dom)
end

"""
    remove!(dom::IntDomain, value::Int)

Remove `value` from `dom`.
"""
function remove!(dom::IntDomain, value::Int)
    if !(value in dom)
        return dom
    end

    value -= dom.offset

    exchangePositions!(dom, value, dom.size.value)
    setValue!(dom.size, dom.size.value - 1)

    return dom
end

"""
    removeAll!(dom::IntDomain)

Remove every value from `dom`
"""
function removeAll!(dom::IntDomain)
    setValue!(dom.size, 0)
    return dom
end

"""
    assign!(dom::IntDomain, value::Int)

Remove everything from the domain but `value`.
"""
function assign!(dom::IntDomain, value::Int)
    @assert value in dom

    value -= dom.offset

    exchangePositions!(dom, value, dom.values[1])

    setValue!(dom.size, 1)

    return dom
end

"""
    assign!(x::IntVar, value::Int)

Remove everything from the domain of `x` but `value`.
"""
assign!(x::IntVar, value::Int) = assign!(x.domain, value)

"""
    assignedValue(x::IntVar)

Return the assigened value of `x`. Throw an error if `x` is not bound.
"""
function assignedValue(x::IntVar)
    @assert isbound(x)

    return x.domain.values[1] + x.domain.offset
end

"""
    Base.iterate(dom::IntDomain, state=1)

Iterate over the domain in an efficient way. The order may not be consistent.
WARNING: Do *NOT* update the domain you are iterating on.
"""
function Base.iterate(dom::IntDomain, state=1)
    @assert state >= 1
    if state > dom.size.value
        return nothing
    end

    return dom.values[state] + dom.offset, state+1
end

"""
    exchangePositions!(dom::IntDomain, v1::Int, v2::Int)

Intended for internal use only, exchange the position of `v1` and `v2` in the array of the domain.
"""
function exchangePositions!(dom::IntDomain, v1::Int, v2::Int)
    @assert(v1 <= length(dom.values) && v2 <= length(dom.values))

    i1, i2 = dom.indexes[v1], dom.indexes[v2]

    dom.values[i1] = v2
    dom.values[i2] = v1
    dom.indexes[v1] = i2
    dom.indexes[v2] = i1

    return dom
end

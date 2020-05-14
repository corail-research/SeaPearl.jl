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
end

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
    return dom.indexes[value] < length(dom)
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

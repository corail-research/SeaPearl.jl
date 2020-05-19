struct IntDomainViewMul <: IntDomainView
    orig            ::IntDomain
    a               ::Int
end


struct IntVarViewMul <: IntVarView
    x               ::IntVar
    a               ::Int
    domain          ::IntDomainViewMul
    id              ::String

    """
        IntVarViewMul(x::IntVar, a::Int)

    Create a *fake* variable `y`, such that `y == a*x`. This variable behaves like an usual one.
    """
    function IntVarViewMul(x::IntVar, a::Int, id::String)
        @assert a > 0
        dom = IntDomainViewMul(x.domain, a)
        return new(x, a, dom, id)
    end
end

"""
    assignedValue(x::IntVarViewMul)

Return the assigened value of `x`. Throw an error if `x` is not bound.
"""
assignedValue(x::IntVarViewMul) = x.a * assignedValue(x.x)

"""
    isempty(dom::IntDomainViewMul)

Return `true` iff `dom` is an empty set.
"""
Base.isempty(dom::IntDomainViewMul) = isempty(dom.orig)

"""
    length(dom::IntDomainViewMul)

Return the size of `dom`.
"""
Base.length(dom::IntDomainViewMul) = length(dom.orig)

"""
    Base.in(value::Int, dom::IntDomain)

Check if an integer is in the domain.
"""
function Base.in(value::Int, dom::IntDomainViewMul)
    if value % dom.a != 0
        return false
    end
    return (value ÷ dom.a) in dom.orig
end

"""
    remove!(dom::IntDomainViewMul, value::Int)

Remove `value` from `dom`.
"""
function remove!(dom::IntDomainViewMul, value::Int)
    if value % dom.a != 0
        return Int[]
    end

    return remove!(dom.orig, value ÷ dom.a)
end

"""
    removeAll!(dom::IntDomainViewMul)

Remove every value from `dom`. Return the removed values.
"""
removeAll!(dom::IntDomainViewMul) = dom.a * removeAll!(dom.orig)


"""
    minimum(dom::IntDomainViewMul)

Return the minimum value of `dom`.
"""
minimum(dom::IntDomainViewMul) = dom.a * minimum(dom.orig)

"""
    maximum(dom::IntDomainViewMul)

Return the maximum value of `dom`.
"""
maximum(dom::IntDomainViewMul) = dom.a * maximum(dom.orig)


"""
    removeAbove!(dom::IntDomainViewMul, value::Int)

Remove every integer of `dom` that is *strictly* above `value`.
"""
removeAbove!(dom::IntDomainViewMul, value::Int) = dom.a * removeAbove!(dom.orig, convert(Int, floor(value / dom.a)))

"""
    removeBelow!(dom::IntDomainViewMul, value::Int)

Remove every integer of `dom` that is *strictly* below `value`. Return the pruned values.
"""
removeBelow!(dom::IntDomainViewMul, value::Int) = dom.a * removeBelow!(dom.orig, convert(Int, ceil(value / dom.a)))


"""
    assign!(dom::IntDomain, value::Int)

Remove everything from the domain but `value`. Return the removed values. Return the pruned values.
"""
function assign!(dom::IntDomainViewMul, value::Int)
    @assert value % dom.a == 0
    return dom.a * assign!(dom.orig, value ÷ dom.a)
end


"""
    Base.iterate(dom::IntDomainViewMul, state=1)

Iterate over the domain in an efficient way. The order may not be consistent.
WARNING: Do **NOT** update the domain you are iterating on.
"""
function Base.iterate(dom::IntDomainViewMul, state=1)
    returned = iterate(dom.orig, state)
    if isnothing(returned)
        return nothing
    end

    value, newState = returned
    return value * dom.a, newState
end

"""
    updateMaxFromRemovedVal!(dom::IntDomainViewMul, v::Int)

Knowing that `v` just got removed from `dom`, update `dom`'s maximum value.
"""
function updateMaxFromRemovedVal!(dom::IntDomainViewMul, v::Int)
    if maximum(dom) == v
        updateMaxFromRemovedVal!(dom.orig, v ÷ dom.a)
    end
end

"""
    updateMinFromRemovedVal!(dom::IntDomainViewMul, v::Int)

Knowing that `v` just got removed from `dom`, update `dom`'s minimum value.
"""
function updateMinFromRemovedVal!(dom::IntDomainViewMul, v::Int)
    if minimum(dom) == v
        updateMinFromRemovedVal!(dom.orig, v ÷ dom.a)
    end
end

"""
    updateBoundsFromRemovedVal!(dom::IntDomainViewMul, v::Int)

Knowing that `v` just got removed from `dom`, update `dom`'s minimum and maximum value.
"""
function updateBoundsFromRemovedVal!(dom::IntDomainViewMul, v::Int)
    updateMaxFromRemovedVal!(dom, v)
    updateMinFromRemovedVal!(dom, v)
end
struct IntDomainViewOpposite <: IntDomainView
    orig            ::IntDomain
end

struct IntVarViewOpposite <: IntVarView
    x               ::IntVar
    domain          ::IntDomainViewOpposite
    id              ::String

    function IntVarViewOpposite(x::IntVar, id::String)
        dom = IntDomainViewOpposite(x.domain)
        return new(x, dom, id)
    end
end

"""
    Base.in(value::Int, dom::IntDomainViewOpposite)

Check if an integer is in the domain.
"""
Base.in(value::Int, dom::IntDomainViewOpposite) = -value in dom.orig

"""
    remove!(dom::IntDomainViewOpposite, value::Int)

Remove `value` from `dom`.
"""
remove!(dom::IntDomainViewOpposite, value::Int) = -1 * remove!(dom.orig, -value)

"""
    removeAll!(dom::IntDomainViewOpposite)

Remove every value from `dom`. Return the removed values.
"""
removeAll!(dom::IntDomainViewOpposite) = -1 * removeAll!(dom.orig)


"""
    minimum(dom::IntDomainViewOpposite)

Return the minimum value of `dom`.
"""
minimum(dom::IntDomainViewOpposite) = -1 * maximum(dom.orig)

"""
    maximum(dom::IntDomainViewOpposite)

Return the maximum value of `dom`.
"""
maximum(dom::IntDomainViewOpposite) = -1 * minimum(dom.orig)


"""
    removeAbove!(dom::IntDomainViewOpposite, value::Int)

Remove every integer of `dom` that is *strictly* above `value`.
"""
removeAbove!(dom::IntDomainViewOpposite, value::Int) = -1 * removeBelow!(dom.orig, -value)

"""
    removeBelow!(dom::IntDomainViewOpposite, value::Int)

Remove every integer of `dom` that is *strictly* below `value`. Return the pruned values.
"""
removeBelow!(dom::IntDomainViewOpposite, value::Int) = -1 * removeAbove!(dom.orig, -value)


"""
    assign!(dom::IntDomainViewOpposite, value::Int)

Remove everything from the domain but `value`. Return the removed values. Return the pruned values.
"""
assign!(dom::IntDomainViewOpposite, value::Int) = -1 * assign!(dom.orig, -value)

"""
    Base.iterate(dom::IntDomainViewOpposite, state=1)

Iterate over the domain in an efficient way. The order may not be consistent.
WARNING: Do **NOT** update the domain you are iterating on.
"""
function Base.iterate(dom::IntDomainViewOpposite, state=1)
    returned = iterate(dom.orig, state)
    if isnothing(returned)
        return nothing
    end

    value, newState = returned
    return -value, newState
end

"""
    updateMaxFromRemovedVal!(dom::IntDomainViewOpposite, v::Int)

Knowing that `v` just got removed from `dom`, update `dom`'s maximum value.
"""
function updateMaxFromRemovedVal!(dom::IntDomainViewOpposite, v::Int)
    if maximum(dom) == v
        updateMinFromRemovedVal!(dom.orig, -v)
    end
end

"""
    updateMinFromRemovedVal!(dom::IntDomainViewOpposite, v::Int)

Knowing that `v` just got removed from `dom`, update `dom`'s minimum value.
"""
function updateMinFromRemovedVal!(dom::IntDomainViewOpposite, v::Int)
    if minimum(dom) == v
        updateMaxFromRemovedVal!(dom.orig, -v)
    end
end

"""
    updateBoundsFromRemovedVal!(dom::IntDomainViewOpposite, v::Int)

Knowing that `v` just got removed from `dom`, update `dom`'s minimum and maximum value.
"""
function updateBoundsFromRemovedVal!(dom::IntDomainViewOpposite, v::Int)
    updateMaxFromRemovedVal!(dom, v)
    updateMinFromRemovedVal!(dom, v)
end
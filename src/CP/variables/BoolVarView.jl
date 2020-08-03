struct BoolDomainViewNot <: BoolDomainView
    orig            ::AbstractBoolDomain
end

struct BoolVarViewNot <: BoolVarView
    x               ::AbstractBoolVar
    domain          ::BoolDomainViewNot
    id              ::String

    """
        BoolVarViewNot(x::AbstractBoolVar, id::String)

    Create a *fake* variable `y`, such that `y = ¬x`. This variable behaves like an usual one.
    """
    function BoolVarViewNot(x::AbstractBoolVar, id::String)
        dom = BoolDomainViewNot(x.domain)
        return new(x, dom, id)
    end
end

assignedValue(x::BoolVarViewNot) = !assignedValue(x.x)

"""
    isempty(dom::BoolDomainView)

Return `true` iff `dom` is an empty set.
"""
Base.isempty(dom::BoolDomainView) = isempty(dom.orig)

reset_domain!(dom::BoolDomainView) = reset_domain!(dom.orig)

"""
    rootVariable(x::BoolVarView)

Return the "true" variable behind `x`.
"""
rootVariable(x::BoolVarView) = rootVariable(x.x)

"""
    length(dom::BoolDomainView)

Return the size of `dom`.
"""
Base.length(dom::BoolDomainView) = length(dom.orig)

"""
    Base.in(value::Bool, dom::BoolDomainViewNot)

Check if a boolean is in the domain.
"""
Base.in(value::Bool, dom::BoolDomainViewNot) = (!value) in dom.orig

"""
    remove!(dom::BoolDomainViewNot, value::Bool)

Remove `value` from `dom`.
"""
remove!(dom::BoolDomainViewNot, value::Bool) = map(x -> !x, remove!(dom.orig, !value))

"""
    removeAll!(dom::BoolDomainViewNot)

Remove every value from `dom`. Return the removed values.
"""
removeAll!(dom::BoolDomainViewNot) = map(x -> !x, removeAll!(dom.orig))


"""
    assign!(dom::BoolDomainViewNot, value::Bool)

Remove everything from the domain but `value`. Return the removed values. Return the pruned values.
"""
assign!(dom::BoolDomainViewNot, value::Bool) = map(x -> !x, assign!(dom.orig, !value))

"""
    Base.iterate(dom::BoolDomainViewNot, state=1)

Iterate over the domain in an efficient way. The order may not be consistent.
WARNING: Do **NOT** update the domain you are iterating on.
"""
function Base.iterate(dom::BoolDomainViewNot, state=1)
    returned = iterate(dom.orig, state)
    if isnothing(returned)
        return nothing
    end

    value, newState = returned
    return !value, newState
end

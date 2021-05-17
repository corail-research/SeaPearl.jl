struct IntSetDomain <: AbstractDomain
    values          ::Array{Int}
    indexes         ::Array{Int}
    min             ::Int
    max             ::Int
    requiring_index ::StateObject{Int}
    excluding_index ::StateObject{Int}
    trailer         ::Trailer
end

function IntSetDomain(trailer::Trailer, min::Int, max::Int)
    n = max - min + 1
    requiring_index = SeaPearl.StateObject{Int}(1, trailer)
    excluding_index = SeaPearl.StateObject{Int}(n, trailer)

    values = collect(1:n)
    indexes = collect(1:n)

    return IntSetDomain(values, indexes, min, max, requiring_index, excluding_index, trailer)
end

"""
    reset_domain!(dom::IntSetDomain)

Used in `reset_model!`. 
"""
function reset_domain!(dom::IntSetDomain)
    setValue!(dom.requiring_index, 1)
    setValue!(dom.excluding_index, dom.max - dom.min + 1)
    sort!(dom.values)
    sort!(dom.indexes)
    dom
end

function exclude!(dom::IntSetDomain, v::Int)
    @assert dom.min <= v <= dom.max

    if !is_possible(dom, v)
        return nothing
    end
    if is_required(dom, v)
        throw(ErrorException("You can't exclude $(v) as it is required in $(dom)"))
    end
    exchangePositions!(dom, v, dom.values[dom.excluding_index.value] + dom.min - 1)
    setValue!(dom.excluding_index, dom.excluding_index.value - 1)
end

function require!(dom::IntSetDomain, v::Int)
    @assert dom.min <= v <= dom.max

    if is_required(dom, v)
        return nothing
    end
    if !is_possible(dom, v)
        throw(ErrorException("You can't require $(v) as it is excluded from $(dom)"))
    end
    exchangePositions!(dom, v, dom.values[dom.requiring_index.value] + dom.min - 1)
    setValue!(dom.requiring_index, dom.requiring_index.value + 1)
end

"""
    function exclude_all!(dom::IntSetDomain)

Exclude all possible not yet required values from the set domain.
"""
function exclude_all!(dom::IntSetDomain)
    setValue!(dom.excluding_index, dom.requiring_index.value - 1)
end

"""
    function require_all!(dom::IntSetDomain)

Require all possible not yet excluded values from the set domain.
"""
function require_all!(dom::IntSetDomain)
    setValue!(dom.requiring_index, dom.excluding_index.value + 1)
end

"""
    function is_possible(dom::IntSetDomain, v::Int)
    
Return true if `v` is a possible value for `dom`.
"""
function is_possible(dom::IntSetDomain, v::Int)
    if dom.min > v || v > dom.max
        return false
    end
    return dom.indexes[v - dom.min + 1] <= dom.excluding_index.value
end

"""
    function is_possible(dom::IntSetDomain, v::Int)
    
Return true if `v` is a required value for `dom`.
"""
function is_required(dom::IntSetDomain, v::Int)
    if dom.min > v || v > dom.max
        return false
    end
    return dom.indexes[v - dom.min + 1] < dom.requiring_index.value
end

"""
    function required_values(dom::IntSetDomain)::Set{Int}

Return a set containing all the required values of `dom`.
"""
function required_values(dom::IntSetDomain)
    return Set{Int}(dom.values[1:(dom.requiring_index.value - 1)] .+ (dom.min - 1))
end

"""
    function possible_not_required_values(dom::IntSetDomain)::Set{Int}

Return a set containing the possible values, but not the required ones, for `dom`.
"""
function possible_not_required_values(dom::IntSetDomain)
    return Set{Int}(dom.values[dom.requiring_index.value:dom.excluding_index.value] .+ (dom.min - 1))
end

"""
    exchangePositions!(dom::IntDomain, v1::Int, v2::Int)

Intended for internal use only, exchange the position of `v1` and `v2` in the array of the domain.
"""
function exchangePositions!(dom::IntSetDomain, v1::Int, v2::Int)
    @assert dom.min <= v1 <= dom.max
    @assert dom.min <= v2 <= dom.max


    v1, v2 = v1 - dom.min + 1, v2 - dom.min + 1

    i1, i2 = dom.indexes[v1], dom.indexes[v2]

    dom.values[i1] = v2
    dom.values[i2] = v1
    dom.indexes[v1] = i2
    dom.indexes[v2] = i1

    return dom
end

function Base.show(io::IO, dom::IntSetDomain)
    print(io, "required_values = ", required_values(dom), "; possibles_values = ", possible_not_required_values(dom))
end

function Base.show(io::IO, ::MIME"text/plain", dom::IntSetDomain)
    println(io, typeof(dom), ", min = ", dom.min, ", max = ", dom.max)
    println(io, "   required_values = ", required_values(dom))
    print(io, "   possible_values = ", possible_not_required_values(dom))
end

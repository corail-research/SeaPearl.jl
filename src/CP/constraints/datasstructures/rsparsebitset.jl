"""
    RSparseBitSet{T}(size, trailer)

Create a Reversible Sparse BitSet with `size` elements.

This datastructure follows the implementation from Demeulenaere J. et al. 
(2016) Compact-Table: Efficiently Filtering Table Constraints with Reversible Sparse Bit-Sets. 
https://doi.org/10.1007/978-3-319-44953-1_14 .
"""
struct RSparseBitSet{T}
    words::Vector{StateObject{T}}
    index::Vector{Int}
    limit::StateObject{Int}
    mask::Vector{T}

    function RSparseBitSet{T}(size::Int, trailer) where T <: Unsigned
        n = sizeof(T) * 8
        p = Int(ceil(size/n))
        rest = size % n
        words = Vector{StateObject{T}}(undef, p)
        for i = 1:(p-1)
            words[i] = StateObject{T}(typemax(T), trailer)
        end
        if rest == 0
            words[p] = StateObject{T}(typemax(T), trailer)
        else
            words[p] = StateObject{T}(parse(T, "0b" * "1"^rest * "0"^(n-rest)), trailer)
        end

        index = collect(Int, 1:p)
        limit = StateObject{Int}(p, trailer)
        mask = Vector{T}(undef, p)

        return new(words, index, limit, mask)
    end
end

RSparseBitSet(size::Int, trailer) = RSparseBitSet{UInt64}(size::Int, trailer)


"""
    clearMask!(::RSparseBitSet{T})

Set all the masks to 0.
"""
function clearMask!(set::RSparseBitSet{T})::Nothing where T <: Unsigned
    offsets = set.index[1:set.limit.value]
    set.mask[offsets] .= T(0)
    return
end

"""
    reverseMask!(::RSparseBitSet)

Set the mask to its opposite: Boolean NOT.
"""
function reverseMask!(set::RSparseBitSet{T})::Nothing where T <: Unsigned
    offsets = set.index[1:set.limit.value]
    set.mask[offsets] .= .~ set.mask[offsets]
    return
end

"""
    addToMask!(::RSparseBitSet{T}, m)

Add the content of m to the mask: Boolean OR.
"""
function addToMask!(set::RSparseBitSet{T}, m::Vector{T})::Nothing where T <: Unsigned
    offsets = set.index[1:set.limit.value]
    set.mask[offsets] .= set.mask[offsets] .| m[offsets]
    return
end

"""
    intersectWithMask!(::RSparseBitSet{T})

Apply the mask to words: Bolean AND.
"""
function intersectWithMask!(set::RSparseBitSet{T})::Nothing where T <: Unsigned
    for i = set.limit.value:-1:1
        offset = set.index[i]
        word = set.words[offset].value & set.mask[offset]
        setValue!(set.words[offset], word)
        if word == 0
            set.index[i], set.index[set.limit.value] = set.index[set.limit.value], set.index[i]
            setValue!(set.limit, set.limit.value-1)
        end
    end
    return
end

"""
    intersectIndex(::RSparseBitSet{T}, m)

Return the index of the first word intersecting m, or -1 if none exist.
"""
function intersectIndex(set::RSparseBitSet{T}, m::Vector{T})::Int where T <: Unsigned
    for i = 1:set.limit.value
        offset = set.index[i]
        if set.words[offset].value & m[offset] != 0
            return offset
        end
    end
    return -1
end

"""
    bitVectorToUInt64Vector(bitset)::Vector{UInt64}

Convert a Julia BitVector to a vector preformatted for the RSparseBitSet{UInt64}.

# Arguments
- `bitset::BitVector`: the BitVector to convert.
"""
function bitVectorToUInt64Vector(bitset::BitVector)::Vector{UInt64}
    return [bitreverse(chunk) for chunk in bitset.chunks]
end

function Base.BitVector(set::RSparseBitSet{UInt64})
    bitvector = BitVector(undef, 8*sizeof(UInt64)*length(set.words))
    bitvector .= false
    for i = set.limit.value:-1:1
        offset = set.index[i]
        bitvector.chunks[offset] = bitreverse(set.words[offset].value)
    end
    return bitvector
end

function Base.isempty(set::RSparseBitSet{T})::Bool where T <: Unsigned
    return set.limit.value == 0
end

function Base.getindex(set::RSparseBitSet{T}, idx::Integer) where T <: Unsigned
    n = sizeof(T) * 8
    wordIndex = Int(ceil((idx)/n))
    offset = (n - idx%n)%n
    return (set.words[wordIndex].value & (T(1) << offset)) > 0
end

function Base.show(io::IO, ::MIME"text/plain", set::RSparseBitSet{T}) where T <: Unsigned
    n = sizeof(T) * 8
    println(io, string(typeof(set)), ": index = ", set.index, ", limit = ", set.limit.value)
    println(io, "   words: ", join([string(x.value, base=16, pad=Int(n/4)) for x in set.words], " "))
    println(io, "   mask:  ", join([string(x, base=16, pad=Int(n/4)) for x in set.mask], " "))
end

function Base.show(io::IO, set::RSparseBitSet{T}) where T <: Unsigned
    n = sizeof(T) * 8
    println(io, string(typeof(set)), ": index = ", set.index, ", limit = ", set.limit.value)
    println(io, "   words: ", join([string(x.value, base=16, pad=Int(n/4)) for x in set.words], " "))
end
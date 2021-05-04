struct RSparseBitSet
    words::Vector{StateObject{UInt128}}
    index::Vector{Int}
    limit::StateObject{Int}
    mask::Vector{UInt128}

    function RSparseBitSet(size::Int, trailer)
        p = Int(ceil(size/128))
        rest = size % 128
        words = Vector{StateObject{UInt128}}(undef, p)
        for i = 1:(p-1)
            words[i] = StateObject{UInt128}(typemax(UInt128), trailer)
        end
        if rest == 0
            words[p] = StateObject{UInt128}(typemax(UInt128), trailer)
        else
            words[p] = StateObject{UInt128}(parse(UInt128, "0b" * "1"^rest * "0"^(128-rest)), trailer)
        end

        index = collect(Int, 1:p)
        limit = StateObject{Int}(p, trailer)
        mask = Vector{UInt128}(undef, p)

        return new(words, index, limit, mask)
    end
end

function Base.isempty(set::RSparseBitSet)::Bool
    return set.limit.value == 0
end

function clearMask!(set::RSparseBitSet)::Nothing
    offsets = set.index[1:set.limit.value]
    set.mask[offsets] .= UInt128(0)
    return
end

function reverseMask!(set::RSparseBitSet)::Nothing
    offsets = set.index[1:set.limit.value]
    set.mask[offsets] .= .~ set.mask[offsets]
    return
end

function addToMask!(set::RSparseBitSet, m::Vector{UInt128})::Nothing
    offsets = set.index[1:set.limit.value]
    set.mask[offsets] .= set.mask[offsets] .| m[offsets]
    return
end

function intersectWithMask!(set::RSparseBitSet)::Nothing
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

function intersectIndex(set::RSparseBitSet, m::Vector{UInt128})::Int
    for i = 1:set.limit.value
        offset = set.index[i]
        if set.words[offset].value & m[offset] != 0
            return offset
        end
    end
    return -1
end

"""
Code get from github:
https://github.com/JuliaGPU/CUDA.jl/issues/177#issuecomment-838311843
"""

import Zygote

import Base: _RepeatInnerOuter

@kernel function repeat_inner_kernel!(a::AbstractArray{<:Any, N}, inner::NTuple{N}, out) where {N}
    inds = @index(Global, NTuple)
    inds_a = ntuple(i -> (inds[i] - 1) ÷ inner[i] + 1, N)

    @inbounds out[inds...] = a[inds_a...]
end

function repeat_inner(a::TV, inner) where {TV<:AbstractArray}
    out = TV(undef, inner .* size(a))

    kernel! = if out isa CuArray
        repeat_inner_kernel!(CUDADevice(), 512)
    else
        repeat_inner_kernel!(CPU(), Threads.nthreads())
    end

    ev = kernel!(a, inner, out, ndrange=size(out))
    wait(ev)
    return out
end
# Non-cached coherent loads
@kernel function repeat_outer_kernel!(a::AbstractArray{<:Any, N}, sa::NTuple{N}, outer::NTuple{N}, out) where {N}
    inds = @index(Global, NTuple)
    inds_a = ntuple(i -> (inds[i] - 1) % sa[i] + 1, N)

    @inbounds out[inds...] = a[inds_a...]
end

function repeat_outer(a::TV, outer) where {TV<:AbstractArray}
    out = TV(undef, outer .* size(a))

    kernel! = if out isa CuArray
        repeat_outer_kernel!(CUDADevice(), 512)
    else
        repeat_outer_kernel!(CPU(), Threads.nthreads())
    end

    ev = kernel!(a, size(a), outer, out, ndrange=size(out))
    wait(ev)
    return out
end


# Overload methods used by `Base.repeat`.
# No need to implement `repeat_inner_outer` since this is implemented in `Base` as
# `repeat_outer(repeat_inner(arr, inner), outer)`.
function _RepeatInnerOuter.repeat_inner(a::CuArray{<:Any, N}, dims::NTuple{N}) where {N}
    return repeat_inner(a, dims)
end

function _RepeatInnerOuter.repeat_outer(a::CuArray{<:Any, N}, dims::NTuple{N}) where {N}
    return repeat_outer(a, dims)
end

function _RepeatInnerOuter.repeat_outer(a::CuVector, dims::Tuple{Any})
    return repeat_outer(a, dims)
end

function _RepeatInnerOuter.repeat_outer(a::CuMatrix, dims::NTuple{2, Any})
    return repeat_outer(a, dims)
end

### Adjoint implementation for `repeat`
@kernel function repeat_adjoint_gpu_kernel!(
    Δ::AbstractArray{T},
    inner::NTuple,
    outer::NTuple,
    out::AbstractArray{T},
    outsize::NTuple{N}
) where {N, T<:Real}
    dest_inds = @index(Global, NTuple)
    src_inds = ntuple(i -> mod1((dest_inds[i] - 1) ÷ inner[i] + 1, outsize[i]), N)
    CUDA.@atomic out[src_inds...] += Δ[dest_inds...]
end;

# FIXME: not threadsafe atm!!! And therefore not used anywhere (we only overload) the
# adjoint for `CuArray`. But if we have  something like `@atomic_addindex!`
# from https://github.com/JuliaLang/julia/pull/37683, we'd be golden.
@kernel function repeat_adjoint_cpu_kernel!(
    Δ::AbstractArray,
    inner::NTuple,
    outer::NTuple,
    out::AbstractArray,
    outsize::NTuple{N}
) where {N}
    dest_inds = @index(Global, NTuple)
    src_inds = ntuple(i -> mod1((dest_inds[i] - 1) ÷ inner[i] + 1, outsize[i]), N)
    # FIXME: make threadsafe
    out[src_inds...] += Δ[dest_inds...]
end;

function repeat_adjoint(
    x,
    Δ::AbstractArray{<:Any, N},
    inner::NTuple{N},
    outer::NTuple{N}
) where {N}
    out = zero(x)

    kernel! = if out isa CuArray
        repeat_adjoint_gpu_kernel!(CUDADevice(), 512)
    else
        repeat_adjoint_cpu_kernel!(CPU(), Threads.nthreads())
    end

    ev = kernel!(Δ, inner, outer, out, size(out), ndrange=size(Δ))
    wait(ev)

    return out
end;


Zygote.@adjoint function _RepeatInnerOuter.repeat_inner_outer(xs::AbstractArray, inner::Nothing, outer::Nothing)
    return xs, Δ -> (Δ, )
end
Zygote.@adjoint function _RepeatInnerOuter.repeat_inner_outer(
    xs::AbstractArray,
    inner::Nothing,
    outer::NTuple{N}
) where {N}
    inner_new = ntuple(_ -> 1, N)
    return (
        _RepeatInnerOuter.repeat_outer(xs, outer),
        Δ -> (repeat_adjoint(xs, Δ, inner_new, outer), )
    )
end
Zygote.@adjoint function _RepeatInnerOuter.repeat_inner_outer(
    xs::AbstractArray,
    inner::NTuple{N},
    outer::Nothing
) where {N}
    outer_new = ntuple(_ -> 1, N)
    return (
        _RepeatInnerOuter.repeat_inner(xs, inner),
        Δ -> (repeat_adjoint(xs, Δ, inner, outer_new), )
    )
end
Zygote.@adjoint function _RepeatInnerOuter.repeat_inner_outer(
    xs::AbstractArray,
    inner::NTuple{N},
    outer::NTuple{N}
) where {N}
    return (
        _RepeatInnerOuter.repeat_outer(_RepeatInnerOuter.repeat_inner(xs, inner), outer),
        Δ -> (repeat_adjoint(xs, Δ, inner, outer), )
    )
end

# We need to stop Zygote from using the rule implemented in
# https://github.com/FluxML/Zygote.jl/blob/d5be4d5ca80e79278d714eaac15ca71904a262e3/src/lib/array.jl#L149-L163
# We stop this adjoint from triggering, and then call the underlying `repeat_inner_outer`.
# Unfortunately we need to replicate the body of `_RepeatInnerOuter.repeat` since we can't do `Zygote.pullback`
# for kwargs.
Zygote.@adjoint function Base.repeat(arr::CuArray; inner = nothing, outer = nothing)
    _RepeatInnerOuter.check(arr, inner, outer)
    arr, inner, outer = _RepeatInnerOuter.resolve(arr, inner, outer)
    return Zygote.pullback(_RepeatInnerOuter.repeat_inner_outer, arr, inner, outer)
end

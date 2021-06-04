Flux.@functor GeometricFlux.FeaturedGraph
Flux.@functor DefaultTrajectoryState
function Flux.functor(::Type{Vector{DefaultTrajectoryState}}, v)
    maxNode = Base.maximum(s -> nv(s.fg), v)
    featureLength = size(v[1].fg.nf, 1)
    batchSize = length(v)

    adjacencies = zeros(eltype(v[1].fg.nf), maxNode, maxNode, batchSize)
    features = zeros(eltype(v[1].fg.nf), featureLength, maxNode, batchSize)
    variables = ones(Int, batchSize)
    """
    Zygote.ignore() do
        foreach(enumerate(v)) do (idx, state)
            adj = adjacency_matrix(state.fg)
            adjacencies[1:size(adj,1),1:size(adj,2),idx] = adj
            features[1:size(state.fg.nf, 1),1:size(state.fg.nf, 2),idx] = state.fg.nf
            variables[idx] = state.variabeIdx
        end
    end
    """
    return (adjacencies, features), ls -> BatchedDefaultTrajectoryState(ls[1], ls[2], variables)
end

dcat(args...) = cat(args...; dims=3)

function batchedmul(x::AbstractMatrix{T}, y::AbstractArray{T, 3}) where T
    batchSize = size(y, 3)
    return dcat([x*y[:,:,i] for i = 1:batchSize]...)
end
Zygote.@adjoint function batchedmul(x::AbstractMatrix{T}, y::AbstractArray{T, 3}) where T
    back = z̄ -> (
        batchSize = size(z̄, 3);
        backX = sum([z̄[:,:,i]*y[:,:,i]' for i = 1:batchSize]);
        backY = dcat([x'*z̄[:,:,i] for i = 1:batchSize]...);
        (backX, backY)
    )
    return batchedmul(x,y), back
end

function batchedmul(x::AbstractArray{T, 3}, y::AbstractArray{T, 3}) where T 
    batchSize = size(y, 3)
    @assert batchSize == size(x, 3)
    return dcat([x[:,:,i] * y[:,:,i] for i = 1:batchSize]...)
end
Zygote.@adjoint function batchedmul(x::AbstractArray{T, 3}, y::AbstractArray{T, 3}) where T
    back = z̄ -> (
        batchSize = size(z̄, 3);
        backX = dcat([z̄[:,:,i]*y[:,:,i]' for i = 1:batchSize]...);
        backY = dcat([x[:,:,i]'*z̄[:,:,i] for i = 1:batchSize]...);
        (backX, backY)
    )
    return batchedmul(x,y), back
end

(g::GeometricFlux.GraphConv)(t::Tuple{AbstractArray, AbstractArray}) = g(t[1], t[2])
function (g::GeometricFlux.GraphConv)(A::R, X::T) where{R<:AbstractArray, T<:AbstractArray}
    B = T(undef, size(A))
    Zygote.ignore() do 
        copyto!(B,T(A))
    end
    g(B,X)
end
function (g::GeometricFlux.GraphConv)(A::T, X::T) where {T <: AbstractMatrix}
    return A, g.σ.(g.weight1 * X .+ g.weight2 * X * A .+ g.bias)
end
function (g::GeometricFlux.GraphConv)(A::T, X::T) where {T <: AbstractArray{<:Real, 3}}
    m1 = batchedmul(g.weight1, X)
    m2 = batchedmul(batchedmul(g.weight2, X), A)
    return A, g.σ.(m1 .+ m2 .+ g.bias)
end

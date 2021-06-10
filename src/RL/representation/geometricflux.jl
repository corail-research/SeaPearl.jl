using NNlib: batched_mul

"""
GeometricFlux isn't written to sustain many parallel graph computations, and for each graph
it relies on a sequential implementation that isn't supported by GPUs.
Thus we propose our own version of the GeometricFlux API, using only matrices as input, eventually in 3D, to 
make it possible to compute GNNs on many graphs simultaneously.
"""

(g::GeometricFlux.GraphConv)(fgs::BatchedDefaultTrajectoryState) = g(fgs.adjacencies, fgs.nodeFeatures)
(g::GeometricFlux.GraphConv)(t::Tuple{AbstractArray, AbstractArray}) = g(t...)
function (g::GeometricFlux.GraphConv)(A::R, X::T) where{R<:AbstractArray, T<:AbstractArray}
    B = T(undef, size(A))
    Zygote.ignore() do 
        copyto!(B,T(A))
    end
    g(B,X)
end
(g::GeometricFlux.GraphConv)(A::T, X::T) where {T <: AbstractMatrix} = A, g.σ.(g.weight1 * X .+ g.weight2 * X * A .+ g.bias)
(g::GeometricFlux.GraphConv)(A::T, X::T) where {T <: AbstractArray{<:Real, 3}} = A, g.σ.(g.weight1 ⊠ X .+ g.weight2 ⊠ X ⊠ A .+ g.bias)

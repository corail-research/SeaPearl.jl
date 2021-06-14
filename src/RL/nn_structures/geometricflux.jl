using NNlib: batched_mul

"""
GeometricFlux isn't written to sustain many parallel graph computations, and for each graph
it relies on a sequential implementation that isn't supported by GPUs.
Thus we propose our own version of the GeometricFlux API, using only matrices as input, eventually in 3D, to 
make it possible to compute GNNs on many graphs simultaneously.
"""

function (g::GeometricFlux.GraphConv)(fgs::BatchedDefaultTrajectoryState{Float32}) 
    A, X = fgs.adjacencies, fgs.nodeFeatures
    return BatchedDefaultTrajectoryState{Float32}(
        adjacencies = fgs.adjacencies,
        nodeFeatures = g.σ.(g.weight1 ⊠ X .+ g.weight2 ⊠ X ⊠ A .+ g.bias),
        edgeFeatures = fgs.edgeFeatures,
        globalFeatures = fgs.globalFeatures,
        variables = fgs.variables
    )
end

struct GraphNorm <: GeometricFlux.GraphNet
    batchNormLayer::Flux.BatchNorm

    GraphNorm(channels::Integer, σ = identity; initβ = zeros, initγ = ones, ϵ = Float32(1e-8), momentum = Float32(.1)) = new(Flux.BatchNorm(channels, σ; initβ = initβ, initγ = initγ, ϵ = ϵ, momentum = momentum))
    GraphNorm(bn::Flux.BatchNorm) = new(bn)
end

Flux.@functor GraphNorm
function (gn::GraphNorm)(fgs::BatchedDefaultTrajectoryState{Float32})
    X = fgs.nodeFeatures
    Y = reshape(X, size(X)[1:end - 2]..., :)
    return BatchedDefaultTrajectoryState{Float32}(
        adjacencies = fgs.adjacencies,
        nodeFeatures = reshape(gn.batchNormLayer(Y), size(X)),
        edgeFeatures = fgs.edgeFeatures,
        globalFeatures = fgs.globalFeatures,
        variables = fgs.variables
    )
end

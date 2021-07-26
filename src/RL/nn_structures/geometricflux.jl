using NNlib: batched_mul

"""
GeometricFlux isn't written to sustain many parallel graph computations, and for each graph
it relies on a sequential implementation that isn't supported by GPUs.
Thus we propose our own version of the GeometricFlux API, using only matrices as input, eventually in 3D, to 
make it possible to compute GNNs on many graphs simultaneously.
"""
# TODO: implement GraphConv
function (g::GraphConv)(fgs::BatchedFeaturedGraph{Float32}) 
    A, X = fgs.graph, fgs.nf
    return BatchedFeaturedGraph{Float32}(
        fgs.graph;
        nf = g.σ.(g.weight1 ⊠ X .+ g.weight2 ⊠ X ⊠ A .+ g.bias),
        ef = fgs.ef,
        gf = fgs.gf
    )
end


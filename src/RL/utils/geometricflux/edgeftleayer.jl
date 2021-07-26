"""
    EdgeFtLayer(v_in=>v_out, e_in=>e_out)

Edge Features Layers. This is used in [this article] to compute a state representation of the TSPTW.

[this article]: https://arxiv.org/abs/2006.01610

# Arguments
- `v_in`: the dimension of input features for vertices.
- `v_out`: the dimension of output features for vertices.
- `e_in`: the dimension of input features for edges.
- `e_out`: the dimension of output features for edges.
"""
struct EdgeFtLayer{T <: Real}
    W_a::AbstractMatrix{T}
    W_T::AbstractMatrix{T}
    b_T::AbstractVector{T}
    W_e::AbstractMatrix{T}
    W_ee::AbstractMatrix{T}
    σ
end

function EdgeFtLayer(vDim::Pair{<:Integer,<:Integer}, eDim::Pair{<:Integer,<:Integer}, σ=identity; init=Flux.glorot_uniform, T::DataType=Float32, bias::Bool=true)

    vIn, vOut = vDim
    eIn, eOut = eDim

    # Used to compute node features
    W_a = T.(init(vOut, 2 * vIn + eIn))
    W_T = T.(init(vOut, 2 * vIn + eIn))
    b_T = bias ? T.(init(vOut)) : zeros(T, vOut)

    # Used to compute edge features
    W_e = T.(init(eOut, vIn))
    W_ee = T.(init(eOut, eIn))

    EdgeFtLayer(W_a, W_T, b_T, W_e, W_ee, σ)
end

Flux.@functor EdgeFtLayer

function (g::EdgeFtLayer)(fg::FeaturedGraph)
    nNodes = nv(fg)
    mask = Flux.unsqueeze(fg.graph, 1) # used to broadcast arrays to the right shape

    srcNodes = Flux.unsqueeze(fg.nf, 3) # FxNx1
    dstNodes = Flux.unsqueeze(fg.nf, 2) # Fx1xN
    inpFeatures = vcat(srcNodes .* mask, fg.ef .* mask, dstNodes .* mask) # (F+E+F)xNxN

    attention = Flux.softmax(g.σ.(g.W_a ⊠ inpFeatures), dims=2)
    nodeFeatures = (sum(attention .* (g.W_T ⊠ inpFeatures), dims=2) .+ g.b_T)[:,1,:]
    edgeFeatures = (g.W_e ⊠ (srcNodes .+ dstNodes) + g.W_ee ⊠ fg.ef) .* mask

    return FeaturedGraph(
        fg.graph,
        nodeFeatures,
        edgeFeatures,
        fg.gf,
        fg.directed
    )
end


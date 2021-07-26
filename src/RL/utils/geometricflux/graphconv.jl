
struct GraphConv{A <: AbstractMatrix, B}
    weight1::A
    weight2::B
    bias::B
    σ
end

function GraphConv(ch::Pair{Int, Int}, σ=identity; init=glorot_uniform, bias::Bool=true)
    in, out = ch
    W1 = init(out, in)
    W2 = init(out, in)
    b = Flux.create_bias(W1, bias, out)
    return GraphConv(W1, W2, b, σ)
end

Flux.@functor GraphConv

function (g::GraphConv)(fgs::BatchedFeaturedGraph{Float32}) 
    A, X = fgs.graph, fgs.nf
    return BatchedFeaturedGraph{Float32}(
        fgs.graph;
        nf = g.σ.(g.weight1 ⊠ X .+ g.weight2 ⊠ X ⊠ A .+ g.bias),
        ef = fgs.ef,
        gf = fgs.gf
    )
end

function (g::GraphConv)(fg::FeaturedGraph)
    A, X = fg.graph, fg.nf
    return FeaturedGraph(
        fg.graph,
        g.σ.(g.weight1 * X .+ g.weight2 * X * A .+ g.bias),
        fg.ef,
        fg.gf,
        fg.directed
    )
end
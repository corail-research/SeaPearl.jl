
struct HeterogeneousGraphConv{A <: AbstractMatrix, B}
    weights1::A
    weights2::A
    weights3::A
    bias1::B
    bias2::B
    bias3::B
    σ
end

function HeterogeneousGraphConv(ch::Pair{Int, Int}, original_dimensions::Array{Int}, σ=identity; init=Flux.glorot_uniform, bias::Bool=true, T::DataType=Float32)
    in, out = ch
    weights1 = init(out, 3*in + original_dimensions[1])
    b1 = bias ? T.(init(3*in + original_dimensions[1])) : zeros(T, 3*in + original_dimensions[1])
    weights2 = init(out, in + original_dimensions[2])
    b2 = bias ? T.(init(in + original_dimensions[2])) : zeros(T, in + original_dimensions[2])
    weights3 = init(out, in + original_dimensions[3])
    b3 = bias ? T.(init(in + original_dimensions[3])) : zeros(T, in + original_dimensions[3])
    return HeterogeneousGraphConv(weights1, weights2, weights3, b1, b2, b3, σ)
end

Flux.@functor HeterogeneousGraphConv

function (g::HeterogeneousGraphConv)(fgs::BatchedHeterogeneousFeaturedGraph{Float32}, original_fgs::BatchedHeterogeneousFeaturedGraph{Float32}) 
    A11, A12, A13 = fgs.A11, fgs.A12, fgs.A13
    H1, H2, H3 = fgs.nf1, fgs.nf2, fgs.nf3
    X1, X2, X3 = original_fgs.nf1, original_fgs.nf2, original_fgs.nf3
    return BatchedHeterogeneousFeaturedGraph{Float32}(
        A11,
        A12,
        A13,
        g.σ.(g.weights1 ⊠ vcat(X1, H1, A11 ⊠ H1, transpose(A12) ⊠ H2, transpose(A13) ⊠ H3) .+ g.bias1),
        g.σ.(g.weights2 ⊠ vcat(X2, H2, A12 ⊠ H1) .+ g.bias2),
        g.σ.(g.weights3 ⊠ vcat(X3, H3, A13 ⊠ H1) .+ g.bias3),
        fg.gf
    )
end

function (g::HeterogeneousGraphConv)(fg::HeterogeneousFeaturedGraph, original_fg::HeterogeneousFeaturedGraph)
    A11, A12, A13 = fg.A11, fg.A12, fg.A13
    H1, H2, H3 = fg.nf1, fg.nf2, fg.nf3
    X1, X2, X3 = original_fg.nf1, original_fg.nf2, original_fg.nf3
    return HeterogeneousFeaturedGraph(
        A11,
        A12,
        A13,
        g.σ.(g.weights1 * vcat(X1, H1, A11 * H1, transpose(A12) * H2, transpose(A13) * H3) .+ g.bias1),
        g.σ.(g.weights2 * vcat(X2, H2, A12 * H1) .+ g.bias2),
        g.σ.(g.weights3 * vcat(X3, H3, A13 * H1) .+ g.bias3),
        fg.gf
    )
end

#=
# Alternative formulation
function (g::HeterogeneousGraphConv)(fg::HeterogeneousFeaturedGraph, original_fg::HeterogeneousFeaturedGraph)
    A11, A12, A13 = fg.A11, fg.A12, fg.A13
    ind1, ind2, ind3 = fg.ind1, fg.ind2, fg.ind3
    H = fg.vectors
    X = original_fg.vectors
    return HeterogeneousFeaturedGraph(
        fg.graph,
        g.σ.(ind1 .* (g.weights1 * vcat(X, H, A11 * H, A12 * H, A13 * H) .+ g.bias1) .+ ind2 .* (g.weights2 * vcat(X, H, transpose(A12)*fg.vectors, A23 * H) .+ g.bias2) .+ ind3 .* (g.weights3 * vcat(X, H, transpose(A13) * H, transpose(A23) * H) .+ g.bias3)),
        fg.ef,
        fg.gf,
        fg.directed
    )
end
=#
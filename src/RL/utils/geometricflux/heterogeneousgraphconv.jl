
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
    contovar, valtovar = fgs.contovar, fgs.valtovar
    H1, H2, H3 = fgs.varnf, fgs.connf, fgs.valnf
    X1, X2, X3 = original_fgs.varnf, original_fgs.connf, original_fgs.valnf
    return BatchedHeterogeneousFeaturedGraph{Float32}(
        contovar,
        valtovar,
        g.σ.(g.weights1 ⊠ vcat(X1, H1, contovar ⊠ H2, valtovar ⊠ H3) .+ g.bias1),
        g.σ.(g.weights2 ⊠ vcat(X2, H2, transpose(contovar) ⊠ H1) .+ g.bias2),
        g.σ.(g.weights3 ⊠ vcat(X3, H3, transpose(valtovar) ⊠ H1) .+ g.bias3),
        fg.gf
    )
end

function (g::HeterogeneousGraphConv)(fg::HeterogeneousFeaturedGraph, original_fg::HeterogeneousFeaturedGraph)
    contovar, valtovar = fg.contovar, fg.valtovar
    H1, H2, H3 = fg.varnf, fg.connf, fg.valnf
    X1, X2, X3 = original_fg.varnf, original_fg.connf, original_fg.valnf
    return HeterogeneousFeaturedGraph(
        contovar,
        valtovar,
        g.σ.(g.weights1 * vcat(X1, H1, contovar * H2, valtovar * H3) .+ g.bias1),
        g.σ.(g.weights2 * vcat(X2, H2, transpose(contovar) * H1) .+ g.bias2),
        g.σ.(g.weights3 * vcat(X3, H3, transpose(valtovar) * H1) .+ g.bias3),
        fg.gf
    )
end

#=
# Alternative formulation
function (g::HeterogeneousGraphConv)(fg::HeterogeneousFeaturedGraph, original_fg::HeterogeneousFeaturedGraph)
    A11, contovar, valtovar = fg.A11, fg.contovar, fg.valtovar
    ind1, ind2, ind3 = fg.ind1, fg.ind2, fg.ind3
    H = fg.vectors
    X = original_fg.vectors
    return HeterogeneousFeaturedGraph(
        fg.graph,
        g.σ.(ind1 .* (g.weights1 * vcat(X, H, A11 * H, contovar * H, valtovar * H) .+ g.bias1) .+ ind2 .* (g.weights2 * vcat(X, H, transpose(contovar)*fg.vectors, A23 * H) .+ g.bias2) .+ ind3 .* (g.weights3 * vcat(X, H, transpose(valtovar) * H, transpose(A23) * H) .+ g.bias3)),
        fg.ef,
        fg.gf,
        fg.directed
    )
end
=#
struct HeterogeneousGraphConv{A<:AbstractMatrix,B}
    weightsvar::A
    weightscon::A
    weightsval::A
    biasvar::B
    biascon::B
    biasval::B
    σ
end

function HeterogeneousGraphConv(ch::Pair{Int,Int}, original_dimensions::Array{Int}, σ=identity; init=Flux.glorot_uniform, bias::Bool=true, T::DataType=Float32)
    in, out = ch
    weightsvar = init(out, 3 * in + original_dimensions[1])
    biasvar = bias ? T.(init(out)) : zeros(T, out)
    weightscon = init(out, 2 * in + original_dimensions[2])
    biascon = bias ? T.(init(out)) : zeros(T, out)
    weightsval = init(out, 2 * in + original_dimensions[3])
    biasval = bias ? T.(init(out)) : zeros(T, out)
    return HeterogeneousGraphConv(weightsvar, weightscon, weightsval, biasvar, biascon, biasval, σ)
end

Flux.@functor HeterogeneousGraphConv

function (g::HeterogeneousGraphConv)(fgs::BatchedHeterogeneousFeaturedGraph{Float32}, original_fgs::BatchedHeterogeneousFeaturedGraph{Float32})
    contovar, valtovar = fgs.contovar, fgs.valtovar
    H1, H2, H3 = fgs.varnf, fgs.connf, fgs.valnf
    X1, X2, X3 = original_fgs.varnf, original_fgs.connf, original_fgs.valnf
    return BatchedHeterogeneousFeaturedGraph{Float32}(
        contovar,
        valtovar,
        g.σ.(g.weightsvar ⊠ vcat(X1, H1, H2 ⊠ contovar, H3 ⊠ valtovar) .+ g.biasvar),
        g.σ.(g.weightscon ⊠ vcat(X2, H2, H1 ⊠ transpose(contovar)) .+ g.biascon),
        g.σ.(g.weightsval ⊠ vcat(X3, H3, H1 ⊠ transpose(valtovar)) .+ g.biasval),
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
        g.σ.(g.weightsvar * vcat(X1, H1, H2 * contovar, H3 * valtovar) .+ g.biasvar),
        g.σ.(g.weightscon * vcat(X2, H2, H1 * transpose(contovar)) .+ g.biascon),
        g.σ.(g.weightsval * vcat(X3, H3, H1 * transpose(valtovar)) .+ g.biasval),
        fg.gf
    )
end
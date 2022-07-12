struct HeterogeneousGraphConvInit{A <: AbstractMatrix, B,G<:pool}
    weightsvar::A
    weightscon::A
    weightsval::A
    biasvar::B
    biascon::B
    biasval::B
    σ
    pool::G

end

function HeterogeneousGraphConvInit(in::Array{Int}, out::Int, σ=identity; init=Flux.glorot_uniform, bias::Bool=true, T::DataType=Float32, pool::pool=meanPooling())
    weightsvar = init(out, in[1])
    biasvar = bias ? T.(init(out)) : zeros(T, out)
    weightscon = init(out, in[2])
    biascon = bias ? T.(init(out)) : zeros(T, out)
    weightsval = init(out, in[3])
    biasval = bias ? T.(init(out)) : zeros(T, out)
    return HeterogeneousGraphConvInit(weightsvar, weightscon, weightsval, biasvar, biascon, biasval, σm pool)
end

Flux.@functor HeterogeneousGraphConvInit

function (g::HeterogeneousGraphConvInit{<:AbstractMatrix,<:Any,sumPooling})(fgs::BatchedHeterogeneousFeaturedGraph{Float32}) 
    return BatchedHeterogeneousFeaturedGraph{Float32}(
        fgs.contovar,
        fgs.valtovar,
        g.σ.(g.weightsvar ⊠ fgs.varnf .+ g.biasvar),
        g.σ.(g.weightscon ⊠ fgs.connf .+ g.biascon),
        g.σ.(g.weightsval ⊠ fgs.valnf .+ g.biasval),
        fgs.gf
    )
end

function (g::HeterogeneousGraphConvInit{<:AbstractMatrix,<:Any,sumPooling})(fg::HeterogeneousFeaturedGraph)
    return HeterogeneousFeaturedGraph(
        fg.contovar,
        fg.valtovar,
        g.σ.(g.weightsvar * fg.varnf .+ g.biasvar),
        g.σ.(g.weightscon * fg.connf .+ g.biascon),
        g.σ.(g.weightsval * fg.valnf .+ g.biasval),
        fg.gf
    )
end
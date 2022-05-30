struct HeterogeneousGraphConv{A<:AbstractMatrix,B, G <: pool}
    weightsvar::A
    weightscon::A
    weightsval::A
    biasvar::B
    biascon::B
    biasval::B
    σ
    pool::G
end

function HeterogeneousGraphConv(ch::Pair{Int,Int}, original_dimensions::Array{Int}, σ=Flux.leakyrelu; init=Flux.glorot_uniform, bias::Bool=true, T::DataType=Float32,pool::pool=meanPooling())
    in, out = ch
    weightsvar = init(out, 3 * in + original_dimensions[1])
    biasvar = bias ? T.(init(out)) : zeros(T, out)
    weightscon = init(out, 2 * in + original_dimensions[2])
    biascon = bias ? T.(init(out)) : zeros(T, out)
    weightsval = init(out, 2 * in + original_dimensions[3])
    biasval = bias ? T.(init(out)) : zeros(T, out)
    return HeterogeneousGraphConv(weightsvar, weightscon, weightsval, biasvar, biascon, biasval, σ, pool)
end

Flux.@functor HeterogeneousGraphConv

function (g::HeterogeneousGraphConv)(fgs::BatchedHeterogeneousFeaturedGraph{Float32}, original_fgs::BatchedHeterogeneousFeaturedGraph{Float32})
    contovar, valtovar = fgs.contovar, fgs.valtovar
    vartocon, vartoval = permutedims(contovar, [2,1,3]), permutedims(valtovar, [2,1,3])
    H1, H2, H3 = fgs.varnf, fgs.connf, fgs.valnf
    X1, X2, X3 = original_fgs.varnf, original_fgs.connf, original_fgs.valnf
    if isa(g.pool,meanPooling)
        contovarN = contovar./reshape(mapslices(x->sum(eachrow(x)) , contovar, dims=[1,2]), 1, :,  size(contovar,3))
        valtovarN = valtovar./reshape(mapslices(x->sum(eachrow(x)) , valtovar, dims=[1,2]), 1, :,  size(valtovar,3))
        vartoconN = vartocon./reshape(mapslices(x->sum(eachrow(x)) , vartocon, dims=[1,2]), 1, :,  size(vartocon,3))
        vartovalN = vartoval./reshape(mapslices(x->sum(eachrow(x)) , vartoval, dims=[1,2]), 1, :,  size(vartoval,3))
    else if isa(g.pool,sumPooling)
        contovarN, valtovarN, vartoconN, vartovalN = contovar, valtovar, vartocon, vartoval  
    end

    return BatchedHeterogeneousFeaturedGraph{Float32}(
        contovar,
        valtovar,
        g.σ.(g.weightsvar ⊠ vcat(X1, H1, H2 ⊠ contovarN, H3 ⊠ valtovarN) .+ g.biasvar),
        g.σ.(g.weightscon ⊠ vcat(X2, H2, H1 ⊠ vartoconN) .+ g.biascon),
        g.σ.(g.weightsval ⊠ vcat(X3, H3, H1 ⊠ vartovalN) .+ g.biasval),
        fgs.gf
    )
    end

function (g::HeterogeneousGraphConv)(fg::HeterogeneousFeaturedGraph, original_fg::HeterogeneousFeaturedGraph)
    contovar, valtovar = fg.contovar, fg.valtovar
    vartocon, vartoval = transpose(contovar), transpose(valtovar)
    H1, H2, H3 = fg.varnf, fg.connf, fg.valnf
    X1, X2, X3 = original_fg.varnf, original_fg.connf, original_fg.valnf
    if isa(g.pool,meanPooling)
        contovarN = contovar./reshape(sum(eachrow(contovar)), 1, :)
        valtovarN = valtovar./reshape(sum(eachrow(contovar)), 1, :)
        vartoconN = vartocon./reshape(sum(eachrow(vartocon)), 1, :)
        vartovalN = vartoval./reshape(sum(eachrow(vartoval)), 1, :)
    else if isa(g.pool,sumPooling)
        contovarN, valtovarN, vartoconN, vartovalN = contovar, valtovar, vartocon, vartoval  
    end

    return HeterogeneousFeaturedGraph(
        contovar,
        valtovar,
        g.σ.(g.weightsvar * vcat(X1, H1, H2 * contovarN, H3 * valtovarN) .+ g.biasvar),
        g.σ.(g.weightscon * vcat(X2, H2, H1 * vartoconN) .+ g.biascon),
        g.σ.(g.weightsval * vcat(X3, H3, H1 * vartovalN) .+ g.biasval),
        fg.gf
    )
end
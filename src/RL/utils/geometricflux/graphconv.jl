struct GraphConv{A<:AbstractMatrix,B,G<:pool}
    weight1::A
    weight2::A
    bias::B
    σ
    pool::G
end

function GraphConv(ch::Pair{Int,Int}, σ=Flux.leakyrelu; init=Flux.glorot_uniform, bias::Bool=true, T::DataType=Float32, pool::pool=sumPooling())
    in, out = ch
    W1 = init(out, in)
    W2 = init(out, in)
    b = bias ? T.(init(ch[2])) : zeros(T, ch[2])
    return GraphConv(W1, W2, b, σ, pool)
end

Flux.@functor GraphConv

function (g::GraphConv{<:AbstractMatrix,<:Any,sumPooling})(fgs::BatchedFeaturedGraph{Float32})
    A, X = fgs.graph, fgs.nf
    
    return BatchedFeaturedGraph{Float32}(
        fgs.graph;
        nf=g.σ.(g.weight1 ⊠ X .+ g.weight2 ⊠ X ⊠ A .+ g.bias),
        ef=fgs.ef,
        gf=fgs.gf
    )
end

function (g::GraphConv{<:AbstractMatrix,<:Any,sumPooling})(fg::FeaturedGraph)
    A, X = fg.graph, fg.nf
    return FeaturedGraph(
        fg.graph,
        g.σ.(g.weight1 * X .+ g.weight2 * X * A .+ g.bias),
        fg.ef,
        fg.gf,
        fg.directed
    )
end

function (g::GraphConv{<:AbstractMatrix,<:Any,meanPooling})(fgs::BatchedFeaturedGraph{Float32})
    A, X = fgs.graph, fgs.nf

    sum = nothing
    Zygote.ignore() do
        sum = replace(reshape(mapslices(x -> sum(eachrow(x)), A, dims=[1, 2]), 1, :, size(A, 3)), 0=>1)    
    end
    A = A ./ sum

    return BatchedFeaturedGraph{Float32}(
        fgs.graph;
        nf=g.σ.(g.weight1 ⊠ X .+ g.weight2 ⊠ X ⊠ A .+ g.bias),
        ef=fgs.ef,
        gf=fgs.gf
    )
end

function (g::GraphConv{<:AbstractMatrix,<:Any,meanPooling})(fg::FeaturedGraph)
    A, X = fg.graph, fg.nf
    
    sum = reshape(sum(eachrow(A)), 1, :)
    Zygote.ignore() do
        replace(sum, 0=>1)
    end
    A = A ./ sum
    
    return FeaturedGraph(
        fg.graph,
        g.σ.(g.weight1 * X .+ g.weight2 * X * A .+ g.bias),
        fg.ef,
        fg.gf,
        fg.directed
    )
end

function (g::GraphConv{<:AbstractMatrix,<:Any,maxPooling})(fgs::BatchedFeaturedGraph{Float32})
    A, X = fgs.graph, fgs.nf

    Zygote.ignore() do
        B = repeat(collect(1:size(A,2)),1,size(A,2)).*A
        B = collect.(zip(B,cat(repeat([1],size(A)[1:2]...),repeat([2], size(A)[1:2]...),dims= 3)))
        filteredcol = mapslices( x -> map(z-> filter(y -> y[1]!=0,z),eachcol(x)),B,dims=[1,2])
        filteredemb = mapslices(x->map(y-> maximum(mapreduce(z->X[:,z...], hcat, y), dims =2),  x), filteredcol, dims = [2])
        filteredemb = reshape(reduce(hcat ,filteredemb), size(X))
    end
        return BatchedFeaturedGraph{Float32}(
            fgs.graph;
            nf=g.σ.(g.weight1 ⊠ X .+ g.weight2 ⊠ filteredemb .+ g.bias),
            ef=fgs.ef,
            gf=fgs.gf
        )
    
end

function (g::GraphConv{<:AbstractMatrix,<:Any, maxPooling})(fg::FeaturedGraph)
    A, X = fg.graph, fg.nf
    Zygote.ignore() do
        B = repeat(collect(1:size(A,2)),1,size(A,2)).*A
        filteredcol = map(x-> filter(y -> y!=0,x),eachcol(B))
        filteredemb = mapreduce(x->maximum(X[:,x], dims = 2), hcat,filteredcol)

    end
        return BatchedFeaturedGraph{Float32}(
            fgs.graph;
            nf=g.σ.(g.weight1 ⊠ X .+ g.weight2 ⊠ filteredemb .+ g.bias),
            ef=fgs.ef,
            gf=fgs.gf
        )

end
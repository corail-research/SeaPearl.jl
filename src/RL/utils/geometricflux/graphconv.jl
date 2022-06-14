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
"""
function (g::GraphConv{<:AbstractMatrix,<:Any,maxPooling})(fgs::BatchedFeaturedGraph{Float32})

This function operates the coordinate-wise max-Pooling technique along the neightbors of every node of the input FeaturedGraph. For details about each operation step, look at the maxèpooling function for non-batched FeaturedGraph. 
"""
function (g::GraphConv{<:AbstractMatrix,<:Any,maxPooling})(fgs::BatchedFeaturedGraph{Float32})
    A, X = fgs.graph, fgs.nf

    Zygote.ignore() do
        B = repeat(collect(1:size(A,2)),1,size(A,2)).*A
        B = collect.(zip(B,cat(repeat([1],size(A)[1:2]...),repeat([2], size(A)[1:2]...),dims= 3)))
        filteredcol = mapslices( x -> map(z-> filter(y -> y[1]!=0,z),eachcol(x)), B, dims= [1,2])
        filteredemb = mapslices(x->map(y-> maximum(mapreduce(z->X[:,z...], hcat, y), dims =2),  x), filteredcol, dims = [1,3])
        filteredemb = reshape(reduce(hcat ,filteredemb), size(X))
    end
        return BatchedFeaturedGraph{Float32}(
            fgs.graph;
            nf=g.σ.(g.weight1 ⊠ X .+ g.weight2 ⊠ filteredemb .+ g.bias),
            ef=fgs.ef,
            gf=fgs.gf
        )
    
end
"""
    function (g::GraphConv{<:AbstractMatrix,<:Any, maxPooling})(fg::FeaturedGraph)

This function operates the coordinate-wise max-Pooling technique along the neightbors of every node of the input FeaturedGraph.
    A is the adjacency Matrix
    X is the node embeddings

    B is of the same size as A. B[i,j] = i  <=> A[i,j] = 1
    filteredcol contains for every node, the list of index of its neightbors. B[:,j] = [1; 2 ; 0] => filteredcol[j] = [1 2]
    filteredemb contains for everynode the pooled embedding of its neightbors using the coordinate-wise maximum. filteredemb[i, j] = maximum( X[i, filteredcol[j]])

    Here is a little example : 

    X = [ 1 2 3       A = [ 1 0 0      B = [ 1 0 0      filteredcol = [[1, 2 3]       filteredemb = [3 2 3   
          5 1 2             1 1 1            2 2 2                     [2]                           5 1 2   
          3 1 4             1 0 1 ]          3 0 3 ]                   [2, 3]]                       4 1 4 
          2 3 6]                                                                                     6 3 6 ]
"""
function (g::GraphConv{<:AbstractMatrix,<:Any, maxPooling})(fg::FeaturedGraph)
    A, X = fg.graph, fg.nf
    Zygote.ignore() do
        B = repeat(collect(1:size(A,2)),1,size(A,2)).*A
        filteredcol = map(x-> filter(y -> y!=0,x),eachcol(B))
        filteredemb = mapreduce(x->maximum(X[:,x], dims = 2), hcat,filteredcol)
    end
        return FeaturedGraph{Float32}(
            fgs.graph;
            nf=g.σ.(g.weight1 ⊠ X .+ g.weight2 ⊠ filteredemb .+ g.bias),
            ef=fgs.ef,
            gf=fgs.gf
        )

end
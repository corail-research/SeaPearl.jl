struct HeterogeneousGraphTransformer
    
end
# Constructor
function HeterogeneousGraphTransformer()

end
Flux.@functor HeterogeneousGraphTransformer

# Forward batched
function (g::HeterogeneousGraphTransformer)(fgs::BatchedHeterogeneousFeaturedGraph{Float32})
    
end

# Forward unbatched
function (g::HeterogeneousGraphTransformer)(fg::HeterogeneousFeaturedGraph)
    
end
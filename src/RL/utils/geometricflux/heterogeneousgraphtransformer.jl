struct HeterogeneousGraphTransformer
    in_channels:: Int
    out_channels:: Int
    heads:: Int
    aggr:: String = "sum"
    k_lin_var::Vector{Flux.Dense} = Vector{Flux.Dense}(Flux.Dense(in_channels,out_channels,identity),heads)
    k_lin_con::Vector{Flux.Dense} = Vector{Flux.Dense}(Flux.Dense(in_channels,out_channels,identity),heads)
    k_lin_val::Vector{Flux.Dense} = Vector{Flux.Dense}(Flux.Dense(in_channels,out_channels,identity),heads)
    q_lin_var::Vector{Flux.Dense} = Vector{Flux.Dense}(Flux.Dense(in_channels,out_channels,identity),heads)
    q_lin_con::Vector{Flux.Dense} = Vector{Flux.Dense}(Flux.Dense(in_channels,out_channels,identity),heads)
    q_lin_val::Vector{Flux.Dense} = Vector{Flux.Dense}(Flux.Dense(in_channels,out_channels,identity),heads)
    m_lin_var::Vector{Flux.Dense} = Vector{Flux.Dense}(Flux.Dense(in_channels,out_channels,identity),heads)
    m_lin_con::Vector{Flux.Dense} = Vector{Flux.Dense}(Flux.Dense(in_channels,out_channels,identity),heads)
    m_lin_val::Vector{Flux.Dense} = Vector{Flux.Dense}(Flux.Dense(in_channels,out_channels,identity),heads)
    a_lin_var::Vector{Flux.Dense} = Vector{Flux.Dense}(Flux.Dense(in_channels,out_channels,identity),heads)
    a_lin_con::Vector{Flux.Dense} = Vector{Flux.Dense}(Flux.Dense(in_channels,out_channels,identity),heads)
    a_lin_val::Vector{Flux.Dense} = Vector{Flux.Dense}(Flux.Dense(in_channels,out_channels,identity),heads)
    w_att::Vector{Flux.Dense} = Vector{Flux.Dense}(Flux.Dense(out_channels//heads,out_channels//heads,identity),heads)
    w_mess::::Vector{Flux.Dense} = Vector{Flux.Dense}(Flux.Dense(out_channels//heads,out_channels//heads,identity),heads)
    dim::Int = out_channels//heads
end
# Constructor
function HeterogeneousGraphTransformer(in_channels::Int, out_channels::Int, heads::Int)
    @assert out_channels%heads==0
end
Flux.@functor HeterogeneousGraphTransformer

# Forward batched
function (g::HeterogeneousGraphTransformer)(fgs::BatchedHeterogeneousFeaturedGraph{Float32})
    
end

# Forward unbatched
function (g::HeterogeneousGraphTransformer)(fg::HeterogeneousFeaturedGraph)
    
end
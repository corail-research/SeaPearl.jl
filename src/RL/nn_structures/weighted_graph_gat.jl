"""
    GATConv([graph, ]in=>out)

Graph attentional layer.

# Arguments
- `graph`: should be a adjacency matrix, `SimpleGraph`, `SimpleDiGraph` (from LightGraphs) or `SimpleWeightedGraph`,
`SimpleWeightedDiGraph` (from SimpleWeightedGraphs). Is optionnal so you can give a `FeaturedGraph` to
the layer instead of only the features.
- `in`: the dimension of input features.
- `out`: the dimension of output features.
- `bias::Bool=true`: keyword argument, whether to learn the additive bias.
- `negative_slope::Real=0.2`: keyword argument, the parameter of LeakyReLU.
"""
struct WeightedGATConv{V<:AbstractFeaturedGraph, T <: Real} <: MessagePassing
    fg::V
    weight::AbstractMatrix{T}
    bias::AbstractVector{T}
    a::AbstractMatrix{T}
    negative_slope::Real
    channel::Pair{<:Integer,<:Integer}
    heads::Integer
    concat::Bool
end

function WeightedGATConv(adj::AbstractMatrix, ch::Pair{<:Integer,<:Integer}; heads::Integer=1,
                 concat::Bool=true, negative_slope::Real=0.2, init=glorot_uniform,
                 bias::Bool=true, T::DataType=Float32)
    w = T.(init(ch[2]*heads, ch[1]))
    b = bias ? T.(init(ch[2]*heads)) : zeros(T, ch[2]*heads)
    a = T.(init(2*ch[2], heads))
    fg = FeaturedGraph(adjacency_list(adj))
    WeightedGATConv(fg, w, b, a, negative_slope, ch, heads, concat)
end

function WeightedGATConv(ch::Pair{<:Integer,<:Integer}; heads::Integer=1,
                 concat::Bool=true, negative_slope::Real=0.2, init=glorot_uniform,
                 bias::Bool=true, T::DataType=Float32)
    w = T.(init(ch[2]*heads, ch[1]))
    b = bias ? T.(init(ch[2]*heads)) : zeros(T, ch[2]*heads)
    a = T.(init(2*ch[2], heads))
    GATConv(NullGraph(), w, b, a, negative_slope, ch, heads, concat)
end

@functor WeightedGATConv

# Here the α that has not been softmaxed is the first number of the output message
function message(g::WeightedGATConv, x_i::AbstractVector, x_j::AbstractVector, e_ij)
    x_i = reshape(g.weight*x_i, :, g.heads)
    x_j = reshape(g.weight*x_j, :, g.heads)
    n = size(x_i, 1)
    e = vcat(x_i, x_j+zero(x_j))
    e = sum(e .* g.a, dims=1)  # inner product for each head, output shape: (1, g.heads)
    e = leakyrelu.(e, g.negative_slope)
    vcat(e, x_j)  # shape: (n+1, g.heads)
end

# After some reshaping due to the multihead, we get the α from each message, 
# then get the softmax over every α, and eventually multiply the message by α
function apply_batch_message(g::WeightedGATConv, i, js, edge_idx, E::AbstractMatrix, X::AbstractMatrix, u)
    e_ij = hcat([message(g, get_feature(X, i), get_feature(X, j), get_feature(E, edge_idx[(i,j)])) for j = js]...)
    n = size(e_ij, 1)
    alphas = Flux.softmax(reshape(view(e_ij, 1, :), g.heads, :), dims=2)
    msgs = view(e_ij, 2:n, :) .* reshape(alphas, 1, :)
    reshape(msgs, (n-1)*g.heads, :)
end

function update_batch_edge(g::WeightedGATConv, adj, E::AbstractMatrix, X::AbstractMatrix, u)
    n = size(adj, 1)
    # In GATConv, a vertex must always receive a message from itself
    Zygote.ignore() do
        GeometricFlux.add_self_loop!(adj, n)
    end

    edge_idx = edge_index_table(adj)
    hcat([apply_batch_message(g, i, adj[i], edge_idx, E, X, u) for i in 1:n]...)
end

# The same as update function in batch manner
function update_batch_vertex(g::WeightedGATConv, M::AbstractMatrix, X::AbstractMatrix, u)
    M = M .+ g.bias
    if !g.concat
        N = size(M, 2)
        M = reshape(mean(reshape(M, :, g.heads, N), dims=2), :, N)
    end
    return M
end

function (gat::WeightedGATConv)(X::AbstractMatrix)
    @assert has_graph(gat.fg) "A WeightedGATConv created without a graph must be given a FeaturedGraph as an input."
    g = graph(gat.fg)
    _, X = propagate(gat, adjacency_list(g), Fill(0.f0, 0, ne(g)), X, :add)
    X
end
(g::WeightedGATConv)(fg::FeaturedGraph) = propagate(g, fg, :add)

function Base.show(io::IO, l::WeightedGATConv)
    in_channel = size(l.weight, ndims(l.weight))
    out_channel = size(l.weight, ndims(l.weight)-1)
    print(io, "WeightedGATConv(G(V=", nv(l.fg), ", E=", ne(l.fg))
    print(io, "), ", in_channel, "=>", out_channel)
    print(io, ", LeakyReLU(λ=", l.negative_slope)
    print(io, "))")
end


struct HeterogeneousGraphTransformer
    n_channels:: Int
    heads:: Int
    aggr:: String
    dim::Int
    k_lin_var::AbstractArray
    k_lin_con::AbstractArray
    k_lin_val::AbstractArray
    q_lin_var::AbstractArray
    q_lin_con::AbstractArray
    q_lin_val::AbstractArray
    m_lin_var::AbstractArray
    m_lin_con::AbstractArray
    m_lin_val::AbstractArray
    a_lin_var::AbstractArray
    a_lin_con::AbstractArray
    a_lin_val::AbstractArray
    σ
    W_MSG_contovar::AbstractArray
    W_MSG_vartocon::AbstractArray
    W_MSG_valtovar::AbstractArray
    W_MSG_vartoval::AbstractArray
    W_ATT_contovar::AbstractArray
    W_ATT_vartocon::AbstractArray
    W_ATT_valtovar::AbstractArray
    W_ATT_vartoval::AbstractArray
    mu_contovar
    mu_vartocon
    mu_valtovar
    mu_vartoval
end
# Constructor
function HeterogeneousGraphTransformer(n_channels::Int, heads::Int; init=Flux.glorot_uniform, aggr="sum", σ=Flux.leakyrelu)
    @assert n_channels%heads==0
    dim = Int(n_channels//heads)
    k_lin_var = init(n_channels,dim,heads)
    k_lin_con = init(n_channels,dim,heads)
    k_lin_val = init(n_channels,dim,heads)
    q_lin_var = init(n_channels,dim,heads)
    q_lin_con = init(n_channels,dim,heads)
    q_lin_val = init(n_channels,dim,heads)
    m_lin_var = init(n_channels,dim,heads)
    m_lin_con = init(n_channels,dim,heads)
    m_lin_val = init(n_channels,dim,heads)
    a_lin_var = init(n_channels,n_channels,heads)
    a_lin_con = init(n_channels,n_channels,heads)
    a_lin_val = init(n_channels,n_channels,heads)
    W_MSG_contovar = init(dim,dim)
    W_MSG_vartocon = init(dim,dim)
    W_MSG_valtovar = init(dim,dim)
    W_MSG_vartoval = init(dim,dim)
    W_ATT_contovar = init(dim,dim)
    W_ATT_vartocon = init(dim,dim)
    W_ATT_valtovar = init(dim,dim)
    W_ATT_vartoval = init(dim,dim)
    mu_contovar = init(1)
    mu_vartocon = init(1)
    mu_valtovar = init(1)
    mu_vartoval = init(1)
    return HeterogeneousGraphTransformer(n_channels, heads, aggr, dim, k_lin_var, k_lin_con, k_lin_val, q_lin_var, q_lin_con, q_lin_val, m_lin_var, m_lin_con, m_lin_val, a_lin_var, a_lin_con, a_lin_val, σ, W_MSG_contovar, W_MSG_vartocon, W_MSG_valtovar, W_MSG_vartoval, W_ATT_contovar, W_ATT_vartocon, W_ATT_valtovar, W_ATT_vartoval, mu_contovar, mu_vartocon, mu_valtovar, mu_vartoval)
end

Flux.@functor HeterogeneousGraphTransformer

# Forward batched
function (g::HeterogeneousGraphTransformer)(fgs::BatchedHeterogeneousFeaturedGraph{Float32})
    
end

# Forward unbatched
function (g::HeterogeneousGraphTransformer)(fg::HeterogeneousFeaturedGraph)
    contovar, valtovar = fg.contovar, fg.valtovar
    vartocon, vartoval = transpose(contovar), transpose(valtovar)
    H1, H2, H3 = transpose(fg.varnf), transpose(fg.connf), transpose(fg.valnf)
    d = g.dim

    # Heterogeneous Mutual Attention
    k_var = H1 ⊠ g.k_lin_var # nvar x dim x heads
    k_con = H2 ⊠ g.k_lin_con # ncon x dim x heads
    k_val = H3 ⊠ g.k_lin_val # nval x dim x heads
    q_var = H1 ⊠ g.k_lin_var # nvar x dim x heads
    q_con = H2 ⊠ g.k_lin_con # ncon x dim x heads
    q_val = H3 ⊠ g.k_lin_val # nval x dim x heads

    # We compute these coefficients on each node pair
    ATT_head_contovar = (k_con ⊠ g.W_ATT_contovar ⊠ permutedims(q_var, [2,1,3])) .* (g.mu_contovar/sqrt(d)) # ncon x nvar x heads
    ATT_head_vartocon = (k_var ⊠ g.W_ATT_vartocon ⊠ permutedims(q_con, [2,1,3])) .* (g.mu_vartocon/sqrt(d)) # nvar x ncon x heads
    ATT_head_valtovar = (k_val ⊠ g.W_ATT_valtovar ⊠ permutedims(q_var, [2,1,3])) .* (g.mu_valtovar/sqrt(d)) # nval x nvar x heads
    ATT_head_vartoval = (k_var ⊠ g.W_ATT_vartoval ⊠ permutedims(q_val, [2,1,3])) .* (g.mu_vartoval/sqrt(d)) # nvar x nval x heads

    # We apply softmax only on neighbors
    #=@assert prod(ATT_head_contovar.*100)!=0
    @assert prod(ATT_head_vartocon.*100)!=0
    @assert prod(ATT_head_valtovar.*100)!=0
    @assert prod(ATT_head_vartoval.*100)!=0=#
    heads = size(ATT_head_contovar)[3]
    nvar = size(contovar)[2]
    ncon = size(contovar)[1]
    nval = size(valtovar)[1]
    attention_contovar = softmax(replace((contovar .+ zeros(ncon, nvar, heads)) .*  ATT_head_contovar, 0.0 => -Inf); dims=2) # ncon x nvar x heads
    attention_vartocon = softmax(replace((vartocon .+ zeros(nvar, ncon, heads)) .*  ATT_head_vartocon, 0.0 => -Inf); dims=2) # nvar x ncon x heads
    attention_valtovar = softmax(replace((valtovar .+ zeros(nval, nvar, heads)) .*  ATT_head_valtovar, 0.0 => -Inf); dims=2) # nval x nvar x heads
    attention_vartoval = softmax(replace((vartoval .+ zeros(nvar, nval, heads)) .*  ATT_head_vartoval, 0.0 => -Inf); dims=2) # nvar x nval x heads

    # Heterogeneous Message Passing
    message_contovar = H2 ⊠ g.m_lin_con ⊠ g.W_MSG_contovar # ncon x dim x heads
    message_vartocon = H1 ⊠ g.m_lin_var ⊠ g.W_MSG_vartocon # nvar x dim x heads
    message_valtovar = H3 ⊠ g.m_lin_val ⊠ g.W_MSG_valtovar # nval x dim x heads
    message_vartoval = H1 ⊠ g.m_lin_var ⊠ g.W_MSG_vartoval # nvar x dim x heads

    
    # Target-Specific Aggregation TODO: start debugging from here
    if g.aggr=="sum"
        H_tilde_1 = reshape(permutedims(permutedims(attention_contovar, [1,3,2]) .* message_contovar,[2,3,1]),(nvar,n_channels)) .+ reshape(permutedims(permutedims(attention_valtovar, [1,3,2]) .* message_valtovar,[2,3,1]),(nvar,n_channels)) # nvar x n
        H_tilde_2 = reshape(permutedims(permutedims(attention_vartocon, [1,3,2]) .* message_vartocon,[2,3,1]),(ncon,n_channels))  # ncon x n
        H_tilde_3 = reshape(permutedims(permutedims(attention_vartoval, [1,3,2]) .* message_vartoval,[2,3,1]),(nval,n_channels)) # nval x n
    else
        error("Aggregation not implemented!")
    end
    return HeterogeneousFeaturedGraph(
            contovar,
            valtovar,
            a_lin_var.*σ(H_tilde_1) + H1, # nvar x n
            a_lin_con.*σ(H_tilde_2) + H2, # ncon x n
            a_lin_val.*σ(H_tilde_3) + H3, # nval x n
            fg.gf
        )
end
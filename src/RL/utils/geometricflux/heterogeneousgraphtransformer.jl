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
    a_lin_var = init(n_channels,n_channels)
    a_lin_con = init(n_channels,n_channels)
    a_lin_val = init(n_channels,n_channels)
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
    contovar, valtovar = fgs.contovar, fgs.valtovar # ncon x nvar x batch , nval x nvar x batch
    vartocon, vartoval = permutedims(contovar, [2, 1, 3]), permutedims(valtovar, [2, 1, 3]) # nvar x ncon x batch , nvar x nval x batch
    H1, H2, H3 = permutedims(fgs.varnf, [2,1,3]), permutedims(fgs.connf, [2,1,3]), permutedims(fgs.valnf, [2,1,3]) # nvar x n x batch, ncon x n x batch, nval x n x batch
    d = g.dim
    batch_size = size(contovar)[3]

    # Heterogeneous Mutual Attention
    k_var = cat([H1[:,:,i] ⊠ g.k_lin_var for i in 1:batch_size]..., dims=4) # nvar x dim x heads x batch
    k_con = cat([H2[:,:,i] ⊠ g.k_lin_con for i in 1:batch_size]..., dims=4) # ncon x dim x heads x batch
    k_val = cat([H3[:,:,i] ⊠ g.k_lin_val for i in 1:batch_size]..., dims=4) # nval x dim x heads x batch
    q_var = cat([H1[:,:,i] ⊠ g.k_lin_var for i in 1:batch_size]..., dims=4) # nvar x dim x heads x batch
    q_con = cat([H2[:,:,i] ⊠ g.k_lin_con for i in 1:batch_size]..., dims=4) # ncon x dim x heads x batch
    q_val = cat([H3[:,:,i] ⊠ g.k_lin_val for i in 1:batch_size]..., dims=4) # nval x dim x heads x batch
    
    # We compute these coefficients on each node pair
    ATT_head_contovar = cat([(k_con[:,:,:,i] ⊠ g.W_ATT_contovar ⊠ permutedims(q_var[:,:,:,i], [2,1,3])) .* (g.mu_contovar/sqrt(d)) for i in 1:batch_size]..., dims=4) # ncon x nvar x heads x batch
    ATT_head_vartocon = cat([(k_var[:,:,:,i] ⊠ g.W_ATT_vartocon ⊠ permutedims(q_con[:,:,:,i], [2,1,3])) .* (g.mu_vartocon/sqrt(d)) for i in 1:batch_size]..., dims=4) # nvar x ncon x heads x batch
    ATT_head_valtovar = cat([(k_val[:,:,:,i] ⊠ g.W_ATT_valtovar ⊠ permutedims(q_var[:,:,:,i], [2,1,3])) .* (g.mu_valtovar/sqrt(d)) for i in 1:batch_size]..., dims=4) # nval x nvar x heads x batch
    ATT_head_vartoval = cat([(k_var[:,:,:,i] ⊠ g.W_ATT_vartoval ⊠ permutedims(q_val[:,:,:,i], [2,1,3])) .* (g.mu_vartoval/sqrt(d)) for i in 1:batch_size]..., dims=4) # nvar x nval x heads x batch

    # We apply softmax only on neighbors
    nvar = size(contovar)[2]
    ncon = size(contovar)[1]
    nval = size(valtovar)[1]
    temp_attention_contovar = cat([(contovar[:,:,i] .+ zeros(ncon, nvar, g.heads)) .*  ATT_head_contovar[:,:,:,i] for i in 1:batch_size]..., dims=4) 
    temp_attention_vartocon = cat([(vartocon[:,:,i] .+ zeros(nvar, ncon, g.heads)) .*  ATT_head_vartocon[:,:,:,i] for i in 1:batch_size]..., dims=4)
    temp_attention_valtovar = cat([(valtovar[:,:,i] .+ zeros(nval, nvar, g.heads)) .*  ATT_head_valtovar[:,:,:,i] for i in 1:batch_size]..., dims=4)
    temp_attention_vartoval = cat([(vartoval[:,:,i] .+ zeros(nvar, nval, g.heads)) .*  ATT_head_vartoval[:,:,:,i] for i in 1:batch_size]..., dims=4)
    Zygote.ignore() do
        temp_attention_contovar = replace(temp_attention_contovar, 0.0 => -Inf)
        temp_attention_vartocon = replace(temp_attention_vartocon, 0.0 => -Inf)
        temp_attention_valtovar = replace(temp_attention_valtovar, 0.0 => -Inf)
        temp_attention_vartoval = replace(temp_attention_vartoval, 0.0 => -Inf)
    end
    attention_contovar = softmax(temp_attention_contovar; dims=2) # ncon x nvar x heads x batch
    attention_vartocon = softmax(temp_attention_vartocon; dims=2) # nvar x ncon x heads x batch
    attention_valtovar = softmax(temp_attention_valtovar; dims=2) # nval x nvar x heads x batch
    attention_vartoval = softmax(temp_attention_vartoval; dims=2) # nvar x nval x heads x batch
    Zygote.ignore() do
        attention_contovar = replace(attention_contovar, NaN => 0)
        attention_vartocon = replace(attention_vartocon, NaN => 0)
        attention_valtovar = replace(attention_valtovar, NaN => 0)
        attention_vartoval = replace(attention_vartoval, NaN => 0)
    end

    # Heterogeneous Message Passing
    message_contovar = cat([H2[:,:,i] ⊠ g.m_lin_con ⊠ g.W_MSG_contovar for i in 1:batch_size]..., dims=4) # ncon x dim x heads x batch
    message_vartocon = cat([H1[:,:,i] ⊠ g.m_lin_var ⊠ g.W_MSG_vartocon for i in 1:batch_size]..., dims=4) # nvar x dim x heads x batch
    message_valtovar = cat([H3[:,:,i] ⊠ g.m_lin_val ⊠ g.W_MSG_valtovar for i in 1:batch_size]..., dims=4) # nval x dim x heads x batch
    message_vartoval = cat([H1[:,:,i] ⊠ g.m_lin_var ⊠ g.W_MSG_vartoval for i in 1:batch_size]..., dims=4) # nvar x dim x heads x batch

    # Target-Specific Aggregation TODO: start debugging from here
    if g.aggr=="sum"
        H_tilde_1 = cat([reshape(permutedims(attention_contovar[:,:,:,i], [2,1,3]) ⊠ message_contovar[:,:,:,i],(nvar,g.n_channels)) .+ 
                    reshape(permutedims(attention_valtovar[:,:,:,i], [2,1,3]) ⊠ message_valtovar[:,:,:,i],(nvar,g.n_channels)) for i in 1:batch_size]..., dims=3) # nvar x n x batch
        H_tilde_2 = cat([reshape(permutedims(attention_vartocon[:,:,:,i], [2,1,3]) ⊠ message_vartocon[:,:,:,i],(ncon,g.n_channels)) for i in 1:batch_size]..., dims=3) # ncon x n x batch
        H_tilde_3 = cat([reshape(permutedims(attention_vartoval[:,:,:,i], [2,1,3]) ⊠ message_vartoval[:,:,:,i],(nval,g.n_channels)) for i in 1:batch_size]..., dims=3) # nval x n x batch
    else
        error("Aggregation not implemented!")
    end

    new_H1 = permutedims(σ.(H_tilde_1) ⊠ g.a_lin_var + H1,[2,1,3]) # n x nvar x batch
    new_H2 = permutedims(σ.(H_tilde_2) ⊠ g.a_lin_con + H2,[2,1,3]) # n x ncon x batch
    new_H3 = permutedims(σ.(H_tilde_3) ⊠ g.a_lin_val + H3,[2,1,3]) # n x nval x batch
    Zygote.ignore() do
        return BatchedHeterogeneousFeaturedGraph{Float32}(
                contovar,
                valtovar,
                new_H1,
                new_H2,
                new_H3,
                fgs.gf
            )
    end
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
    nvar = size(contovar)[2]
    ncon = size(contovar)[1]
    nval = size(valtovar)[1]
    mask_contovar = (contovar .+ zeros(ncon, nvar, g.heads))
    mask_vartocon = (vartocon .+ zeros(nvar, ncon, g.heads))
    mask_valtovar = (valtovar .+ zeros(nval, nvar, g.heads))
    mask_vartoval = (vartoval .+ zeros(nvar, nval, g.heads))
    
    temp_attention_contovar = (contovar .+ zeros(ncon, nvar, g.heads)) .*  ATT_head_contovar
    temp_attention_vartocon = (vartocon .+ zeros(nvar, ncon, g.heads)) .*  ATT_head_vartocon
    temp_attention_valtovar = (valtovar .+ zeros(nval, nvar, g.heads)) .*  ATT_head_valtovar
    temp_attention_vartoval = (vartoval .+ zeros(nvar, nval, g.heads)) .*  ATT_head_vartoval
    Zygote.ignore() do
        temp_attention_contovar = replace(temp_attention_contovar, 0.0 => -Inf)
        temp_attention_vartocon = replace(temp_attention_vartocon, 0.0 => -Inf)
        temp_attention_valtovar = replace(temp_attention_valtovar, 0.0 => -Inf)
        temp_attention_vartoval = replace(temp_attention_vartoval, 0.0 => -Inf)
    end
    attention_contovar = softmax(temp_attention_contovar; dims=2) # ncon x nvar x heads
    attention_vartocon = softmax(temp_attention_vartocon; dims=2) # nvar x ncon x heads
    attention_valtovar = softmax(temp_attention_valtovar; dims=2) # nval x nvar x heads
    attention_vartoval = softmax(temp_attention_vartoval; dims=2) # nvar x nval x heads
    
    Zygote.ignore() do
        attention_contovar = replace(attention_contovar, NaN => 0)
        attention_vartocon = replace(attention_vartocon, NaN => 0)
        attention_valtovar = replace(attention_valtovar, NaN => 0)
        attention_vartoval = replace(attention_vartoval, NaN => 0)
    end

    # Heterogeneous Message Passing
    message_contovar = H2 ⊠ g.m_lin_con ⊠ g.W_MSG_contovar # ncon x dim x heads
    message_vartocon = H1 ⊠ g.m_lin_var ⊠ g.W_MSG_vartocon # nvar x dim x heads
    message_valtovar = H3 ⊠ g.m_lin_val ⊠ g.W_MSG_valtovar # nval x dim x heads
    message_vartoval = H1 ⊠ g.m_lin_var ⊠ g.W_MSG_vartoval # nvar x dim x heads

    # Target-Specific Aggregation TODO: start debugging from here
    if g.aggr=="sum"
        H_tilde_1 = reshape(permutedims(attention_contovar, [2,1,3]) ⊠ message_contovar,(nvar,g.n_channels)) .+ 
                    reshape(permutedims(attention_valtovar, [2,1,3]) ⊠ message_valtovar,(nvar,g.n_channels)) # nvar x n
        H_tilde_2 = reshape(permutedims(attention_vartocon, [2,1,3]) ⊠ message_vartocon,(ncon,g.n_channels)) # ncon x n
        H_tilde_3 = reshape(permutedims(attention_vartoval, [2,1,3]) ⊠ message_vartoval,(nval,g.n_channels)) # nval x n
    else
        error("Aggregation not implemented!")
    end

    return HeterogeneousFeaturedGraph(
            contovar,
            valtovar,
            transpose(σ.(H_tilde_1) * g.a_lin_var + H1), # n x nvar
            transpose(σ.(H_tilde_2) * g.a_lin_con + H2), # n x ncon
            transpose(σ.(H_tilde_3) * g.a_lin_val + H3), # n x nval
            fg.gf
        )
end
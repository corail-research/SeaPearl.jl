struct HeterogeneousGraphTransformer{A:AbstractMatrix}
    n_channels:: Int
    heads:: Int
    aggr:: String
    dim::Int
    k_lin_var::A
    k_lin_con::A
    k_lin_val::A
    q_lin_var::A
    q_lin_con::A
    q_lin_val::A
    m_lin_var::A
    m_lin_con::A
    m_lin_val::A
    a_lin_var::A
    a_lin_con::A
    a_lin_val::A
    σ
    W_MSG_contovar::A
    W_MSG_vartocon::A
    W_MSG_valtovar::A
    W_MSG_vartoval::A
    W_ATT_contovar::A
    W_ATT_vartocon::A
    W_ATT_valtovar::A
    W_ATT_vartoval::A
    mu_contovar
    mu_vartocon
    mu_valtovar
    mu_vartoval
end
# Constructor
function HeterogeneousGraphTransformer(n_channels::Int, heads::Int; init=Flux.glorot_uniform, aggr="sum", σ=Flux.leakyrelu)
    @assert n_channels%heads==0
    dim = n_channels//heads
    k_lin_var = init(heads,n_channels,dim)
    k_lin_con = init(heads,n_channels,dim)
    k_lin_val = init(heads,n_channels,dim)
    q_lin_var = init(heads,n_channels,dim)
    q_lin_con = init(heads,n_channels,dim)
    q_lin_val = init(heads,n_channels,dim)
    m_lin_var = init(heads,n_channels,dim)
    m_lin_con = init(heads,n_channels,dim)
    m_lin_val = init(heads,n_channels,dim)
    a_lin_var = init(heads,n_channels,n_channels)
    a_lin_con = init(heads,n_channels,n_channels)
    a_lin_val = init(heads,n_channels,n_channels)
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
    H1, H2, H3 = fg.varnf, fg.connf, fg.valnf
    d = self.dim

    # Heterogeneous Mutual Attention
    k_var = self.k_lin_var.*H1 # heads x nvar x dim
    k_con = self.k_lin_con.*H2 # heads x ncon x dim
    k_val = self.k_lin_val.*H3 # heads x nval x dim
    q_var = self.q_lin_var.*H1 # heads x nvar x dim
    q_con = self.q_lin_con.*H2 # heads x ncon x dim
    q_val = self.q_lin_val.*H3 # heads x nval x dim

    # We compute these coefficients on each node pair
    ATT_head_contovar = (k_con .* self.W_ATT_contovar .* permutedims(q_var, [1,3,2])) .* (self.mu_contovar/sqrt(d)) # heads x ncon x nvar
    ATT_head_vartocon = (k_var .* self.W_ATT_vartocon .* permutedims(q_con, [1,3,2])) .* (self.mu_vartocon/sqrt(d)) # heads x nvar x ncon
    ATT_head_valtovar = (k_val .* self.W_ATT_valtovar .* permutedims(q_var, [1,3,2])) .* (self.mu_valtovar/sqrt(d)) # heads x nval x nvar
    ATT_head_vartoval = (k_var .* self.W_ATT_vartoval .* permutedims(q_val, [1,3,2])) .* (self.mu_vartoval/sqrt(d)) # heads x nvar x nval

    # We apply softmax only on neighbors
    @assert prod(ATT_head_contovar)!=0
    @assert prod(ATT_head_vartocon)!=0
    @assert prod(ATT_head_valtovar)!=0
    @assert prod(ATT_head_vartoval)!=0
    attention_contovar = softmax(replace((contovar .+ zeros(heads)) .*  ATT_head_contovar, 0.0 => -Inf); dims=3) # heads x ncon x nvar
    attention_vartocon = softmax(replace((vartocon .+ zeros(heads)) .*  ATT_head_vartocon, 0.0 => -Inf); dims=3) # heads x nvar x ncon
    attention_valtovar = softmax(replace((valtovar .+ zeros(heads)) .*  ATT_head_valtovar, 0.0 => -Inf); dims=3) # heads x nval x nvar
    attention_vartoval = softmax(replace((vartoval .+ zeros(heads)) .*  ATT_head_vartoval, 0.0 => -Inf); dims=3) # heads x nvar x nval

    # Heterogeneous Message Passing
    message_contovar = self.m_lin_con(H2) .* self.W_MSG_contovar # heads x ncon x dim
    message_vartocon = self.m_lin_var(H1) .* self.W_MSG_vartocon # heads x nvar x dim
    message_valtovar = self.m_lin_val(H3) .* self.W_MSG_valtovar # heads x nval x dim
    message_vartoval = self.m_lin_var(H1) .* self.W_MSG_vartoval # heads x nvar x dim

    nvar = size(contovar)[2]
    ncon = size(contovar)[1]
    nval = size(valtovar)[1]
    # Target-Specific Aggregation
    if self.aggr=="sum"
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
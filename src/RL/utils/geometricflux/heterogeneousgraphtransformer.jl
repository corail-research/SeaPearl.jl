struct HeterogeneousGraphTransformer{A:AbstractMatrix}
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
function HeterogeneousGraphTransformer(in_channels::Int, out_channels::Int, heads::Int)
    @assert out_channels%heads==0
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
    k_var = self.k_lin_var(H1)
    k_con = self.k_lin_con(H2)
    k_val = self.k_lin_val(H3)
    q_var = self.q_lin_var(H1)
    q_con = self.q_lin_con(H2)
    q_val = self.q_lin_val(H3)

    # TODO: modify that to compute only required edges
    ATT_head_contovar = (k_con * self.W_ATT_contovar * transpose(q_var)) * (self.mu_contovar/sqrt(d))
    ATT_head_vartocon = (k_var * self.W_ATT_vartocon * transpose(q_con)) * (self.mu_vartocon/sqrt(d))
    ATT_head_valtovar = (k_val * self.W_ATT_valtovar * transpose(q_var)) * (self.mu_valtovar/sqrt(d))
    ATT_head_vartoval = (k_var * self.W_ATT_vartoval * transpose(q_val)) * (self.mu_vartoval/sqrt(d))

    # TODO: compute the softmax only on the neighbors
    attention_contovar = softmax(vcat(ATT_head_contovar); dims=2)
    attention_vartocon = softmax(vcat(ATT_head_vartocon); dims=2)
    attention_valtovar = softmax(vcat(ATT_head_valtovar); dims=2)
    attention_vartoval = softmax(vcat(ATT_head_vartoval); dims=2)

    # Heterogeneous Message Passing
    MSG_head_contovar = self.m_lin_con(H2) * self.W_MSG_contovar
    MSG_head_vartocon = self.m_lin_var(H1) * self.W_MSG_vartocon
    MSG_head_valtovar = self.m_lin_val(H3) * self.W_MSG_valtovar
    MSG_head_vartoval = self.m_lin_var(H1) * self.W_MSG_vartoval

    message_contovar = vcat(MSG_head_contovar)
    message_vartocon = vcat(MSG_head_vartocon)
    message_valtovar = vcat(MSG_head_valtovar)
    message_vartoval = vcat(MSG_head_vartoval)

    # Target-Specific Aggregation
    if self.aggr=="sum"
        H_tilde_1 = (attention_contovar .* message_contovar) * contovar + (attention_valtovar .* message_valtovar) * valtovar
        H_tilde_2 = (attention_vartocon .* message_vartocon) * vartocon
        H_tilde_3 = (attention_vartoval .* message_vartoval) * vartoval
    else
        error("Aggregation not implemented!")
    end
    return HeterogeneousFeaturedGraph(
            contovar,
            valtovar,
            a_lin_var(σ(H_tilde_1)) + H1,
            a_lin_con(σ(H_tilde_2)) + H2,
            a_lin_val(σ(H_tilde_3)) + H3,
            fg.gf
        )
end
using Distributions: Categorical

abstract type AbstractCPEnv{TS <: AbstractTrajectoryState} <: AbstractEnv end

struct CPEnv{TS} <: AbstractCPEnv{TS}
    reward::Float32
    terminal::Bool
    state::TS
    actions_index::Vector{Int}
    legal_actions::Vector{Int}
    legal_actions_mask::Vector{Bool}
end

RLBase.action_space(env::CPEnv) = env.actions_index
RLBase.legal_action_space(env::CPEnv) = env.legal_actions
RLBase.legal_action_space_mask(env::CPEnv) = env.legal_actions_mask
RLBase.reward(env::CPEnv) = env.reward
RLBase.is_terminated(env::CPEnv) = env.terminal
RLBase.state(env::CPEnv) = env.state
RLBase.ActionStyle(::CPEnv) = FULL_ACTION_SET
RLBase.state_space(::SeaPearl.CPEnv, ::Observation{Any}, ::DefaultPlayer) = nothing

struct unmaskedCPEnv{TS} <: AbstractCPEnv{TS}
    reward::Float32
    terminal::Bool
    state::TS
    actions_index::Array{Int64, 1}
end

RLBase.action_space(env::unmaskedCPEnv) = env.actions_index
RLBase.reward(env::unmaskedCPEnv) = env.reward
RLBase.is_terminated(env::unmaskedCPEnv) = env.terminal
RLBase.state(env::unmaskedCPEnv) = env.state
RLBase.ActionStyle(::unmaskedCPEnv) = MINIMAL_ACTION_SET
RLBase.state_space(::unmaskedCPEnv, ::Observation{Any}, ::DefaultPlayer) = nothing

function (learner::DQNLearner)(env::AbstractCPEnv{TS}) where {TS <: NonTabularTrajectoryState}
    env |>
    state |>
    x ->
        send_to_device(device(learner), x) |>
        learner.approximator |>
        vec |>
        send_to_host
end

function (learner::A2CLearner)(env::AbstractCPEnv{ST}) where {ST <: NonTabularTrajectoryState}
    env |>
    state |>
    x ->
        send_to_device(device(learner), x) |>
        learner.approximator.actor |>
        vec |>
        send_to_host
end

function Array(state::T) where {T<:NonTabularTrajectoryState}
    state
end

### PPO 

(p::PPOPolicy)(env::AbstractCPEnv{ST}) where {ST <: NonTabularTrajectoryState} = rand.(p.rng, prob(p, env))[1]

function RLBase.prob(p::PPOPolicy, env::AbstractCPEnv{ST}) where {ST <: NonTabularTrajectoryState}
    s = state(env)
    mask =  ActionStyle(env) === FULL_ACTION_SET ? legal_action_space_mask(env) : nothing
    prob(p, s, mask)
end

function RLBase.prob(p::PPOPolicy{<:ActorCritic,Categorical}, state::GraphTrajectoryState, mask)
    logits = p.approximator.actor(send_to_device(device(p.approximator), state))
    if !isnothing(mask)
        logits .+= ifelse.(mask, 0f0, typemin(Float32))
    end
    logits = logits |> softmax |> send_to_host
    if p.update_step < p.n_random_start
        [
            Categorical(fill(1 / length(x), length(x)); check_args = false) for
            x in eachcol(logits)
        ]
    else
        [Categorical(x; check_args = false) for x in eachcol(logits)]
    end
end


function RLCore.update!(
    p::PPOPolicy,
    t::Union{PPOTrajectory,MaskedPPOTrajectory},
    ::AbstractEnv,
    ::PreActStage,
)
    length(t) == 0 && return  # in the first update, only state & action are inserted into trajectory
    p.update_step += 1
    if p.update_step % p.update_freq == 0
        _update!(p, t)
    end
end

function _update!(p::PPOPolicy, t::AbstractTrajectory)
    rng = p.rng
    AC = p.approximator
    γ = p.γ
    λ = p.λ
    n_epochs = p.n_epochs
    n_microbatches = p.n_microbatches
    clip_range = p.clip_range
    w₁ = p.actor_loss_weight
    w₂ = p.critic_loss_weight
    w₃ = p.entropy_loss_weight
    D = device(AC)
    to_device(x) = send_to_device(D, x)

    n_envs, n_rollout = size(t[:terminal])
    @assert n_envs * n_rollout % n_microbatches == 0 "size mismatch"
    microbatch_size = n_envs * n_rollout ÷ n_microbatches

    n = length(t)
    states_plus = to_device(t[:state])

    if t isa MaskedPPOTrajectory
        LAM = to_device(t[:legal_actions_mask])
    end

    states_flatten_on_host = flatten_batch(select_last_dim(t[:state], 1:n))
    states_plus_values =
        reshape(send_to_host(AC.critic(flatten_batch(states_plus))), n_envs, :)

    # TODO: make generalized_advantage_estimation GPU friendly
    advantages = generalized_advantage_estimation(
        t[:reward],
        states_plus_values,
        γ,
        λ;
        dims = 2,
        terminal = t[:terminal],
    )
    returns = to_device(advantages .+ select_last_dim(states_plus_values, 1:n_rollout))
    advantages = to_device(advantages)

    actions_flatten = flatten_batch(select_last_dim(t[:action], 1:n))
    action_log_probs = select_last_dim(to_device(t[:action_log_prob]), 1:n)

    # TODO: normalize advantage
    for epoch in 1:n_epochs
        rand_inds = shuffle!(rng, Vector(1:n_envs*n_rollout))
        for i in 1:n_microbatches
            inds = rand_inds[(i-1)*microbatch_size+1:i*microbatch_size]
            if t isa MaskedPPOTrajectory
                # lam = select_last_dim(flatten_batch(select_last_dim(LAM, 2:n+1)),inds,)

                ### LEGAL ACTION MASK CORRECTION
                lam = select_last_dim(select_last_dim(LAM, 2:n+1), inds)
                ###
            else
                lam = nothing
            end

            # s = to_device(select_last_dim(states_flatten_on_host, inds))
            # !!! we need to convert it into a continuous CuArray otherwise CUDA.jl will complain scalar indexing
            s = to_device(collect(select_last_dim(states_flatten_on_host, inds)))
            a = to_device(collect(select_last_dim(actions_flatten, inds)))

            if eltype(a) === Int
                a = CartesianIndex.(a, 1:length(a))
            end

            r = vec(returns)[inds]
            log_p = vec(action_log_probs)[inds]
            adv = vec(advantages)[inds]

            ps = Flux.params(AC)
            gs = gradient(ps) do
                v′ = AC.critic(s) |> vec
                if AC.actor isa GaussianNetwork
                    μ, σ = AC.actor(s)
                    if ndims(a) == 2
                        log_p′ₐ = vec(sum(normlogpdf(μ, σ, a), dims=1))
                    else
                        log_p′ₐ = normlogpdf(μ, σ, a)
                    end
                    entropy_loss =
                        mean(size(σ, 1) * (log(2.0f0π) + 1) .+ sum(log.(σ); dims=1)) / 2
                else
                    # actor is assumed to return discrete logits
                    raw_logit′ = AC.actor(s)
                    if isnothing(lam)
                        logit′ = raw_logit′
                    else
                        logit′ = raw_logit′ .+ ifelse.(lam, 0.0f0, typemin(Float32))
                    end
                    p′ = softmax(logit′)
                    log_p′ = logsoftmax(logit′)
                    log_p′ₐ = log_p′[a]
                    # entropy_loss = -sum(p′ .* log_p′) * 1 // size(p′, 2)  
                    
                    ### ENTROPY LOSS CORRECTION
                    sum_p_logp = 0.0
                    for (i,val) in enumerate(p′)
                        if val != 0
                            sum_p_logp += val * log_p′[i]
                        end
                    end
                    entropy_loss = -sum_p_logp * 1 // size(p′, 2)
                    ###
                end

                ratio = exp.(log_p′ₐ .- log_p)
                surr1 = ratio .* adv
                surr2 = clamp.(ratio, 1.0f0 - clip_range, 1.0f0 + clip_range) .* adv

                actor_loss = -mean(min.(surr1, surr2))
                critic_loss = mean((r .- v′) .^ 2)
                loss = w₁ * actor_loss + w₂ * critic_loss - w₃ * entropy_loss

                ignore_derivatives() do
                    p.actor_loss[i, epoch] = actor_loss
                    p.critic_loss[i, epoch] = critic_loss
                    p.entropy_loss[i, epoch] = entropy_loss
                    p.loss[i, epoch] = loss
                end

                loss
            end

            p.norm[i, epoch] = clip_by_global_norm!(gs, ps, p.max_grad_norm)
            RLCore.update!(AC, gs)
        end
    end
end

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

using CPRL
using ReinforcementLearning
using Flux
using Statistics

using Plots
gr()

const RL = ReinforcementLearning

TYPE = Float64
NB_EPISODE = 50

#env = RL.CartPoleEnv(;T=Float32, seed=11)
env = MountainCarEnv(; T = TYPE, max_steps = 5000, seed=21)

# get problem parameters for state and action
ns, na = length(rand(RL.get_observation_space(env))), length(RL.get_action_space(env))

hidden_size = 16

"""
# creating my own hook to render the MountainCarEnv
function f(t, agent, env::RL.MountainCarEnv, obs)
    RL.render(env)
end

mutable struct DoEveryNStep{F} <: AbstractHook
    f::F
    n::Int
    t::Int
end

function (hook::DoEveryNStep)(::PostActStage, agent, env, obs)
    hook.t += 1
    if hook.t % hook.n == 0
        hook.f(hook.t, agent, env, obs)
    end
end

renderHook() = DoEveryNStep(f, 1, 0)
"""


@inline function _buffer_frame(cb::CircularArrayBuffer, i::Int)
    n = capacity(cb)
    idx = cb.first + i - 1
    if idx > n
        idx - n
    else
        idx
    end
end

_buffer_frame(cb::CircularArrayBuffer, I::Vector{Int}) = map(i -> _buffer_frame(cb, i), I)

function RL.update!(cb::CircularArrayBuffer{T,N}, data::AbstractArray) where {T,N}
    select_last_dim(cb.buffer, _buffer_frame(cb, cb.length)) .= data
    cb
end


# create a smart agent 
smart_agent = CPRL.BasicDQNAgent(ns, na, hidden_size; γ = 0.95f0, capacity = 50000, decay_steps = 5000, state_type = TYPE, reward_type = TYPE)
hook1 = RL.ComposedHook(RL.TotalRewardPerEpisode(), RL.TimePerStep())

# create a smart agent 
very_smart_agent = CPRL.DQNAgent(ns, na, hidden_size; γ = 0.95f0, capacity = 50000, decay_steps = 5000, state_type = TYPE, reward_type = TYPE)
hook2 = RL.ComposedHook(RL.TotalRewardPerEpisode(), RL.TimePerStep())


# create a random agent (for comparison)
random_agent = CPRL.RandomAgent(env, ns)
hook3 = RL.ComposedHook(RL.TotalRewardPerEpisode(), RL.TimePerStep())

# run an experiment with a stop condition
run(smart_agent, env, RL.StopAfterEpisode(NB_EPISODE), hook1)
@info "Stats for BasicDQNAgent" avg_reward = mean(hook1[1].rewards) avg_last_rewards = mean(hook1[1].rewards[end-min(NB_EPISODE-1, 10):end]) avg_fps = 1 / mean(hook1[2].times)

run(very_smart_agent, env, RL.StopAfterEpisode(NB_EPISODE), hook2)
@info "Stats for DQNAgent" avg_reward = mean(hook2[1].rewards) avg_last_rewards = mean(hook2[1].rewards[end-min(NB_EPISODE-1, 10):end]) avg_fps = 1 / mean(hook2[2].times)

run(random_agent, env, RL.StopAfterEpisode(NB_EPISODE), hook3)
@info "Stats for RandomAgent" avg_reward = mean(hook3[1].rewards) avg_last_rewards = mean(hook3[1].rewards[end-min(NB_EPISODE-1, 10):end]) avg_fps = 1 / mean(hook3[2].times)


# plot 
x = 1:length(hook1[1].rewards)

p = plot(x, hook1[1].rewards, xlabel="Episode", ylabel="Reward")
plot!(p, x, hook2[1].rewards)
plot!(p, x, hook3[1].rewards)
display(p)
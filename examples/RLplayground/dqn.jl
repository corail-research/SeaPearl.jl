using CPRL
using ReinforcementLearning
using Flux
using Statistics

using Plots
gr()

const RL = ReinforcementLearning

env = RL.CartPoleEnv(;T=Float32, seed=11)
#env = MountainCarEnv(; max_steps = 500, seed=21)

# get problem parameters for state and action
ns, na = length(rand(RL.get_observation_space(env))), length(RL.get_action_space(env))

hidden_size = 32

# create an agent 
smart_agent = CPRL.BasicDQNAgent(ns, na, hidden_size)
hook1 = RL.ComposedHook(RL.TotalRewardPerEpisode(), RL.TimePerStep())

# create a random agent (for comparison)
random_agent = CPRL.RandomAgent(env, ns)
hook2 = RL.ComposedHook(RL.TotalRewardPerEpisode(), RL.TimePerStep())

# run an experiment with a stop condition
run(smart_agent, env, RL.StopAfterEpisode(200), hook1)
@info "Stats for BasicDQNAgent" avg_reward = mean(hook1[1].rewards) avg_last_rewards = mean(hook1[1].rewards[end-10:end]) avg_fps = 1 / mean(hook1[2].times)

run(random_agent, env, RL.StopAfterEpisode(200), hook2)
@info "Stats for RandomAgent" avg_reward = mean(hook2[1].rewards) avg_last_rewards = mean(hook2[1].rewards[end-10:end]) avg_fps = 1 / mean(hook2[2].times)

# plot 
x = 1:length(hook1[1].rewards)

p = plot(x, hook1[1].rewards, xlabel="Episode", ylabel="Reward")
plot!(p, x, hook2[1].rewards)
display(p)
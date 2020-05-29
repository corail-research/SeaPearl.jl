using CPRL
using ReinforcementLearning
using Flux
using Statistics

using Plots
gr()

const RL = ReinforcementLearning

env = CartPoleEnv(;T=Float32, seed=11)
#env = MountainCarEnv(; max_steps = 500, seed=21)

# get problem parameters for state and action
ns, na = length(rand(get_observation_space(env))), length(get_action_space(env))

hidden_size = 32

# create an agent 
smart_agent = CPRL.BasicDQNAgent(ns, ns, hidden_size)

# compare with a random agent
random_agent = Agent(
    policy = RandomPolicy(env; seed=456),
    trajectory = CircularCompactSARTSATrajectory(; capacity=3, state_type=Float32, state_size = (4,)),
)
hook = ComposedHook(TotalRewardPerEpisode(), TimePerStep())
run(random_agent, env, StopAfterEpisode(200), hook)
@info "Stats for RandomAgent" avg_reward = mean(hook[1].rewards) avg_last_rewards = mean(hook[1].rewards[end-10:end]) avg_fps = 1 / mean(hook[2].times)


# create an hook
hook = ComposedHook(TotalRewardPerEpisode(), TimePerStep())

# run an experiment with a stop condition
run(smart_agent, env, StopAfterEpisode(200), hook)
@info "Stats for BasicDQNAgent" avg_reward = mean(hook[1].rewards) avg_last_rewards = mean(hook[1].rewards[end-10:end]) avg_fps = 1 / mean(hook[2].times)


p = plot(1:length(hook[1].rewards), hook[1].rewards, xlabel="Episode", ylabel="Reward")
display(p)
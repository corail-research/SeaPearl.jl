using CPRL
using ReinforcementLearning
using Flux
using Statistics

using Plots
gr()

const RL = ReinforcementLearning

MountainC_PARAMS = Dict(
    "type" => Float64,
    "max_steps" => 5000,
    "nb_episode" => 20,
    "hidden_size" => 16,
    "optimizer" => ADAM,
    "η" => 0.001,
    "target_update_freq" => 100,
    "γ" => 0.95f0,
    "capacity" => 50000,
    "decay_steps" => 5000
)

CartP_PARAMS = Dict(
    "type" => Float32,
    "max_steps" => 200,
    "nb_episode" => 800,
    "hidden_size" => 12,
    "optimizer" => RMSProp,
    "η" => 0.0001,
    "target_update_freq" => 500,
    "γ" => 1.0f0,
    "capacity" => 2000,
    "decay_steps" => 500
)

if true
    PARAMS = CartP_PARAMS
    env = RL.CartPoleEnv(; T = PARAMS["type"], max_steps = PARAMS["max_steps"], seed=11)
else
    PARAMS = MountainC_PARAMS
    env = RL.MountainCarEnv(; T = PARAMS["type"], max_steps = PARAMS["max_steps"], seed=21)
end

# get problem parameters for state and action
ns, na = length(rand(RL.get_observation_space(env))), length(RL.get_action_space(env))

# create a smart agent 
smart_agent = CPRL.BasicDQNAgent(ns, na, PARAMS["hidden_size"]; γ = PARAMS["γ"], capacity = PARAMS["capacity"], decay_steps = PARAMS["decay_steps"], state_type = PARAMS["type"], reward_type = PARAMS["type"])
hook1 = RL.ComposedHook(RL.TotalRewardPerEpisode(), RL.TimePerStep())

# create a smart agent 
very_smart_agent = CPRL.DQNAgent(ns, na, PARAMS["hidden_size"]; optimizer = PARAMS["optimizer"], η = PARAMS["η"], target_update_freq = PARAMS["target_update_freq"], γ = PARAMS["γ"], capacity = PARAMS["capacity"], decay_steps = PARAMS["decay_steps"], state_type = PARAMS["type"], reward_type = PARAMS["type"])
"""
nn_model = Chain(
    Dense(ns, PARAMS["hidden_size"], relu; initW = seed_glorot_uniform(seed = 17)),
    Dense(PARAMS["hidden_size"], PARAMS["hidden_size"], relu; initW = seed_glorot_uniform(seed = 23)), 
    Dense(PARAMS["hidden_size"], na; initW = seed_glorot_uniform(seed = 39))
)

very_smart_agent = CPRL.DQNAgent(
    nn_model = nn_model,
    state_size = (ns,),
    optimizer = PARAMS["optimizer"], η = PARAMS["η"], target_update_freq = PARAMS["target_update_freq"], γ = PARAMS["γ"], capacity = PARAMS["capacity"], 
    decay_steps = PARAMS["decay_steps"], state_type = PARAMS["type"], reward_type = PARAMS["type"]
)
"""

hook2 = RL.ComposedHook(RL.TotalRewardPerEpisode(), RL.TimePerStep())


# create a random agent (for comparison)
random_agent = CPRL.RandomAgent(env, ns)
hook3 = RL.ComposedHook(RL.TotalRewardPerEpisode(), RL.TimePerStep())

# run an experiment with a stop condition
run(smart_agent, env, RL.StopAfterEpisode(PARAMS["nb_episode"]), hook1)
@info "Stats for BasicDQNAgent" avg_reward = mean(hook1[1].rewards) avg_last_rewards = mean(hook1[1].rewards[end-min(PARAMS["nb_episode"]-1, 10):end]) avg_fps = 1 / mean(hook1[2].times)

run(very_smart_agent, env, RL.StopAfterEpisode(PARAMS["nb_episode"]), hook2)
@info "Stats for DQNAgent" avg_reward = mean(hook2[1].rewards) avg_last_rewards = mean(hook2[1].rewards[end-min(PARAMS["nb_episode"]-1, 10):end]) avg_fps = 1 / mean(hook2[2].times)

run(random_agent, env, RL.StopAfterEpisode(PARAMS["nb_episode"]), hook3)
@info "Stats for RandomAgent" avg_reward = mean(hook3[1].rewards) avg_last_rewards = mean(hook3[1].rewards[end-min(PARAMS["nb_episode"]-1, 10):end]) avg_fps = 1 / mean(hook3[2].times)


# plot 
x = 1:length(hook2[1].rewards)

p = plot(x, hook1[1].rewards, xlabel="Episode", ylabel="Reward")
plot!(p, x, hook2[1].rewards)
plot!(p, x, hook3[1].rewards)
display(p)
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


agent = Agent(
    policy = QBasedPolicy(
        learner = BasicDQNLearner(
            approximator = NeuralNetworkApproximator(
                model = Chain(
                    Dense(ns, hidden_size, relu; initW = seed_glorot_uniform(seed = 17)),
                    Dense(hidden_size, hidden_size, relu; initW = seed_glorot_uniform(seed = 23)), 
                    Dense(hidden_size, na; initW = seed_glorot_uniform(seed = 39))
                ),
                optimizer = ADAM()
            ),
            batch_size = 32,
            min_replay_history = 100,
            loss_func = huber_loss,
            seed = 22,
        ), 
        explorer = EpsilonGreedyExplorer(
            kind = :exp,
            ϵ_stable = 0.01,
            decay_steps = 500,
            seed = 33
        )
    ),
    trajectory = CircularCompactSARTSATrajectory(
        capacity = 1000, 
        state_type = Float32,
        #state_type = Float64, 
        state_size = (ns,)
    )
)

hook = ComposedHook(TotalRewardPerEpisode(), TimePerStep())

run(agent, env, StopAfterEpisode(200), hook)

@info "Stats for BasicDQNLearner" avg_reward = mean(hook[1].rewards) avg_fps = 1 / mean(hook[2].times)

p = plot(1:length(hook[1].rewards), hook[1].rewards, xlabel="Episode", ylabel="Reward")
display(p)
"""
    BasicDQNAgent(state_space_size, action_space_size, hidden_size = 32; 
                optimizer = ADAM(), 
                batch_size = 32, min_replay_history = 100, loss_func = huber_loss, learner_seed = 22,
                kind = :exp, ϵ_stable = 0.01, decay_steps = 500, explorer_seed = 33,
                capacity = 1000, state_type = Float32, state_size = (state_space_size,)
                )

Using the structure of ReinforcementLearning.jl agents. This is the structure of a basic 
DQN agent (the one from Playing Atari - Google Deep Mind). This function give the possibility 
to parametrize this agent without having to think about the entire structure. 
If user, wants to go further, he can create its own agent. 
"""
function BasicDQNAgent(state_space_size, action_space_size, hidden_size = 32; 
                        optimizer = ADAM, 
                        batch_size = 32, min_replay_history = 100, loss_func = huber_loss, learner_seed = 22,
                        kind = :exp, ϵ_stable = 0.01, decay_steps = 500, explorer_seed = 33,
                        capacity = 1000, state_type = Float32, state_size = (state_space_size,)
                        )
    # function
    agent = RL.Agent(
        policy = RL.QBasedPolicy(
            learner = RL.BasicDQNLearner(
                approximator = RL.NeuralNetworkApproximator(
                    model = Chain(
                        Dense(state_space_size, hidden_size, relu; initW = seed_glorot_uniform(seed = 17)),
                        Dense(hidden_size, hidden_size, relu; initW = seed_glorot_uniform(seed = 23)), 
                        Dense(hidden_size, action_space_size; initW = seed_glorot_uniform(seed = 39))
                    ),
                    optimizer = optimizer()
                ),
                batch_size = batch_size,
                min_replay_history = min_replay_history,
                loss_func = loss_func,
                seed = learner_seed,
            ), 
            explorer = RL.EpsilonGreedyExplorer(
                kind = kind,
                ϵ_stable = ϵ_stable,
                decay_steps = decay_steps,
                seed = explorer_seed
            )
        ),
        trajectory = RL.CircularCompactSARTSATrajectory(
            capacity = capacity, 
            state_type = state_type, 
            state_size = state_size
        )
    )
    return agent
end
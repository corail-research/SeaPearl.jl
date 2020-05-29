function BasicDQNAgent()
    agent = RL.Agent(
        policy = RL.QBasedPolicy(
            learner = RL.BasicDQNLearner(
                approximator = RL.NeuralNetworkApproximator(
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
            explorer = RL.EpsilonGreedyExplorer(
                kind = :exp,
                ϵ_stable = 0.01,
                decay_steps = 500,
                seed = 33
            )
        ),
        trajectory = RL.CircularCompactSARTSATrajectory(
            capacity = 1000, 
            #state_type = Float32,
            state_type = Float64, 
            state_size = (ns,)
        )
    )
    return agent
end
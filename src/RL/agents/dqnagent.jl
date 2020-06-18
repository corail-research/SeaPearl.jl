"""
    DQNAgent(state_space_size, action_space_size, hidden_size = 32; 
            optimizer = ADAM, 
            loss_func = huber_loss, stack_size = nothing, γ = 0.99f0, batch_size = 32, update_horizon = 1, min_replay_history = 100, update_freq = 1, target_update_freq = 100, update_step = 0, learner_seed = 22,
            kind = :exp, ϵ_stable = 0.01, decay_steps = 500, explorer_seed = 33,
            capacity = 1000, state_type = Float32, state_size = (state_space_size,), reward_type = Float32
    )

This is a standard DQN Agent with an epsilon greed explorer and circular compact sarsat trajectory.

Using the structure of ReinforcementLearning.jl agents. This is the structure of a 
DQN agent (the one from Human-level control through deep reinforcement learning - Google Deep Mind). This function give the possibility 
to parametrize this agent without having to think about the entire structure. 
If user, wants to go further, he can create its own agent. 
"""
function DQNAgent(; 
            nn_model,
            optimizer = ADAM, η = 0.001,
            loss_func = huber_loss, stack_size = nothing, γ = 0.99f0, batch_size = 32, update_horizon = 1, min_replay_history = 0, update_freq = 1, target_update_freq = 100, learner_seed = 22,
            kind = :exp, ϵ_stable = 0.01, decay_steps = 500, explorer_seed = 33,
            capacity = 1000, state_type = Float32, state_size = (1,), action_type = Int64, action_size = (), reward_type = Float32, reward_size = (), terminal_type = Bool, terminal_size = ()
        )
    # function
    agent = RL.Agent(
        policy = RL.QBasedPolicy(
            learner = RL.DQNLearner(
                approximator = RL.NeuralNetworkApproximator(
                    model = nn_model,
                    optimizer = optimizer(η)
                ),
                target_approximator = RL.NeuralNetworkApproximator(
                    model = nn_model,
                    optimizer = optimizer(η)
                ),
                loss_func = loss_func,
                stack_size = stack_size,
                γ = γ,
                batch_size = batch_size,
                update_horizon = update_horizon,
                min_replay_history = min_replay_history,
                update_freq = update_freq,
                target_update_freq = target_update_freq,
                seed = learner_seed,
            ), 
            explorer = RL.EpsilonGreedyExplorer(
                ϵ_stable = ϵ_stable,
                kind = kind,
                ϵ_init = 1.0,
                warmup_steps = 0,
                decay_steps = decay_steps,
                step = 1,
                is_break_tie = false, 
                #is_training = true,
                seed = explorer_seed
            )
        ),
        trajectory = RL.CircularCompactSARTSATrajectory(
            capacity = capacity, 
            state_type = state_type, 
            state_size = state_size,
            action_type = Int,
            action_size = (),
            reward_type = reward_type,
            reward_size = (),
            terminal_type = Bool,
            terminal_size = ()
        ),
        role = :DEFAULT_PLAYER
    )
    return agent
end
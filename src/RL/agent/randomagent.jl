"""
    RandomAgent(state_space_size, action_space_size; 
                policy_seed = 22,
                capacity = 1000, state_type = Float32, state_size = (state_space_size,)
                )

Using the structure of ReinforcementLearning.jl agents. This is the structure of a basic 
DQN agent (the one from Playing Atari - Google Deep Mind). This function give the possibility 
to parametrize this agent without having to think about the entire structure. 
If user, wants to go further, he can create its own agent. 
"""
function RandomAgent(env, state_space_size; 
                        policy_seed = 22,
                        capacity = 1000, state_type = Float32, state_size = (state_space_size,)
                        )
    # function
    agent = RL.Agent(
        policy = RL.RandomPolicy(RL.get_action_space(env), MersenneTwister(policy_seed)),
        trajectory = RL.CircularCompactSARTSATrajectory(
            capacity = capacity, 
            state_type = state_type, 
            state_size = state_size
        )
    )
    return agent
end


"""
    RLEnv

Implementation of the RL.AbstractEnv type coming from ReinforcementLearning's interface.
"""
mutable struct RLEnv{T, R<:AbstractRNG} <: RL.AbstractEnv 
    action_space::RL.DiscreteSpace{UnitRange{Int64}}
    observation_space::CPGraphSpace
    state::CPGraph
    done::Bool
    rng::R # random number generator
end

"""
    RLEnv(model::CPModel)

Construct the RLEnv thanks to the informations which are in the CPModel.
"""
function RLEnv(cpmodel::CPModel, seed = nothing)
    # construct the action_space
    variables = collect(values(cpmodel.variables))
    valuesOfVariables = sort(arrayOfEveryValue(variables))
    action_space = DiscreteSpace(valuesOfVariables)

    # construct the observation space
    observation_space = CPGraphSpace(length(variables), Float32)
    # get the random number generator
    rng = MersenneTwister(seed)

    env = RLEnv(
        action_space,
        observation_space,
        Random.rand(rng, observation_space), # will be synchronised later 
        false,
        rng)
    
    RL.reset!(env)
    env
end

"""
    sync!(env::RLEnv, cpmodel::CPModel, x::AbstractIntVar)

Synchronize the env with the CPModel.
"""
function sync_state!(env::RLEnv, cpmodel::CPModel, x::AbstractIntVar)
    g = CPLayerGraph(cpmodel)
    env.state = CPGraph(g, x)
end


"""
    RL.reset!(::RLEnv)

Reinitialise the environment so it is ready for a new episode.
"""
function reset!(env::RLEnv{T}) where {T<:Number}
    # the state will be synchronised later
    env.done = false
    nothing
end

"""
    observe(::RLEnv)

Return what is observe by the agent at each stage. It contains (among others) the
rewards, thus it might be a function to modify during our experiments. It also contains the 
legal_actions !

To do : Need to change the reward
To do : Need to change the legal actions
"""
function observe(env::RLEnv, x::AbstractIntVar)
    # get legal_actions_mask
    legal_actions_mask = [value in x.domain ? true : false  for value in env.action_space]

    # compute legal actions
    legal_actions = env.action_space[legal_actions_mask]

    # compute reward - we could add a transition function given by the user
    reward = env.done ? -1 : 0

    # return the observation as a named tuple (useful for interface understanding)
    return (reward = reward, terminal = env.done, state = env.state, legal_actions = legal_actions, legal_actions_mask = legal_actions_mask)
end

"""
    Random.seed!(env::RLEnv, seed)

We want our experiences to be reproducible, thus we provide this function to reseed the random
number generator. rng will give a reproducible sequence of numbers if and only if a seed is provided.
"""
Random.seed!(env::RLEnv, seed) = Random.seed!(env.rng, seed)

"""
    RL.render(env::RLEnv)
Not a priority at all. Give a human friendly representation of what's happening.
"""
render(env::RLEnv) = nothing

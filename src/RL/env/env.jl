

"""
    RLEnv

Implementation of the RL.AbstractEnv type coming from ReinforcementLearning's interface.
The RLEnv does not need t (step) and action as they are usually useful to control what is 
happening and this role is taken by the CP part in our framework. 

We will keep the env.done for now for convenience reasons (to stay near enough to the RL 
framework in order to be able to use its useful functions)
"""
mutable struct RLEnv <: RL.AbstractEnv 
    action_space::RL.DiscreteSpace{Array{Int64,1}}
    observation_space::CPGraphSpace
    state::CPGraph
    action::Int64
    reward::Int64
    done::Bool
    rng::Random.MersenneTwister # random number generator

    function RLEnv(action_space::RL.DiscreteSpace{Array{Int64,1}}, observation_space::CPGraphSpace, 
                   state::CPGraph, action::Int64, reward::Int64, done::Bool, rng::Random.MersenneTwister)
        new(action_space, observation_space, state, action, reward, done, rng) 
    end
end

"""
    RLEnv(model::CPModel)

Construct the RLEnv thanks to the informations which are in the CPModel.
"""
function RLEnv(cpmodel::CPModel, seed = nothing)
    # construct the action_space
    variables = collect(values(cpmodel.variables))
    valuesOfVariables = sort(arrayOfEveryValue(variables))
    action_space = RL.DiscreteSpace(valuesOfVariables)

    # construct the observation space
    observation_space = CPGraphSpace(length(variables))
    # get the random number generator
    rng = MersenneTwister(seed)

    env = RLEnv(
        action_space,
        observation_space,
        Random.rand(rng, observation_space), # will be synchronised later
        1,
        -1,
        false,  
        rng)
    
    #RL.reset!(env)
    env
end

"""
    set_done!(env::RLEnv, done::Bool)

Change the "done" attribute of the env. This is compulsory as used in the buffer
for the training.
"""
function set_done!(env::RLEnv, done::Bool)
    env.done = done
    nothing
end

"""
    set_reward!(env::RLEnv, symbol::Symbol)

Change the "reward" attribute of the env. This is compulsory as used in the buffer
for the training.
"""
function set_reward!(env::RLEnv, symbol::Symbol)
    env.reward += - 5 * (symbol == :Infeasible) + 5 * (symbol == :FoundSolution)
    nothing
end

"""
    set_final_reward!(env::RLEnv, symbol::Symbol)

Change the "reward" attribute of the env. This is compulsory as used in the buffer
for the training.
"""
function set_final_reward!(env::RLEnv, model::CPModel)
    if isempty(model.solutions)
        env.reward = 0
    elseif !isnothing(model.objectiveBound)
        env.reward = model.objectiveBound + 1
    else
        env.reward = 1
    end
    nothing
end

"""
    reset!(env::RLEnv)

Not sure this one will survive
"""
function reset!(env::RLEnv)
    env.done = false
    nothing 
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
    observe(::RLEnv)

Return what is observe by the agent at each stage. It contains (among others) the
rewards, thus it might be a function to modify during our experiments. It also contains the 
legal_actions !

To do : Need to change the reward
To do : Need to change the legal actions
"""
function observe!(env::RLEnv, model::CPModel, x::AbstractIntVar)
    # get legal_actions_mask
    legal_actions_mask = [value in x.domain for value in env.action_space]

    # compute legal actions
    legal_actions = env.action_space[legal_actions_mask]

    # compute reward - we could add a transition function given by the user
    reward = env.reward 
    env.reward = -1

    # synchronize state: we could delete env.state, we do not need it 
    sync_state!(env, model, x)

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

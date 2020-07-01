

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
    state::CPGraph
    action::Int64
    reward::Float64
    done::Bool
    rng::Random.MersenneTwister # random number generator
    nslbt::Int64
    nslfs::Int64
end

"""
    RLEnv(model::CPModel)

Construct the RLEnv thanks to the informations which are in the CPModel.
"""
function RLEnv(cpmodel::CPModel, seed = nothing)
    if isnothing(cpmodel.RLRep)
        cpmodel.RLRep = CPLayerGraph(cpmodel)
    end
    # construct the action_space
    variables = collect(values(cpmodel.variables))
    valuesOfVariables = sort(arrayOfEveryValue(variables))
    action_space = RL.DiscreteSpace(valuesOfVariables)

    # get the random number generator
    rng = MersenneTwister(seed)

    env = RLEnv(
        action_space,
        CPGraph(cpmodel, 0), # use a fake variable index
        1,
        0,
        false,  
        rng,
        1,
        1)
    
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
function set_reward!(env::RLEnv, model::CPModel, symbol::Symbol)
    nothing
end

"""
    set_final_reward!(env::RLEnv, symbol::Symbol)

Change the "reward" attribute of the env. This is compulsory as used in the buffer
for the training.
"""
function set_final_reward!(env::RLEnv, model::CPModel)
    env.reward += 30/(model.statistics.numberOfNodes)
    nothing
end

"""
    sync!(env::RLEnv, cpmodel::CPModel, x::AbstractIntVar)

Synchronize the env with the CPModel.
"""
function sync_state!(env::RLEnv, cpmodel::CPModel, x::AbstractIntVar)
    if isnothing(cpmodel.RLRep)
        cpmodel.RLRep = CPLayerGraph(cpmodel)
    end
    update_graph!(env.state, cpmodel.RLRep, x)
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
function observe!(env::RLEnv, model::CPModel, x::AbstractIntVar)
    # get legal_actions_mask
    legal_actions_mask = [value in x.domain for value in env.action_space]

    # compute legal actions
    legal_actions = env.action_space.span[legal_actions_mask]

    # compute reward - we could add a transition function given by the user
    reward = env.reward 
    env.reward = 0#-1/40
    # reward = 0
    # println("test")

    # synchronize state: we could delete env.state, we do not need it 
    sync_state!(env, model, x)

    state = to_array(env.state)
    state = reshape(state, size(state)..., 1)
    # println("reward", reward)
    
    # return the observation as a named tuple (useful for interface understanding)
    return (reward = reward, terminal = env.done, state = state, legal_actions = legal_actions, legal_actions_mask = legal_actions_mask)
end

"""
    Random.seed!(env::RLEnv, seed)

We want our experiences to be reproducible, thus we provide this function to reseed the random
number generator. rng will give a reproducible sequence of numbers if and only if a seed is provided.
"""
Random.seed!(env::RLEnv, seed) = Random.seed!(env.rng, seed)


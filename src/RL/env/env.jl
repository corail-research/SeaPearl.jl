"""
    RLEnvParams

Params needed to construct the RLEnv adapted to the current problem.
"""
struct RLEnvParams 
    name::String
end

"""
    extract_params(::CPModel)

The RLEnv of the problem while be created with a unify method. Nevertheless, it while still
depend on some parameters of the problem we are trying to solve. Hence, we are going to 
extract those parameters from the CPModel and they will further be given to the constructor
of the RLEnv.

This function might be moved to CP directory. 
"""
extract_params(::CPModel) = RLEnvParams("WIP")

"""

Implementation of the RL.AbstractEnv type coming from ReinforcementLearning's interface.

"""
mutable struct RLEnv{T, R<:AbstractRNG} <: RL.AbstractEnv 
    params::RLEnvParams
    action_space::RL.DiscreteSpace{UnitRange{Int64}}
    observation_space::RL.MultiContinuousSpace{Array{T,2}}
    state::Array{T,2} # adjacency matrix and feature matrix of a graph
    variable::Any # the variable we're working on - or we could even give the entire CPModel (useful for the graph creation)
    action::Int64
    done::Bool
    t::Int # time # number of steps
    rng::R # random number generator
end

"""
    RLEnv(model::CPModel)

Construct the RLEnv thanks to the informations which are in the CPModel.
"""
function RLEnv(model::CPModel, T = Float32, seed = nothing)
    params = extract_params(model)
    min = 1 # will depend on the CPModel
    max = 2 # will depend on the CPModel
    action_space = DiscreteSpace(min:max)
    low = Array{T, 2}[ [1 1], [1 1]] # will depend on the CPModel
    high = Array{T, 2}[ [3 3], [3 3]] # will depend on the CPModel
    env = RLEnv(
        params, 
        action_space,
        MultiContinuousSpace(low, high),
        zeros(T, (2, 2)), # will be truly initialized by RL.reset!()
        false,
        0,
        MersenneTwister(seed))
    RL.reset!(env)
    env
end

"""
    RL.reset!(::RLEnv)

Reinitialise the environment so it is ready for a new episode.
"""
function RL.reset!(env::RLEnv{T}) where {T<:Number}
    env.state = zeros(T, (2, 2)) # need to be changed
    env.done = false
    env.t = 0
    nothing
end


"""
    RL.observe(::RLEnv)

Return what is observe by the agent at each stage. It contains (among others) the
rewards, thus it might be a function to modify during our experiments. It also contains the 
legal_actions !

To do : Need to change the reward
To do : Need to change the legal actions
"""
function RL.observe(env::RLEnv)
    # compute legal actions
    legal_actions_mask = [true for i in 1:length(env.action_space)]

    # compute legal actions
    legal_actions = env.action_space[legal_actions_mask]

    # compute reward - we could add a transition function given by the user
    reward = env.done ? -1 : 0

    # return the observation as a named tuple (useful for interface understanding)
    return (reward = reward, terminal = env.done, state = env.state, legal_actions = legal_actions, legal_actions_mask = legal_actions_mask)
end

"""
    (env::RLEnv)(a)

This is the equivalent of the step! function. Here a implemented all the stuff that 
happen when an action is taken. This will be a step of the CP model !
"""
function (env::RLEnv)(a)
    """
    Changes are made in the CPModel, here we get the useful informations from the CPModel to make 
    sure the env has the latest updated informations.

    It would be great to have an efficient function to get from a previous state to a new one. At the moment, 
    we can use the whole constructor:  CPLayerGraph(::CPModel)
    """
    @assert a in env.action_space
    env.action = a
    env.t += 1
    # env.state = 
    # env.done = 
    # env.variable ou env.inner ou ??
    nothing
end

"""


Necessary in order to have a mask ! 
The observe function throw a named tuple (:reward, :terminal, :state, :legal_actions), hence, the interface
of ReinforcementLearningBase.jl already provide the get_legal_actions functions. The way the legal actions 
are found is build in the oberve(env::RLEnv) function. 

No need to override it as we use the named tuple convention recognised by RL.jl interface
"""
#RL.ActionStyle(::RLEnv) = RL.FULL_ACTION_SET

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
RL.render(env::RLEnv) = nothing

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

Implmentation of the RL.AbstractEnv type coming from ReinforcementLearning's interface.

"""
mutable struct RLEnv <: RL.AbstractEnv 
    params::RLEnvParams
    action_space::Any
    observation_space::Any
    state::Any
    action
    done::Bool
end

"""
    RLEnv(model::CPModel)

Construct the RLEnv thanks to the informations which are in the CPModel.
"""
function RLEnv(model::CPModel)
    params = extract_params(model)
    return RLEnv(params, false)
end

"""
    RL.reset!(::RLEnv)

Reinitialise the environment so it is ready for a new episode.
"""
RL.reset!(::RLEnv) = nothing

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
    legal_actions = env.action_space

    # compute reward
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
    RL.render(env::RLEnv)
Not a priority at all. Give a human friendly representation of what's happening.
"""
RL.render(env::RLEnv) = nothing

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

RL.reset!(::RLEnv) = nothing

"""
    RL.observe(::RLEnv)

Return what is observe by the agent at each stage. It typically contains the
rewards, thus it might be a function to modify during our experiments.
"""
function RL.observe(::RLEnv)
    nothing
end

"""
    (env::RLEnv)(a)

This is the equivalent of the step! function. Here a implemented all the stuff that 
happen when an action is taken.
"""
(env::RLEnv)(a) = nothing

"""

Not a priority at all.
"""
RL.render(env::RLEnv)

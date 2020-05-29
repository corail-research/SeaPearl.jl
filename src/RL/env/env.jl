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
RL.observe(::RLEnv) = nothing
(::RLEnv)(a) = nothing

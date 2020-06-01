using ReinforcementLearning
using Random

const RL = ReinforcementLearning

include("env/env.jl")
include("preprocessor/preprocessor.jl")
include("agent/agents.jl")
include("hooks.jl")
include("stop_conditions.jl")

function selectValue(x::IntVar)
    return maximum(x.domain)
end

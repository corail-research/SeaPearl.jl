include("../../RL/RL.jl")

abstract type ValueSelection end

mutable struct BasicHeuristic <: ValueSelection
    selectValue::Function

    BasicHeuristic() = new(selectValue)
end

mutable struct LearnedHeuristic <: ValueSelection
    agent::RL.Agent
    fitted_problem::Any
    fitted_strategy::Any
    current_env::Union{Nothing, RLEnv}

    LearnedHeuristic(agent::RL.Agent) = new(agent, nothing, nothing, nothing)
end

require_env(::BasicHeuristic) = false
require_env(::LearnedHeuristic) = true

selectValue(x::IntVar) = maximum(x.domain)
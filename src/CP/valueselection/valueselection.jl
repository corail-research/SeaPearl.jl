include("../../RL/RL.jl")

abstract type ValueSelection end

mutable struct BasicHeuristic <: ValueSelection
    selectValue::Function
end

"""
    BasicHeuristic()
    
Create the default `BasicHeuristic` that selects the maximum value of the domain
"""
BasicHeuristic() = BasicHeuristic(x -> maximum(x.domain))

mutable struct LearnedHeuristic{R<:AbstractReward} <: ValueSelection
    agent::RL.Agent
    fitted_problem::Union{Nothing, Symbol}
    fitted_strategy::Union{Nothing, Type{S}} where S <: SearchStrategy
    current_env::Union{Nothing, RLEnv}
    cpnodes_max::Union{Nothing, Int64}

    LearnedHeuristic{R}(agent::RL.Agent, cpnodes_max=nothing) where R = new{R}(agent, nothing, nothing, nothing, cpnodes_max)
end

LearnedHeuristic(agent::RL.Agent) = LearnedHeuristic{DefaultReward}(agent)

Flux.testmode!(lh::LearnedHeuristic, mode = true) = Flux.testmode!(lh.agent, mode)

abstract type LearningPhase end

struct InitializingPhase <: LearningPhase end
struct RewardingPhase <: LearningPhase end 
struct DecisionPhase <: LearningPhase end 
struct EndingPhase <: LearningPhase end 

# Implementations for a basic heuristic 
(valueSelection::BasicHeuristic)(::InitializingPhase, model::Union{Nothing, CPModel}=nothing, x::Union{Nothing, AbstractIntVar}=nothing, current_status::Union{Nothing, Symbol}=nothing) = nothing
(valueSelection::BasicHeuristic)(::RewardingPhase, model::Union{Nothing, CPModel}=nothing, x::Union{Nothing, AbstractIntVar}=nothing, current_status::Union{Nothing, Symbol}=nothing) = nothing
(valueSelection::BasicHeuristic)(::DecisionPhase, model::Union{Nothing, CPModel}=nothing, x::Union{Nothing, AbstractIntVar}=nothing, current_status::Union{Nothing, Symbol}=nothing) = valueSelection.selectValue(x)
(valueSelection::BasicHeuristic)(::EndingPhase, model::Union{Nothing, CPModel}=nothing, x::Union{Nothing, AbstractIntVar}=nothing, current_status::Union{Nothing, Symbol}=nothing) = nothing

# Implementations for a learned heuristic

"""
    (valueSelection::LearnedHeuristic)(::InitializingPhase, model::CPModel, x::Union{Nothing, AbstractIntVar}, current_status::Union{Nothing, Symbol})

Create an RL environment and a first observation. Finally make the agent call the process of 
the pre episode stage (basically making sure that the buffer is empty).
"""
function (valueSelection::LearnedHeuristic{R})(::InitializingPhase, model::CPModel, x::Union{Nothing, AbstractIntVar}, current_status::Union{Nothing, Symbol}) where R<:AbstractReward
    # create the environment
    valueSelection.current_env = RLEnv{R}(model::CPModel; cpnodes_max=valueSelection.cpnodes_max)
    false_x = first(values(model.variables))
    obs = observe!(valueSelection.current_env, model, false_x)

    # Reset the agent, useful for things like recurrent networks
    Flux.reset!(valueSelection.agent)

    valueSelection.agent(RL.PRE_EPISODE_STAGE, obs) # just empty the buffer
    # eventually hook(PRE_EPISODE_STAGE, agent, env, obs)
end

"""
    (valueSelection::LearnedHeuristic)(::RewardingPhase, model::CPModel, x::Union{Nothing, AbstractIntVar}, current_status::Union{Nothing, Symbol})

Set reward in case if needed.
"""
function (valueSelection::LearnedHeuristic)(::RewardingPhase, model::CPModel, x::Union{Nothing, AbstractIntVar}, current_status::Union{Nothing, Symbol})
    # the RL EPISODE continue
    # change reward in case of :Unfeasible status (I would like it for :FoundSolution if possible)
    # if is unnecessary but i keep it for visual issue atm 
    # set_backtracking_reward!(valueSelection.current_env, model, current_status)
    set_reward!(valueSelection.current_env, model, current_status)
    set_metrics!(valueSelection.current_env, model, current_status)
    # when we go back to expandDfs, env will be able to add the reward to the observation
end

"""
    (valueSelection::LearnedHeuristic)(::DecisionPhase, model::CPModel, x::Union{Nothing, AbstractIntVar}, current_status::Union{Nothing, Symbol})

Observe, store useful informations in the buffer with agent(POST_ACT_STAGE, ...) and take a decision
with the call of agent(PRE_ACT_STAGE).
"""
function (valueSelection::LearnedHeuristic)(::DecisionPhase, model::CPModel, x::Union{Nothing, AbstractIntVar}, current_status::Union{Nothing, Symbol})
    set_before_next_decision_reward!(valueSelection.current_env, model)

    obs = observe!(valueSelection.current_env, model, x)
    #println("Decision  ", obs.reward, " ", obs.terminal, " ", obs.legal_actions, " ", obs.legal_actions_mask)
    if model.statistics.numberOfNodes > 1
        valueSelection.agent(RL.POST_ACT_STAGE, obs) # get terminal and reward
        # eventually: hook(POST_ACT_STAGE, agent, env, obs, action)
    end
    v = valueSelection.agent(RL.PRE_ACT_STAGE, obs) # choose action, store it with the state
    
    # set_after_decision_reward!(valueSelection.current_env, model)
    return v
end

"""
    (valueSelection::LearnedHeuristic)(::EndingPhase, model::CPModel, x::Union{Nothing, AbstractIntVar}, current_status::Union{Nothing, Symbol})

Set the final reward, do last observation.
"""
function (valueSelection::LearnedHeuristic)(::EndingPhase, model::CPModel, x::Union{Nothing, AbstractIntVar}, current_status::Union{Nothing, Symbol})
    # the RL EPISODE stops
    set_done!(valueSelection.current_env, true)
    set_final_reward!(valueSelection.current_env, model, current_status)
    false_x = first(values(model.variables))
    obs = observe!(valueSelection.current_env, model, false_x)
    #println("EndingPhase  ", obs.reward, " ", obs.terminal, " ", obs.legal_actions, " ", obs.legal_actions_mask)

    valueSelection.agent(RL.POST_ACT_STAGE, obs) # get terminal and reward
    # eventually: hook(POST_ACT_STAGE, agent, env, obs, action)

    valueSelection.agent(RL.POST_EPISODE_STAGE, obs)  # let the agent see the last observation
    # eventually hook(POST_EPISODE_STAGE, agent, env, obs)
end

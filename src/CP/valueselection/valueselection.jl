
abstract type LearningPhase end

struct InitializingPhase <: LearningPhase end
struct StepPhase <: LearningPhase end 
struct DecisionPhase <: LearningPhase end 
struct EndingPhase <: LearningPhase end

include("../../RL/RL.jl")

abstract type ValueSelection end

mutable struct BasicHeuristic <: ValueSelection
    selectValue::Function
end

abstract type ActionOutput end
struct VariableOutput <: ActionOutput end
struct FixedOutput <: ActionOutput end

"""
    BasicHeuristic()
    
Create the default `BasicHeuristic` that selects the maximum value of the domain
"""
BasicHeuristic() = BasicHeuristic(x -> maximum(x.domain))

mutable struct LearnedHeuristic{R<:AbstractReward, A<:ActionOutput} <: ValueSelection
    agent::RL.Agent
    fitted_problem::Union{Nothing, Symbol}
    fitted_strategy::Union{Nothing, Type{S}} where S <: SearchStrategy
    current_env::Union{Nothing, RLEnv}
    cpnodes_max::Union{Nothing, Int64}

    LearnedHeuristic{R, A}(agent::RL.Agent, cpnodes_max=nothing) where {R, A}= new{R, A}(agent, nothing, nothing, nothing, cpnodes_max)
end

LearnedHeuristic(agent::RL.Agent) = LearnedHeuristic{DefaultReward, FixedOutput}(agent)

Flux.testmode!(lh::LearnedHeuristic, mode = true) = Flux.testmode!(lh.agent, mode) 

# Implementations for a basic heuristic 
(valueSelection::BasicHeuristic)(::InitializingPhase, model::Union{Nothing, CPModel}=nothing, x::Union{Nothing, AbstractIntVar}=nothing, current_status::Union{Nothing, Symbol}=nothing) = nothing
(valueSelection::BasicHeuristic)(::StepPhase, model::Union{Nothing, CPModel}=nothing, x::Union{Nothing, AbstractIntVar}=nothing, current_status::Union{Nothing, Symbol}=nothing) = nothing
(valueSelection::BasicHeuristic)(::DecisionPhase, model::Union{Nothing, CPModel}=nothing, x::Union{Nothing, AbstractIntVar}=nothing, current_status::Union{Nothing, Symbol}=nothing) = valueSelection.selectValue(x)
(valueSelection::BasicHeuristic)(::EndingPhase, model::Union{Nothing, CPModel}=nothing, x::Union{Nothing, AbstractIntVar}=nothing, current_status::Union{Nothing, Symbol}=nothing) = nothing

wears_mask(valueSelection::BasicHeuristic) = true

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
    (valueSelection::LearnedHeuristic)(::StepPhase, model::CPModel, x::Union{Nothing, AbstractIntVar}, current_status::Union{Nothing, Symbol})

The step phase is the phase between every procedure call. It is the best place to get stats about the search tree, that's why 
we put a set_metrics! function here. As those metrics could be used to design a reward, we also put a set_reward! function. 
ATM, the metrics are updated after the reward assignment as the current_status given totally decribes the changes that are to be made. 
Another possibility would be to have old and new metrics in memory. 
"""
function (valueSelection::LearnedHeuristic)(PHASE::StepPhase, model::CPModel, x::Union{Nothing, AbstractIntVar}, current_status::Union{Nothing, Symbol})
    set_reward!(PHASE, valueSelection.current_env, model, current_status)
    # incremental metrics, set after reward is updated
    set_metrics!(PHASE, valueSelection.current_env, model, current_status, nothing)
    nothing
end

"""
    (valueSelection::LearnedHeuristic)(::DecisionPhase, model::CPModel, x::Union{Nothing, AbstractIntVar}, current_status::Union{Nothing, Symbol})

Observe, store useful informations in the buffer with agent(POST_ACT_STAGE, ...) and take a decision
with the call of agent(PRE_ACT_STAGE).
The metrics that aren't updated in the StepPhase, which are more related to variables domains, are updated here. Once updated, they can 
be used in the other set_reward! function as the reward of the last action will only be collected in the RL.POST_ACT_STAGE.
"""
function (valueSelection::LearnedHeuristic)(PHASE::DecisionPhase, model::CPModel, x::Union{Nothing, AbstractIntVar}, current_status::Union{Nothing, Symbol})
    # domain change metrics, set before reward is updated
    set_metrics!(PHASE, valueSelection.current_env, model, nothing, x)
    set_reward!(PHASE, valueSelection.current_env, model)

    obs = observe!(valueSelection.current_env, model, x)

    if !wears_mask(valueSelection)
        obs = (reward = obs.reward, terminal = obs.terminal, state = obs.state)
    end

    #println("Decision  ", obs.reward, " ", obs.terminal, " ", obs.legal_actions, " ", obs.legal_actions_mask)
    if model.statistics.numberOfNodes > 1
        valueSelection.agent(RL.POST_ACT_STAGE, obs) # get terminal and reward
        # eventually: hook(POST_ACT_STAGE, agent, env, obs, action)
    end
    action = valueSelection.agent(RL.PRE_ACT_STAGE, obs) # choose action, store it with the state
    
    return action_to_value(valueSelection, action, obs.state, model)
    # println("Assign value : ", cp_vertex.value, " to variable : ", x)
    
    # set_after_decision_reward!(valueSelection.current_env, model)
end

function from_order_to_id(state::AbstractArray, value_order::Int64)
    value_vector = state[:, end]
    valid_indexes = findall((x) -> x == 1, value_vector)
    return valid_indexes[value_order]
end

function action_to_value(vs::LearnedHeuristic{R, VariableOutput}, action::Int64, state::AbstractArray, model::CPModel) where R <: AbstractReward
    value_id = from_order_to_id(state, action)
    cp_vertex = cpVertexFromIndex(model.RLRep, value_id)
    @assert isa(cp_vertex, ValueVertex)
    return cp_vertex.value
end

function action_to_value(vs::LearnedHeuristic{R, FixedOutput}, action::Int64, state::AbstractArray, model::CPModel) where R <: AbstractReward
    #TODO: Do a proper mapping here, using an offset for example
    return action
end

"""
    (valueSelection::LearnedHeuristic)(::EndingPhase, model::CPModel, x::Union{Nothing, AbstractIntVar}, current_status::Union{Nothing, Symbol})

Set the final reward, do last observation.
"""
function (valueSelection::LearnedHeuristic)(PHASE::EndingPhase, model::CPModel, x::Union{Nothing, AbstractIntVar}, current_status::Union{Nothing, Symbol})
    # the RL EPISODE stops
    set_done!(valueSelection.current_env, true)
    set_reward!(PHASE, valueSelection.current_env, model, current_status)
    false_x = first(values(model.variables))
    obs = observe!(valueSelection.current_env, model, false_x)
    if !wears_mask(valueSelection)
        obs = (reward = obs.reward, terminal = obs.terminal, state = obs.state)
    end
    #println("EndingPhase  ", obs.reward, " ", obs.terminal, " ", obs.legal_actions, " ", obs.legal_actions_mask)

    valueSelection.agent(RL.POST_ACT_STAGE, obs) # get terminal and reward
    # eventually: hook(POST_ACT_STAGE, agent, env, obs, action)

    valueSelection.agent(RL.POST_EPISODE_STAGE, obs)  # let the agent see the last observation
    # eventually hook(POST_EPISODE_STAGE, agent, env, obs)
end

wears_mask(valueSelection::LearnedHeuristic) = wears_mask(valueSelection.agent.policy.learner.approximator.model)

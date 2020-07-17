
include("searchmetrics.jl")

"""
    abstract type AbstractReward end

Used to customize the reward function. If you want to use your own reward, you have to create a struct
(called `CustomReward` for example) and define the following methods:
- set_reward!(::StepPhase, env::RLEnv{CustomReward}, model::CPModel, current_status::Union{Nothing, Symbol})
- set_reward!(::DecisionPhase, env::RLEnv{CustomReward}, model::CPModel)
- set_reward!(::EndingPhase, env::RLEnv{CustomReward}, symbol::Symbol)

Then, when creating the `LearnedHeuristic`, you define it using `LearnedHeuristic{CustomReward}(agent::RL.Agent)`
and your functions will be called instead of the default ones.
"""  

abstract type AbstractReward end

mutable struct LearnedHeuristic{SR<:AbstractStateRepresentation, R<:AbstractReward, A<:ActionOutput} <: ValueSelection
    agent::RL.Agent
    fitted_problem::Union{Nothing, Type{G}} where G
    fitted_strategy::Union{Nothing, Type{S}} where S <: SearchStrategy
    action_space::Union{Nothing, RL.DiscreteSpace{Array{Int64,1}}}
    current_state::Union{Nothing, SR}
    current_reward::Union{Nothing, Float64}
    cpnodes_max::Union{Nothing, Int64}
    search_metrics::Union{Nothing, SearchMetrics}

    LearnedHeuristic{SR, R, A}(agent::RL.Agent, cpnodes_max=nothing) where {SR, R, A}= new{SR, R, A}(agent, nothing, nothing, nothing, nothing, nothing, cpnodes_max, nothing)
end

LearnedHeuristic(agent::RL.Agent) = LearnedHeuristic{DefaultStateRepresentation, DefaultReward, FixedOutput}(agent)

include("lh_utils.jl")

"""
    (valueSelection::LearnedHeuristic)(::InitializingPhase, model::CPModel, x::Union{Nothing, AbstractIntVar}, current_status::Union{Nothing, Symbol})

Create an RL environment and a first observation. Finally make the agent call the process of 
the pre episode stage (basically making sure that the buffer is empty).
"""
function (valueSelection::LearnedHeuristic)(::InitializingPhase, model::CPModel, x::Union{Nothing, AbstractIntVar}, current_status::Union{Nothing, Symbol})
    # create the environment
    update_with_cpmodel!(valueSelection, model)
    false_x = first(values(model.variables))
    obs = get_observation!(valueSelection, model, false_x)

    # Reset the agent, useful for things like recurrent networks
    Flux.reset!(valueSelection.agent)

    valueSelection.agent(RL.PRE_EPISODE_STAGE, obs) # just empty the buffer
end

"""
    (valueSelection::LearnedHeuristic)(::StepPhase, model::CPModel, x::Union{Nothing, AbstractIntVar}, current_status::Union{Nothing, Symbol})

The step phase is the phase between every procedure call. It is the best place to get stats about the search tree, that's why 
we put a set_metrics! function here. As those metrics could be used to design a reward, we also put a set_reward! function. 
ATM, the metrics are updated after the reward assignment as the current_status given totally decribes the changes that are to be made. 
Another possibility would be to have old and new metrics in memory. 
"""
function (valueSelection::LearnedHeuristic)(PHASE::StepPhase, model::CPModel, x::Union{Nothing, AbstractIntVar}, current_status::Union{Nothing, Symbol})
    set_reward!(PHASE, valueSelection, model, current_status)
    # incremental metrics, set after reward is updated
    set_metrics!(PHASE, valueSelection, model, current_status, nothing)
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
    set_metrics!(PHASE, valueSelection, model, nothing, x)
    set_reward!(PHASE, valueSelection, model)

    obs = get_observation!(valueSelection, model, x)

    if !wears_mask(valueSelection)
        obs = (reward = obs.reward, terminal = obs.terminal, state = obs.state)
    end

    #println("Decision  ", obs.reward, " ", obs.terminal, " ", obs.legal_actions, " ", obs.legal_actions_mask)
    if model.statistics.numberOfNodes > 1
        valueSelection.agent(RL.POST_ACT_STAGE, obs) # get terminal and reward
    end
    action = valueSelection.agent(RL.PRE_ACT_STAGE, obs) # choose action, store it with the state
    
    return action_to_value(valueSelection, action, obs.state, model)
    # println("Assign value : ", cp_vertex.value, " to variable : ", x)
    
end

function from_order_to_id(state::AbstractArray, value_order::Int64)
    value_vector = state[:, end]
    valid_indexes = findall((x) -> x == 1, value_vector)
    return valid_indexes[value_order]
end

function action_to_value(vs::LearnedHeuristic{SR, R, VariableOutput}, action::Int64, state::AbstractArray, model::CPModel) where {
    SR <: AbstractStateRepresentation,
    R <: AbstractReward
}
    value_id = from_order_to_id(state, action)
    cp_vertex = cpVertexFromIndex(model.RLRep, value_id)
    @assert isa(cp_vertex, ValueVertex)
    return cp_vertex.value
end

function action_to_value(vs::LearnedHeuristic{SR, R, FixedOutput}, action::Int64, state::AbstractArray, model::CPModel) where {
    SR <: AbstractStateRepresentation,
    R <: AbstractReward
}
    #TODO: Do a proper mapping here, using an offset for example
    return action
end

"""
    (valueSelection::LearnedHeuristic)(::EndingPhase, model::CPModel, x::Union{Nothing, AbstractIntVar}, current_status::Union{Nothing, Symbol})

Set the final reward, do last observation.
"""
function (valueSelection::LearnedHeuristic)(PHASE::EndingPhase, model::CPModel, x::Union{Nothing, AbstractIntVar}, current_status::Union{Nothing, Symbol})
    # the RL EPISODE stops
    set_reward!(PHASE, valueSelection, model, current_status)
    false_x = first(values(model.variables))
    obs = get_observation!(valueSelection, model, false_x, true)
    if !wears_mask(valueSelection)
        obs = (reward = obs.reward, terminal = obs.terminal, state = obs.state)
    end
    #println("EndingPhase  ", obs.reward, " ", obs.terminal, " ", obs.legal_actions, " ", obs.legal_actions_mask)

    valueSelection.agent(RL.POST_ACT_STAGE, obs) # get terminal and reward

    valueSelection.agent(RL.POST_EPISODE_STAGE, obs)  # let the agent see the last observation
end

wears_mask(valueSelection::LearnedHeuristic) = wears_mask(valueSelection.agent.policy.learner.approximator.model)

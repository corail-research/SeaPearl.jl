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

mutable struct LearnedHeuristic <: ValueSelection
    agent::RL.Agent
    fitted_problem::Union{Nothing, Symbol}
    fitted_strategy::Union{Nothing, Type{S}} where S <: SearchStrategy
    current_env::Union{Nothing, RLEnv}
    cpnodes_max::Union{Nothing, Int64}

    LearnedHeuristic(agent::RL.Agent, cpnodes_max=nothing) = new(agent, nothing, nothing, nothing, cpnodes_max)
end

Flux.testmode!(lh::LearnedHeuristic, mode = true) = Flux.testmode!(lh.agent, mode)

abstract type LearningPhase end

struct InitializingPhase <: LearningPhase end
struct BackTrackingPhase <: LearningPhase end 
struct DecisionPhase <: LearningPhase end 
struct EndingPhase <: LearningPhase end 

# Implementations for a basic heuristic 
(valueSelection::BasicHeuristic)(::InitializingPhase, model::Union{Nothing, CPModel}=nothing, x::Union{Nothing, AbstractIntVar}=nothing, current_status::Union{Nothing, Symbol}=nothing) = nothing
(valueSelection::BasicHeuristic)(::BackTrackingPhase, model::Union{Nothing, CPModel}=nothing, x::Union{Nothing, AbstractIntVar}=nothing, current_status::Union{Nothing, Symbol}=nothing) = nothing
(valueSelection::BasicHeuristic)(::DecisionPhase, model::Union{Nothing, CPModel}=nothing, x::Union{Nothing, AbstractIntVar}=nothing, current_status::Union{Nothing, Symbol}=nothing) = valueSelection.selectValue(x)
(valueSelection::BasicHeuristic)(::EndingPhase, model::Union{Nothing, CPModel}=nothing, x::Union{Nothing, AbstractIntVar}=nothing, current_status::Union{Nothing, Symbol}=nothing) = nothing

wears_mask(valueSelection::BasicHeuristic) = true

# Implementations for a learned heuristic

"""
    (valueSelection::LearnedHeuristic)(::InitializingPhase, model::CPModel, x::Union{Nothing, AbstractIntVar}, current_status::Union{Nothing, Symbol})

Create an RL environment and a first observation. Finally make the agent call the process of 
the pre episode stage (basically making sure that the buffer is empty).
"""
function (valueSelection::LearnedHeuristic)(::InitializingPhase, model::CPModel, x::Union{Nothing, AbstractIntVar}, current_status::Union{Nothing, Symbol})
    # create the environment
    valueSelection.current_env = RLEnv(model::CPModel; cpnodes_max=valueSelection.cpnodes_max)
    false_x = first(values(model.variables))
    obs = observe!(valueSelection.current_env, model, false_x)

    # Reset the agent, useful for things like recurrent networks
    Flux.reset!(valueSelection.agent)

    valueSelection.agent(RL.PRE_EPISODE_STAGE, obs) # just empty the buffer
    # eventually hook(PRE_EPISODE_STAGE, agent, env, obs)
end

"""
    (valueSelection::LearnedHeuristic)(::BackTrackingPhase, model::CPModel, x::Union{Nothing, AbstractIntVar}, current_status::Union{Nothing, Symbol})

Set reward in case if needed.
"""
function (valueSelection::LearnedHeuristic)(::BackTrackingPhase, model::CPModel, x::Union{Nothing, AbstractIntVar}, current_status::Union{Nothing, Symbol})
    # the RL EPISODE continue
    # change reward in case of :Unfeasible status (I would like it for :FoundSolution if possible)
    # if is unnecessary but i keep it for visual issue atm 
    set_reward!(valueSelection.current_env, current_status)
    # when we go back to expandDfs, env will be able to add the reward to the observation
end

"""
    (valueSelection::LearnedHeuristic)(::DecisionPhase, model::CPModel, x::Union{Nothing, AbstractIntVar}, current_status::Union{Nothing, Symbol})

Observe, store useful informations in the buffer with agent(POST_ACT_STAGE, ...) and take a decision
with the call of agent(PRE_ACT_STAGE).
"""
function (valueSelection::LearnedHeuristic)(::DecisionPhase, model::CPModel, x::Union{Nothing, AbstractIntVar}, current_status::Union{Nothing, Symbol})
    obs = observe!(valueSelection.current_env, model, x)

    if !wears_mask(valueSelection)
        obs = (reward = obs.reward, terminal = obs.terminal, state = obs.state)
    end

    #println("Decision  ", obs.reward, " ", obs.terminal, " ", obs.legal_actions, " ", obs.legal_actions_mask)
    if model.statistics.numberOfNodes > 1
        valueSelection.agent(RL.POST_ACT_STAGE, obs) # get terminal and reward
        # eventually: hook(POST_ACT_STAGE, agent, env, obs, action)
    end
    value_order = valueSelection.agent(RL.PRE_ACT_STAGE, obs) # choose action, store it with the state
    
    value_id = from_order_to_id(obs.state, value_order)
    cp_vertex = cpVertexFromIndex(model.RLRep, value_id)

    @assert isa(cp_vertex, ValueVertex)


    #println("Assign value : ", v, " to variable : ", x)
    return cp_vertex.value
end

function from_order_to_id(obs::AbstractArray, value_order::Int64)
    value_vector = state[:, end]
    valid_indexes = findall((x) -> x == 1, value_vector)
    return valid_indexes[value_order]
end

"""
    (valueSelection::LearnedHeuristic)(::EndingPhase, model::CPModel, x::Union{Nothing, AbstractIntVar}, current_status::Union{Nothing, Symbol})

Set the final reward, do last observation.
"""
function (valueSelection::LearnedHeuristic)(::EndingPhase, model::CPModel, x::Union{Nothing, AbstractIntVar}, current_status::Union{Nothing, Symbol})
    # the RL EPISODE stops
    set_done!(valueSelection.current_env, true)
    set_final_reward!(valueSelection.current_env, model)
    false_x = first(values(model.variables))
    obs = observe!(valueSelection.current_env, model, false_x)
    #println("EndingPhase  ", obs.reward, " ", obs.terminal, " ", obs.legal_actions, " ", obs.legal_actions_mask)

    valueSelection.agent(RL.POST_ACT_STAGE, obs) # get terminal and reward
    # eventually: hook(POST_ACT_STAGE, agent, env, obs, action)

    valueSelection.agent(RL.POST_EPISODE_STAGE, obs)  # let the agent see the last observation
    # eventually hook(POST_EPISODE_STAGE, agent, env, obs)
end

wears_mask(valueSelection::LearnedHeuristic) = wears_mask(valueSelection.agent.policy.learner.approximator.model)

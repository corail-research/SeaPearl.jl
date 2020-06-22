include("../../RL/RL.jl")

abstract type ValueSelection end

mutable struct BasicHeuristic <: ValueSelection
    selectValue::Function
end

selectValue(x::IntVar) = maximum(x.domain)
BasicHeuristic() = BasicHeuristic(selectValue)

mutable struct LearnedHeuristic <: ValueSelection
    agent::RL.Agent
    fitted_problem::Union{Nothing, Symbol}
    fitted_strategy::Union{Nothing, Type{S}} where S <: SearchStrategy
    current_env::Union{Nothing, RLEnv}

    LearnedHeuristic(agent::RL.Agent) = new(agent, nothing, nothing, nothing)
end

abstract type LearningProcess end

struct InitializingPhase <: LearningProcess end
struct BackTrackingPhase <: LearningProcess end 
struct DecisionPhase <: LearningProcess end 
struct EndingPhase <: LearningProcess end 

# Implementations for a basic heuristic 
(valueSelection::BasicHeuristic)(::InitializingPhase, model::Union{Nothing, CPModel}=nothing, x::Union{Nothing, AbstractIntVar}=nothing, current_status::Union{Nothing, Symbol}=nothing) = nothing
(valueSelection::BasicHeuristic)(::BackTrackingPhase, model::Union{Nothing, CPModel}=nothing, x::Union{Nothing, AbstractIntVar}=nothing, current_status::Union{Nothing, Symbol}=nothing) = nothing
(valueSelection::BasicHeuristic)(::DecisionPhase, model::Union{Nothing, CPModel}=nothing, x::Union{Nothing, AbstractIntVar}=nothing, current_status::Union{Nothing, Symbol}=nothing) = valueSelection.selectValue(x)
(valueSelection::BasicHeuristic)(::EndingPhase, model::Union{Nothing, CPModel}=nothing, x::Union{Nothing, AbstractIntVar}=nothing, current_status::Union{Nothing, Symbol}=nothing) = nothing

# Implementations for a learned heuristic
function (valueSelection::LearnedHeuristic)(::InitializingPhase, model::CPModel, x::Union{Nothing, AbstractIntVar}, current_status::Union{Nothing, Symbol})
    # create the environment
    valueSelection.current_env = RLEnv(model::CPModel)
    false_x = first(values(model.variables))
    obs = observe!(valueSelection.current_env, model, false_x)
    valueSelection.agent(RL.PRE_EPISODE_STAGE, obs) # just empty the buffer
    # eventually hook(PRE_EPISODE_STAGE, agent, env, obs)
end

function (valueSelection::LearnedHeuristic)(::BackTrackingPhase, model::CPModel, x::Union{Nothing, AbstractIntVar}, current_status::Union{Nothing, Symbol})
    # the RL EPISODE continue
    # change reward in case of :Unfeasible status (I would like it for :FoundSolution if possible)
    # if is unnecessary but i keep it for visual issue atm 
    set_reward!(valueSelection.current_env, current_status)
    # when we go back to expandDfs, env will be able to add the reward to the observation
end

function (valueSelection::LearnedHeuristic)(::DecisionPhase, model::CPModel, x::Union{Nothing, AbstractIntVar}, current_status::Union{Nothing, Symbol})
    obs = observe!(valueSelection.current_env, model, x)
    if model.statistics.numberOfNodes > 1
        valueSelection.agent(RL.POST_ACT_STAGE, obs) # get terminal and reward
        # eventually: hook(POST_ACT_STAGE, agent, env, obs, action)
    end
    v = valueSelection.agent(RL.PRE_ACT_STAGE, obs) # choose action, store it with the state
    # eventually hook(PRE_ACT_STAGE, agent, env, obs, action)

    #println("Assign value : ", v, " to variable : ", x)
end

function (valueSelection::LearnedHeuristic)(::EndingPhase, model::CPModel, x::Union{Nothing, AbstractIntVar}, current_status::Union{Nothing, Symbol})
    # the RL EPISODE stops
    set_done!(valueSelection.current_env, true)
    set_final_reward!(valueSelection.current_env, model)
    false_x = first(values(model.variables))
    obs = observe!(valueSelection.current_env, model, false_x)

    valueSelection.agent(RL.POST_ACT_STAGE, obs) # get terminal and reward
    # eventually: hook(POST_ACT_STAGE, agent, env, obs, action)

    valueSelection.agent(RL.POST_EPISODE_STAGE, obs)  # let the agent see the last observation
    # eventually hook(POST_EPISODE_STAGE, agent, env, obs)
end
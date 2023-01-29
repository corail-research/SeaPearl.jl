"""
    SimpleLearnedHeuristic{SR<:AbstractStateRepresentation, R<:AbstractReward, A<:ActionOutput}

`SimpleLearnedHeuristic` is value selection heuristic. It is the standard version of a `LearnedHeuristic` and 
is based on on-policy learning. The agent only learns from his own previous actions, contrary to `SupervisedLearnedHeuristic` 
for which the agent is provided, with a certain probability, with classic CP-solved solutions of the instance to learn from.
"""
mutable struct SimpleLearnedHeuristic{SR<:AbstractStateRepresentation, R<:AbstractReward, A<:ActionOutput} <: LearnedHeuristic{SR, R, A}
    agent::RL.Agent
    fitted_problem::Union{Nothing, Type{G}} where G
    fitted_strategy::Union{Nothing, Type{S}} where S <: SearchStrategy
    action_space::Union{Nothing, Array{Int64,1}}
    current_state::Union{Nothing, SR}
    reward::Union{Nothing, R}
    search_metrics::Union{Nothing, SearchMetrics}
    firstActionTaken::Bool
    trainMode::Bool
    chosen_features::Union{Nothing,Dict{String,Bool}}
    SimpleLearnedHeuristic{SR, R, A}(agent::RL.Agent; chosen_features=nothing) where {SR, R, A}= new{SR, R, A}(agent, nothing, nothing, nothing, nothing, nothing, nothing, false, true, chosen_features)
end

"""
    (valueSelection::SimpleLearnedHeuristic)(::InitializingPhase, model::CPModel, x::Union{Nothing, AbstractIntVar}, current_status::Union{Nothing, Symbol})

Update the part of the SimpleLearnedHeuristic which act like an RL environment, by initializing it with informations caracteritic of the new CPModel. Creates an
initial observation with a false variable. A fixPoint! will be called before the SimpleLearnedHeuristic takes its first decision.
Finally, makes the agent call the process of the RL pre_episode_stage (basically making sure that the buffer is empty).
"""
function (valueSelection::SimpleLearnedHeuristic)(::Type{InitializingPhase}, model::CPModel)
    # create the environment
    valueSelection.firstActionTaken = false
    update_with_cpmodel!(valueSelection, model; chosen_features=valueSelection.chosen_features)
    # FIXME get rid of this => prone to bugs
    false_x = first(values(branchable_variables(model)))
    env = get_observation!(valueSelection, model, false_x)
    Flux.reset!(valueSelection.agent) # Reset the agent, useful for things like recurrent networks

    if valueSelection.trainMode
        valueSelection.agent(RL.PRE_EPISODE_STAGE, env)
    end
end

"""
    (valueSelection::SimpleLearnedHeuristic)(::DecisionPhase, model::CPModel, x::Union{Nothing, AbstractIntVar}, current_status::Union{Nothing, Symbol})

Observe, store useful informations in the buffer with agent(POST_ACT_STAGE, ...) and take a decision with the call to agent(PRE_ACT_STAGE).
The metrics that aren't updated in the StepPhase, which are more related to variables domains, are updated here. Once updated, they can
be used in the other set_reward! function as the reward of the last action will only be collected in the RL.POST_ACT_STAGE.
"""
function (valueSelection::SimpleLearnedHeuristic)(PHASE::Type{DecisionPhase}, model::CPModel, x::Union{Nothing, AbstractIntVar})
    # domain change metrics, set before reward is updated
    set_metrics!(PHASE, valueSelection.search_metrics, model, x)
    set_reward!(PHASE, valueSelection, model)
    model.statistics.lastVar = x
    env = get_observation!(valueSelection, model, x)

    if valueSelection.firstActionTaken
        if valueSelection.trainMode
            valueSelection.agent(RL.POST_ACT_STAGE, env) # get terminal and reward
        end
    else
        valueSelection.firstActionTaken = true
    end

    action = valueSelection.agent(env) # Choose action
    if valueSelection.trainMode
        # TODO: swap to async computation once in deployment
        #@async valueSelection.agent(RL.PRE_ACT_STAGE, env, action) # Store state and action
        valueSelection.agent(RL.PRE_ACT_STAGE, env, action)
    end

    model.statistics.lastVal = action_to_value(valueSelection, action, state(env), model)

    return model.statistics.lastVal
end
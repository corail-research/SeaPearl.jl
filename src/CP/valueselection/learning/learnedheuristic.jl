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

"""
    LearnedHeuristic{SR<:AbstractStateRepresentation, R<:AbstractReward, A<:ActionOutput}

The LearnedHeuristic is a value selection heuristic which is learned thanks to a training made by solving a certain amount 
of problem instances from files or from an `AbstractModelGenerator`. From the RL point of view, this is an agent which is
learning how to choose an appropriate action (value to assign) when observing an `AbstractStateRepresentation`. The agent 
learns thanks to rewards that are given regularly during the search. He wil try to maximize the total reward.

From the RL point of view, this LearnedHeuristic also plays part of the role normally played by the environment. Indeed, the 
LearnedHeuristic stores the action space, the current state and reward. The other role that a classic RL environment has is describing
the consequences of an action: in SeaPearl, this is done by the CP part - branching, running fixPoint!, backtracking, etc...
"""
mutable struct LearnedHeuristic{SR<:AbstractStateRepresentation, R<:AbstractReward, A<:ActionOutput} <: ValueSelection
    agent::RL.Agent
    fitted_problem::Union{Nothing, Type{G}} where G
    fitted_strategy::Union{Nothing, Type{S}} where S <: SearchStrategy
    action_space::Union{Nothing, Array{Int64,1}}
    current_state::Union{Nothing, SR}
    reward::Union{Nothing, R}
    search_metrics::Union{Nothing, SearchMetrics}
    firstActionTaken::Bool
    LearnedHeuristic{SR, R, A}(agent::RL.Agent) where {SR, R, A}= new{SR, R, A}(agent, nothing, nothing, nothing, nothing, nothing, nothing, false)
end

"""
    (valueSelection::LearnedHeuristic)(::InitializingPhase, model::CPModel, x::Union{Nothing, AbstractIntVar}, current_status::Union{Nothing, Symbol})

Update the part of the LearnedHeuristic which act like an RL environment, by initializing it with informations caracteritic of the new CPModel. Creates an 
initial observation with a false variable. A fixPoint! will be called before the LearnedHeuristic takes its first decision.
Finally, makes the agent call the process of the RL pre_episode_stage (basically making sure that the buffer is empty). 
"""
function (valueSelection::LearnedHeuristic)(::Type{InitializingPhase}, model::CPModel)
    # create the environment
    valueSelection.firstActionTaken = false
    update_with_cpmodel!(valueSelection, model)
    # FIXME get rid of this => prone to bugs
    false_x = first(values(branchable_variables(model)))
    env = get_observation!(valueSelection, model, false_x)

    # Reset the agent, useful for things like recurrent networks
    Flux.reset!(valueSelection.agent)

    valueSelection.agent(RL.PRE_EPISODE_STAGE, env)
end

"""
    (valueSelection::LearnedHeuristic)(::StepPhase, model::CPModel, x::Union{Nothing, AbstractIntVar}, current_status::Union{Nothing, Symbol})

The step phase is the phase between every procedure call. It is the best place to get stats about the search tree, that's why 
we put a set_metrics! function here. As those metrics could be used to design a reward, we also put a set_reward! function. 
ATM, the metrics are updated after the reward assignment as the current_status given totally decribes the changes that are to be made. 
Another possibility would be to have old and new metrics in memory. 
"""
function (valueSelection::LearnedHeuristic)(PHASE::Type{StepPhase}, model::CPModel, current_status::Union{Nothing, Symbol})
    set_reward!(PHASE, valueSelection, model, current_status)
    # incremental metrics, set after reward is updated
    set_metrics!(PHASE, valueSelection.search_metrics, model, current_status)
    nothing
end

"""
    (valueSelection::LearnedHeuristic)(::DecisionPhase, model::CPModel, x::Union{Nothing, AbstractIntVar}, current_status::Union{Nothing, Symbol})

Observe, store useful informations in the buffer with agent(POST_ACT_STAGE, ...) and take a decision with the call to agent(PRE_ACT_STAGE).
The metrics that aren't updated in the StepPhase, which are more related to variables domains, are updated here. Once updated, they can 
be used in the other set_reward! function as the reward of the last action will only be collected in the RL.POST_ACT_STAGE.
"""
function (valueSelection::LearnedHeuristic)(PHASE::Type{DecisionPhase}, model::CPModel, x::Union{Nothing, AbstractIntVar})
    # domain change metrics, set before reward is updated
    set_metrics!(PHASE, valueSelection.search_metrics, model, x)
    set_reward!(PHASE, valueSelection, model)

    env = get_observation!(valueSelection, model, x)

    #println("Decision  ", env.reward, " ", env.terminal, " ", env.legal_actions, " ", env.legal_actions_mask)
    if valueSelection.firstActionTaken 
        valueSelection.agent(RL.POST_ACT_STAGE, env) # get terminal and reward
    else 
        valueSelection.firstActionTaken = true
    end

    action = valueSelection.agent(env) # Choose action
    # TODO: swap to async computation once in deployment
    #@async valueSelection.agent(RL.PRE_ACT_STAGE, env, action) # Store state and action
    valueSelection.agent(RL.PRE_ACT_STAGE, env, action)

    return action_to_value(valueSelection, action, state(env), model)
end

"""
    (valueSelection::LearnedHeuristic)(::EndingPhase, model::CPModel, x::Union{Nothing, AbstractIntVar}, current_status::Union{Nothing, Symbol})

Set the final reward, do last observation.
"""
function (valueSelection::LearnedHeuristic)(PHASE::Type{EndingPhase}, model::CPModel, current_status::Union{Nothing, Symbol})
    # the RL EPISODE stops
    if valueSelection.firstActionTaken 
        set_reward!(DecisionPhase,valueSelection, model)  #last decision reward for the previous action taken just before the ending Phase
    end
    set_reward!(PHASE, valueSelection, model, current_status)
    false_x = first(values(branchable_variables(model)))
    env = get_observation!(valueSelection, model, false_x, true)
    #println("EndingPhase  ", env.reward, " ", env.terminal, " ", env.legal_actions, " ", env.legal_actions_mask)

    valueSelection.agent(RL.POST_ACT_STAGE, env) # get terminal and reward

    valueSelection.agent(RL.POST_EPISODE_STAGE, env)  # let the agent see the last observation
    
    if CUDA.has_cuda()
        CUDA.reclaim()
    end
end


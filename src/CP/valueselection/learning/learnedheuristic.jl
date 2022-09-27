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
    mutable struct LearnedHeuristic{SR<:AbstractStateRepresentation, R<:AbstractReward, A<:ActionOutput}

The LearnedHeuristic is a value selection heuristic learned thanks to a training made by solving problem instances from files 
or from an `AbstractModelGenerator`. From the RL point of view, LearnedHeuristic contains an agent which is
learning how to choose an appropriate action (value to assign) when observing an `AbstractStateRepresentation`, which is 
a representation of the instance at its current state. The agent learns thanks to rewards that are given regularly 
during the search. He tries to maximize the total reward.

From the RL point of view, this LearnedHeuristic also plays part of the role normally played by the environment. Indeed, the
LearnedHeuristic stores the action space, the current state and reward. The other role that a classic RL environment 
plays is describing the consequences of an action: in SeaPearl, this is done by the CP part - branching, 
running fixPoint!, backtracking, etc...


"""

abstract type LearnedHeuristic{SR<:AbstractStateRepresentation, R<:AbstractReward, A<:ActionOutput} <: ValueSelection end

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

    if valueSelection.trainMode
        valueSelection.agent(RL.POST_ACT_STAGE, env) # get terminal and reward
        valueSelection.agent(RL.POST_EPISODE_STAGE, env)  # let the agent see the last observation
    end

    if isa(valueSelection.agent.policy.learner, A2CLearner) && (device(valueSelection.agent.policy.learner.approximator.actor) != Val{:cpu}())
        CUDA.reclaim()
    elseif !isa(valueSelection.agent.policy.learner, A2CLearner) && device(valueSelection.agent.policy.learner.approximator.model) != Val{:cpu}()
        CUDA.reclaim()
    end
end

"""
    SupervisedLearnedHeuristic{SR<:AbstractStateRepresentation, R<:AbstractReward, A<:ActionOutput}

`SupervisedLearnedHeuristic` is value selection heuristic. The agent learns from both his previous actions and classic CP-generated solutions. 
For each episode, with probability η (êta), a solution is generated using classic CP and is provided to the agent, which will take the exact same
actions to retrieve the same solution. This operation aims at providing the agent with solutions to learn from, in order to accelerate the learning,
since it is sometimes difficult to provide a solution using an untrained RL agent, for some problems like TSPTW.
"""

mutable struct SupervisedLearnedHeuristic{SR<:AbstractStateRepresentation,R<:AbstractReward,A<:ActionOutput} <: LearnedHeuristic{SR,R,A}
    agent::RL.Agent
    fitted_problem::Union{Nothing,Type{G}} where {G}
    fitted_strategy::Union{Nothing,Type{S}} where {S<:SearchStrategy}
    action_space::Union{Nothing,Array{Int64,1}}
    current_state::Union{Nothing,SR}
    reward::Union{Nothing,R}
    search_metrics::Union{Nothing,SearchMetrics}
    firstActionTaken::Bool
    trainMode::Bool
    helpVariableHeuristic::AbstractVariableSelection
    helpValueHeuristic::ValueSelection
    helpSolution::Union{Nothing,Solution}
    eta_init::Float64
    eta_stable::Float64
    warmup_steps::Int64
    decay_steps::Int64
    step::Int64
    
    function SupervisedLearnedHeuristic{SR,R,A}(
        agent::RL.Agent;
        helpVariableHeuristic::AbstractVariableSelection=MinDomainVariableSelection(),
        helpValueHeuristic::ValueSelection=BasicHeuristic(),
        eta_init::Float64=0.5,
        eta_stable::Float64=0.5,
        warmup_steps::Int64=0,
        decay_steps::Int64=0
    ) where {SR,R,A}
        new{SR,R,A}(agent, nothing, nothing, nothing, nothing, nothing, nothing, false, true, helpVariableHeuristic, helpValueHeuristic, nothing, eta_init, eta_stable, warmup_steps, decay_steps, 1)
    end
end

"""
    (valueSelection::SupervisedLearnedHeuristic)(::InitializingPhase, model::CPModel, x::Union{Nothing, AbstractIntVar}, current_status::Union{Nothing, Symbol})

Update the part of the SupervisedLearnedHeuristic which act like an RL environment, by initializing it with informations caracteritic of the new CPModel. Creates an
initial observation with a false variable. A fixPoint! will be called before the SupervisedLearnedHeuristic takes its first decision.
Finally, makes the agent call the process of the RL pre_episode_stage (basically making sure that the buffer is empty).
"""
function (valueSelection::SupervisedLearnedHeuristic)(::Type{InitializingPhase}, model::CPModel)
    # create the environment
    valueSelection.firstActionTaken = false
    update_with_cpmodel!(valueSelection, model)
    # FIXME get rid of this => prone to bugs
    false_x = first(values(branchable_variables(model)))
    env = get_observation!(valueSelection, model, false_x)
    eta = get_eta(valueSelection) #get the current eta_init
    
    if rand() < eta
        #the instance is solved using classic CP on a duplicated model
        model_duplicate = deepcopy(model) 
        strategy = DFSearch()
        search!(model_duplicate, strategy, valueSelection.helpVariableHeuristic, valueSelection.helpValueHeuristic)
        #the solution is added to the valueSelection.helpSolution field.
        if !isnothing(model_duplicate.statistics.solutions)
            solutions = model_duplicate.statistics.solutions[model_duplicate.statistics.solutions.!=nothing]
            if length(solutions) >= 1
                valueSelection.helpSolution = solutions[1]
            end
        end
        reset_model!(model_duplicate)
    else
        valueSelection.helpSolution = nothing
    end

    # Reset the agent, useful for things like recurrent networks
    Flux.reset!(valueSelection.agent)

    if valueSelection.trainMode
        valueSelection.agent(RL.PRE_EPISODE_STAGE, env)
    end
end

"""
    (valueSelection::SupervisedLearnedHeuristic)(::StepPhase, model::CPModel, x::Union{Nothing, AbstractIntVar}, current_status::Union{Nothing, Symbol})

The step phase is the phase between every procedure call. It is the best place to get stats about the search tree, that's why
we put a set_metrics! function here. As those metrics could be used to design a reward, we also put a set_reward! function.
ATM, the metrics are updated after the reward assignment as the current_status given totally decribes the changes that are to be made.
Another possibility would be to have old and new metrics in memory.
"""
function (valueSelection::SupervisedLearnedHeuristic)(PHASE::Type{StepPhase}, model::CPModel, current_status::Union{Nothing,Symbol})
    set_reward!(PHASE, valueSelection, model, current_status)
    # incremental metrics, set after reward is updated
    set_metrics!(PHASE, valueSelection.search_metrics, model, current_status)
    nothing
end

"""
    (valueSelection::SupervisedLearnedHeuristic)(::DecisionPhase, model::CPModel, x::Union{Nothing, AbstractIntVar}, current_status::Union{Nothing, Symbol})

Observe, store useful informations in the buffer with agent(POST_ACT_STAGE, ...) and take a decision with the call to agent(PRE_ACT_STAGE).
The metrics that aren't updated in the StepPhase, which are more related to variables domains, are updated here. Once updated, they can
be used in the other set_reward! function as the reward of the last action will only be collected in the RL.POST_ACT_STAGE.
"""
function (valueSelection::SupervisedLearnedHeuristic)(PHASE::Type{DecisionPhase}, model::CPModel, x::Union{Nothing,AbstractIntVar})
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

    # If a solution is available, we choose the value of the variable in the solution.
    if valueSelection.trainMode && !isnothing(valueSelection.helpSolution) 
        action = valueSelection.helpSolution[x.id]
    else # Else we choose the action provided by the agent
        action = valueSelection.agent(env) # Choose action
    end
    
    if valueSelection.trainMode
        # TODO: swap to async computation once in deployment
        #@async valueSelection.agent(RL.PRE_ACT_STAGE, env, action) # Store state and action
        valueSelection.agent(RL.PRE_ACT_STAGE, env, action)
    end

    return action_to_value(valueSelection, action, state(env), model)
end

"""
    (valueSelection::SupervisedLearnedHeuristic)(::EndingPhase, model::CPModel, x::Union{Nothing, AbstractIntVar}, current_status::Union{Nothing, Symbol})

Set the final reward, do last observation.
"""
function (valueSelection::SupervisedLearnedHeuristic)(PHASE::Type{EndingPhase}, model::CPModel, current_status::Union{Nothing,Symbol})
    # the RL EPISODE stops
    if valueSelection.firstActionTaken
        set_reward!(DecisionPhase, valueSelection, model)  #last decision reward for the previous action taken just before the ending Phase
    end
    set_reward!(PHASE, valueSelection, model, current_status)
    false_x = first(values(branchable_variables(model)))
    env = get_observation!(valueSelection, model, false_x, true)

    if valueSelection.trainMode
        valueSelection.agent(RL.POST_ACT_STAGE, env) # get terminal and reward
        valueSelection.agent(RL.POST_EPISODE_STAGE, env)  # let the agent see the last observation
    end

    if CUDA.has_cuda()
        CUDA.reclaim()
    end
end

"""
    get_eta(vs::SupervisedLearnedHeuristic)

Get the current value of `eta` (η), which is the probability for the solver to calculate and provide a classic CP-generated solution to the agent.
"""
function get_eta(vs::SupervisedLearnedHeuristic)
    vs.step += 1
    if vs.decay_steps == 0
        return vs.eta_init
    end

    step = vs.step
    if step <= vs.warmup_steps
        return vs.eta_init
    elseif step >= (vs.warmup_steps + vs.decay_steps)
        return vs.eta_stable
    else
        steps_left = vs.warmup_steps + vs.decay_steps - step
        return vs.eta_stable + steps_left / vs.decay_steps * (vs.eta_init - vs.eta_stable)
    end
end

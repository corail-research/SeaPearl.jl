"""
    struct GeneralReward <: AbstractReward end

This is a general reward encouraging a smart exploration of the tree in the case DFSearch is used.
"""
mutable struct GeneralReward <: AbstractReward 
    value::Float32
    initMin::Union{Nothing,Int}
    initMax::Union{Nothing,Int}
    initialNumberOfVariableValueLinks::Int
    gamma::Float32 # Gamma balances the "variable" and the "objective" part of the reward
    beta::Float32 # Beta governs the convexity of the "variable" part of the reward given at the DecisionPhase
end

function GeneralReward(model::CPModel)
    # Beta and gamma should be changed here.
    # Beta should be larger than one to ensure convexity of the "variable" part of the reward given at the DecisionPhase
    if !isnothing(model.objective)
        return GeneralReward(0, model.objective.domain.min.value, model.objective.domain.max.value, global_domain_cardinality(model), 2.0, 2.0)
    else
        return GeneralReward(0, nothing, nothing, global_domain_cardinality(model), 2.0, 2.0)
    end
end

"""
    set_reward!(::StepPhase, lh::LearnedHeuristic{GeneralReward, A}, model::CPModel, symbol::Union{Nothing, Symbol})

Change the "current_reward" attribute of the LearnedHeuristic at the StepPhase.
"""
function set_reward!(::Type{StepPhase}, lh::LearnedHeuristic{SR, GeneralReward, A}, model::CPModel, symbol::Union{Nothing, Symbol}) where {
    SR <: AbstractStateRepresentation,
    A <: ActionOutput
}
    nothing
end

"""
    set_reward!(::DecisionPhase, lh::LearnedHeuristic{GeneralReward, O}, model::CPModel)

Change the current reward at the DecisionPhase. This is called right before making the next decision, so you know you have the very last state before the new decision
and every computation like fixPoints and backtracking has been done.
"""
function set_reward!(::Type{DecisionPhase}, lh::LearnedHeuristic{SR, GeneralReward, A}, model::CPModel) where {
    SR <: AbstractStateRepresentation,
    A <: ActionOutput
}
    if !lh.firstActionTaken
        lh.reward.value = 0
    else
        # The "variable" part of the reward fosters the agent to perform assignments which prune the search space as fast as possible
        lh.reward.value = lh.reward.gamma*(model.statistics.lastPruning/(lh.reward.initialNumberOfVariableValueLinks - length(branchable_variables(model))))^lh.reward.beta
        if !isnothing(model.objective)
            # The "objective part of the reward deters the agent from performing assigments that prune the lowest values of the domain of the objective variable
            lh.reward.value += -(model.statistics.objectiveDownPruning/(lh.reward.initMax - lh.reward.initMin)) + (model.statistics.objectiveUpPruning/(lh.reward.initMax - lh.reward.initMin))
        end
    end
end


"""
    set_reward!(::EndingPhase, lh::LearnedHeuristic{GeneralReward, A}, model::CPModel, symbol::Union{Nothing, Symbol})

Increment the current reward at the EndingPhase. Called when the search is finished by an optimality proof or by a limit in term of nodes or 
in terms of number of solution. This is useful to add some general results to the reward like the number of ndoes visited during the episode for instance. 
"""
function set_reward!(::Type{EndingPhase}, lh::LearnedHeuristic{SR, GeneralReward, A}, model::CPModel, symbol::Union{Nothing, Symbol}) where {
    SR <: AbstractStateRepresentation, 
    A <: ActionOutput
}
    # The rewards given in the EndingPhase ensure that any found feasible solution always gets a higher reward than any infeasible solution
    if symbol == :FoundSolution
        lh.reward.value = 0
    else
        lh.reward.value = -lh.reward.gamma
        if !isnothing(model.objective)
            lh.reward.value += -1
        end
    end
end
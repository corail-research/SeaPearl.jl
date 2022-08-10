"""
    struct ScoreReward <: AbstractReward end

This is a general reward encouraging a smart exploration of the tree in the case DFSearch is used.
"""
mutable struct ScoreReward <: AbstractReward 
    value::Float32
    initMax::Int
end

function ScoreReward(model::CPModel)
    return ScoreReward(0, model.objective.domain.max.value)
end

"""
    set_reward!(::StepPhase, lh::LearnedHeuristic{ScoreReward, A}, model::CPModel, symbol::Union{Nothing, Symbol})

Change the "current_reward" attribute of the LearnedHeuristic at the StepPhase.
"""
function set_reward!(::Type{StepPhase}, lh::LearnedHeuristic{SR, ScoreReward, A}, model::CPModel, symbol::Union{Nothing, Symbol}) where {
    SR <: AbstractStateRepresentation,
    A <: ActionOutput
}
    nothing
end

"""
    set_reward!(::DecisionPhase, lh::LearnedHeuristic{ScoreReward, O}, model::CPModel)

Change the current reward at the DecisionPhase. This is called right before making the next decision, so you know you have the very last state before the new decision
and every computation like fixPoints and backtracking has been done.
"""
function set_reward!(::Type{DecisionPhase}, lh::LearnedHeuristic{SR, ScoreReward, A}, model::CPModel) where {
    SR <: AbstractStateRepresentation,
    A <: ActionOutput
}
    lh.reward.value = 0
end


"""
    set_reward!(::EndingPhase, lh::LearnedHeuristic{ScoreReward, A}, model::CPModel, symbol::Union{Nothing, Symbol})

Increment the current reward at the EndingPhase. Called when the search is finished by an optimality proof or by a limit in term of nodes or 
in terms of number of solution. This is useful to add some general results to the reward like the number of ndoes visited during the episode for instance. 
"""
function set_reward!(::Type{EndingPhase}, lh::LearnedHeuristic{SR, ScoreReward, A}, model::CPModel, symbol::Union{Nothing, Symbol}) where {
    SR <: AbstractStateRepresentation, 
    A <: ActionOutput
}
    # The rewards given in the EndingPhase ensure that any found feasible solution always gets a higher reward than any infeasible solution
    if symbol == :FoundSolution
        lh.reward.value = -assignedValue(model.objective)
    else
        lh.reward.value = -lh.reward.initMax - 1
    end
end
"""
    struct DefaultReward <: AbstractReward end

This is the default reward, that will be used if no custom reward is specified when constructing the `LearnedHeuristic`.
"""
struct DefaultReward <: AbstractReward end

"""
    set_reward!(::StepPhase, lh::LearnedHeuristic{DefaultReward, O}, model::CPModel, symbol::Union{Nothing, Symbol})

Change the "reward" attribute of the env. This is compulsory as used in the buffer
for the training.
"""
function set_reward!(::StepPhase, lh::LearnedHeuristic{SR, DefaultReward, O}, model::CPModel, symbol::Union{Nothing, Symbol}) where {
    SR <: AbstractStateRepresentation,
    O <: ActionOutput
}
    nothing
end

"""
    set_reward!(::DecisionPhase, lh::LearnedHeuristic{DefaultReward, O}, model::CPModel)

Change the reward of `env`. This is called right before making the next decision, so you know you have the very last state before the new decision
and every computation like fixPoints and backtracking has been done.
"""
function set_reward!(::DecisionPhase, lh::LearnedHeuristic{SR, DefaultReward, O}, model::CPModel) where {
    SR <: AbstractStateRepresentation,
    O <: ActionOutput
}
    lh.current_reward += -1/40
    nothing
end


"""
    set_reward!(::EndingPhase, lh::LearnedHeuristic{DefaultReward, O}, model::CPModel, symbol::Union{Nothing, Symbol})

Change the "reward" attribute of the env. Called when the optimality is proved.
"""
function set_reward!(::EndingPhase, lh::LearnedHeuristic{SR, DefaultReward, O}, model::CPModel, symbol::Union{Nothing, Symbol}) where {
    SR <: AbstractStateRepresentation, 
    O <: ActionOutput
}
    lh.current_reward += 30/(model.statistics.numberOfNodes)
    nothing
end
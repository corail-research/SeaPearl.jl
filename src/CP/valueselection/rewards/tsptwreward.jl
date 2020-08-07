"""
    struct TsptwReward <: AbstractReward end

Tsptw is one of the already implemented rewards of SeaPearl.jl. A user can use it directly. 
This reward is adapted to the tsptw problem and is inspired from the one used by Quentin Cappart in 
his recent paper: Combining RL & CP for Combinatorial Optimization, https://arxiv.org/pdf/2006.01610.pdf.
"""
struct TsptwReward <: AbstractReward end

"""
    set_reward!(::StepPhase, lh::LearnedHeuristic{TsptwReward, A}, model::CPModel, symbol::Union{Nothing, Symbol})

Change the "current_reward" attribute of the LearnedHeuristic at the StepPhase.
"""
function set_reward!(::StepPhase, lh::LearnedHeuristic{SR, TsptwReward, A}, model::CPModel, symbol::Union{Nothing, Symbol}) where {
    SR <: AbstractStateRepresentation,
    A <: ActionOutput
}
    nothing
end

"""
    set_reward!(::DecisionPhase, lh::LearnedHeuristic{TsptwReward, O}, model::CPModel)

Change the current reward at the DecisionPhase. This is called right before making the next decision, so you know you have the very last state before the new decision
and every computation like fixPoints and backtracking has been done.
"""
function set_reward!(::DecisionPhase, lh::LearnedHeuristic{SR, TsptwReward, A}, model::CPModel) where {
    SR <: AbstractStateRepresentation,
    A <: ActionOutput
}
    lh.current_reward += -1/40
    nothing
end


"""
    set_reward!(::EndingPhase, lh::LearnedHeuristic{TsptwReward, A}, model::CPModel, symbol::Union{Nothing, Symbol})

Increment the current reward at the EndingPhase. Called when the search is finished by an optimality proof or by a limit in term of nodes or 
in terms of number of solution. This is useful to add some general results to the reward like the number of ndoes visited during the episode for instance. 
"""
function set_reward!(::EndingPhase, lh::LearnedHeuristic{SR, TsptwReward, A}, model::CPModel, symbol::Union{Nothing, Symbol}) where {
    SR <: AbstractStateRepresentation, 
    A <: ActionOutput
}
    lh.current_reward += 30/(model.statistics.numberOfNodes)
    nothing
end
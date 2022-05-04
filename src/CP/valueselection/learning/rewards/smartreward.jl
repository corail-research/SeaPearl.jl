"""
    struct SmartReward <: AbstractReward end

This is the smart reward, that will be used to teach the agent to prioritize paths that lead to improving solutions.
"""
mutable struct SmartReward <: AbstractReward 
    value::Float32
end

SmartReward(model::CPModel) = SmartReward(0)

"""
    set_reward!(::StepPhase, lh::LearnedHeuristic{SmartReward, A}, model::CPModel, symbol::Union{Nothing, Symbol})

Change the "current_reward" attribute of the LearnedHeuristic at the StepPhase.
"""
function set_reward!(::Type{StepPhase}, lh::LearnedHeuristic{SR, SmartReward, A}, model::CPModel, symbol::Union{Nothing, Symbol}) where {
    SR <: AbstractStateRepresentation,
    A <: ActionOutput
}
    if symbol == :Infeasible  
        #println("INFEASIBLE")
        #lh.reward.value -= last_episode_total_reward(lh.agent.trajectory)
        lh.reward.value -= 0

    elseif symbol == :FoundSolution
        #println("SOLUTION FOUND, score : ",assignedValue(model.objective), " delta : ",15-assignedValue(model.objective)," accumulated reward :  ", model.statistics.AccumulatedRewardBeforeReset)
        lh.reward.value += isnothing(model.objective) ?  0 : 100 * (-assignedValue(model.objective))
        #lh.reward.value += model.statistics.lastPruning

    elseif symbol == :Feasible 
        lh.reward.value -= 0
    elseif symbol == :BackTracking
        lh.reward.value -= 0
    end
end

"""
    set_reward!(::DecisionPhase, lh::LearnedHeuristic{SmartReward, O}, model::CPModel)

Change the current reward at the DecisionPhase. This is called right before making the next decision, so you know you have the very last state before the new decision
and every computation like fixPoints and backtracking has been done.
"""
function set_reward!(::Type{DecisionPhase}, lh::LearnedHeuristic{SR, SmartReward, A}, model::CPModel) where {
    SR <: AbstractStateRepresentation,
    A <: ActionOutput
}
    #println("Decision, reward : ",model.statistics.lastPruning)

    #lh.reward.value += model.statistics.lastPruning

end


"""
    set_reward!(::EndingPhase, lh::LearnedHeuristic{SmartReward, A}, model::CPModel, symbol::Union{Nothing, Symbol})

Increment the current reward at the EndingPhase. Called when the search is finished by an optimality proof or by a limit in term of nodes or 
in terms of number of solution. This is useful to add some general results to the reward like the number of ndoes visited during the episode for instance. 
"""
function set_reward!(::Type{EndingPhase}, lh::LearnedHeuristic{SR, SmartReward, A}, model::CPModel, symbol::Union{Nothing, Symbol}) where {
    SR <: AbstractStateRepresentation, 
    A <: ActionOutput
}
    lh.reward.value += 0

end
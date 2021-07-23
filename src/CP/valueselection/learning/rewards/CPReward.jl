function f(x::AbstractIntVar,alpha::Float64)
    return 1/(assignedValue(x)+1)^alpha
end

"""
    struct CPReward <: AbstractReward end
This is the default reward, that will be used if no custom reward is specified when constructing the `LearnedHeuristic`.
"""
mutable struct CPReward <: AbstractReward
    value::Float32
end

CPReward(model::CPModel) = CPReward(0)

"""
    set_reward!(::StepPhase, lh::LearnedHeuristic{DefaultReward, A}, model::CPModel, symbol::Union{Nothing, Symbol})
Change the "current_reward" attribute of the LearnedHeuristic at the StepPhase.
"""
function set_reward!(::Type{StepPhase}, lh::LearnedHeuristic{SR, CPReward, A}, model::CPModel, symbol::Union{Nothing, Symbol}) where {
    SR <: AbstractStateRepresentation,
    A <: ActionOutput
}
    nothing
end

"""
    set_reward!(::DecisionPhase, lh::LearnedHeuristic{DefaultReward, O}, model::CPModel)
Change the current reward at the DecisionPhase. This is called right before making the next decision, so you know you have the very last state before the new decision
and every computation like fixPoints and backtracking has been done.
"""
function set_reward!(::Type{DecisionPhase}, lh::LearnedHeuristic{SR, CPReward, A}, model::CPModel) where {
    SR <: AbstractStateRepresentation,
    A <: ActionOutput
}
    nothing
end


"""
    set_reward!(::EndingPhase, lh::LearnedHeuristic{DefaultReward, A}, model::CPModel, symbol::Union{Nothing, Symbol})
Increment the current reward at the EndingPhase. Called when the search is finished by an optimality proof or by a limit in term of nodes or
in terms of number of solution. This is useful to add some general results to the reward like the number of ndoes visited during the episode for instance.
"""
function set_reward!(::Type{EndingPhase}, lh::LearnedHeuristic{SR, CPReward, A}, model::CPModel, symbol::Union{Nothing, Symbol}) where {
    SR <: AbstractStateRepresentation,
    A <: ActionOutput
}
    alpha = 0.5
    if symbol == :FoundSolution
        if isnothing(model.objective)
            lh.reward.value += 1
        else
            lh.reward.value += f(model.objective, alpha)
        end
    else 
        lh.reward.value -= length(branchable_variables(model))/nb_boundvariables(model) - 1 
    end
end

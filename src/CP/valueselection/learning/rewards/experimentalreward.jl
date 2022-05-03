"""
    struct ExperimentalReward <: AbstractReward end

This is the default reward, that will be used if no custom reward is specified when constructing the `LearnedHeuristic`.
"""
mutable struct ExperimentalReward <: AbstractReward 
    value::Float32
    initMin::Int
    initMax::Int
end

function ExperimentalReward(model::CPModel)
    return ExperimentalReward(0, model.objective.domain.min.value, model.objective.domain.max.value)
end

"""
    set_reward!(::StepPhase, lh::LearnedHeuristic{ExperimentalReward, A}, model::CPModel, symbol::Union{Nothing, Symbol})

Change the "current_reward" attribute of the LearnedHeuristic at the StepPhase.
"""
function set_reward!(::Type{StepPhase}, lh::LearnedHeuristic{SR, ExperimentalReward, A}, model::CPModel, symbol::Union{Nothing, Symbol}) where {
    SR <: AbstractStateRepresentation,
    A <: ActionOutput
}
    nothing
end

"""
    set_reward!(::DecisionPhase, lh::LearnedHeuristic{ExperimentalReward, O}, model::CPModel)

Change the current reward at the DecisionPhase. This is called right before making the next decision, so you know you have the very last state before the new decision
and every computation like fixPoints and backtracking has been done.
"""
function set_reward!(::Type{DecisionPhase}, lh::LearnedHeuristic{SR, ExperimentalReward, A}, model::CPModel) where {
    SR <: AbstractStateRepresentation,
    A <: ActionOutput
}
    #lh.reward.value = nb_boundvariables(model)/length(branchable_variables(model)) - model.objective.domain.min.value
    beta = 1.0
    gamma1 = 0.5
    gamma2 = 1.0
    threshold = -10.0
    first_part = (nb_boundvariables(model)/length(branchable_variables(model)))^beta
    #second_part = gamma2*(lh.reward.initMin/model.objective.domain.min.value)^beta2
    if !isnothing(model.objective)
        second_part = max(-tan((π/(2*(lh.reward.initMax-lh.reward.initMin)))*(model.objective.domain.min.value-lh.reward.initMin)),threshold)
        lh.reward.value = gamma1*first_part + gamma2*second_part
    else
        lh.reward.value = first_part
    end
end


"""
    set_reward!(::EndingPhase, lh::LearnedHeuristic{ExperimentalReward, A}, model::CPModel, symbol::Union{Nothing, Symbol})

Increment the current reward at the EndingPhase. Called when the search is finished by an optimality proof or by a limit in term of nodes or 
in terms of number of solution. This is useful to add some general results to the reward like the number of ndoes visited during the episode for instance. 
"""
function set_reward!(::Type{EndingPhase}, lh::LearnedHeuristic{SR, ExperimentalReward, A}, model::CPModel, symbol::Union{Nothing, Symbol}) where {
    SR <: AbstractStateRepresentation, 
    A <: ActionOutput
}
    nqueens_conflict_counter = false
    alpha = 1.0
    kappa = 5*model.statistics.numberOfNodesBeforeRestart
    if symbol == :FoundSolution
        if isnothing(model.objective)
            #lh.reward.value = 20*(20-model.statistics.numberOfNodes)
            #lh.reward.value = 100
            lh.reward.value = kappa*(count(values(model.branchable))/model.statistics.numberOfNodes)^alpha1
        else
            #lh.reward.value = 20*(10-assignedValue(model.objective))
            println("Objective: "*string(assignedValue(model.objective)))
            #lh.reward.value = kappa*(1/assignedValue(model.objective))^alpha2
            lh.reward.value = (kappa/(lh.reward.initMin-lh.reward.initMax))*(assignedValue(model.objective)-lh.reward.initMax)
        end
    else
        #lh.reward.value = -1
        println("Infeasible")
        lh.reward.value = -kappa
        if nqueens_conflict_counter
            # Getting the number of conflicts on nqueens
            # Getting assigned variables
            boundvariables = Dict{Int,Int}()
            for (id, x) in model.variables
                if isbound(x)
                    boundvariables[parse(Int,split(id,"_")[end])] = assignedValue(x)
                end
            end
            # Getting diagonals ids
            posdiags = zeros(39)
            negdiags = zeros(39)
            for (i, j) in boundvariables
                posdiags[i+j-1] += 1
                negdiags[i+(20-j)] += 1
            end

            nb_conflicts = 0
            nb_conflicts += sum(values(counter(values(boundvariables))) .- 1)
            nb_conflicts += sum((posdiags .> 1) .* (posdiags .- 1))
            nb_conflicts += sum((negdiags .> 1) .* (negdiags .- 1))
            #println("Number of conflicts: "*string(nb_conflicts))
            #lh.reward.value -= 30*nb_conflicts
            lh.reward.value -= kappa*nb_conflicts
        end
    end

end
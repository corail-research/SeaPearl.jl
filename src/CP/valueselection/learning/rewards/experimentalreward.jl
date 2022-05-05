"""
    struct ExperimentalReward <: AbstractReward end

This is the default reward, that will be used if no custom reward is specified when constructing the `LearnedHeuristic`.
"""
mutable struct ExperimentalReward <: AbstractReward 
    value::Float32
    initMin::Int
    initMax::Int
    initialNumberOfVariableValueLinks::Int
    gamma::Float32
    beta::Float32
end

function ExperimentalReward(model::CPModel)
    return ExperimentalReward(0, model.objective.domain.min.value, model.objective.domain.max.value, global_domain_cardinality(model), 2.0, 2.0)
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
    if !lh.firstActionTaken
        #println("First action being taken")
        lh.reward.value = 0
    else
        lh.reward.value = lh.reward.gamma*(model.statistics.lastPruning/(lh.reward.initialNumberOfVariableValueLinks - length(branchable_variables(model))))^lh.reward.beta
        if lh.reward.value>0.01
            #println("Variable part: "*string(lh.reward.value))
        end
        if !isnothing(model.objective)
            lh.reward.value += (-(model.statistics.objectiveDownPruning/(lh.reward.initMax - lh.reward.initMin)) + (model.statistics.objectiveUpPruning/(lh.reward.initMax - lh.reward.initMin)) + 1) / 2
            #println("Objective part: "*string(-(model.statistics.objectiveDownPruning/(lh.reward.initMax - lh.reward.initMin)) + (model.statistics.objectiveUpPruning/(lh.reward.initMax - lh.reward.initMin))))
            if -(model.statistics.objectiveDownPruning/(lh.reward.initMax - lh.reward.initMin)) + (model.statistics.objectiveUpPruning/(lh.reward.initMax - lh.reward.initMin)) != 0
                #println("Objective domain: "*string(model.objective.domain))
                #println("Down pruning: "*string(model.statistics.objectiveDownPruning))
                #println("Up pruning: "*string(model.statistics.objectiveUpPruning))
            end
        end
        #println(lh.reward.value)
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
   
    if symbol == :FoundSolution
        lh.reward.value = 0
        println("Feasible -> Objective = "*string(assignedValue(model.objective)))
    else
        println("Infeasible")
        lh.reward.value = -lh.reward.gamma
        if !isnothing(model.objective)
            lh.reward.value += -1
        end
        if nqueens_conflict_counter
            # Getting the number of conflicts on nqueens
            # Getting assigned variables
            println("nqueens_conflict_counter")
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
            lh.reward.value -= nb_conflicts
        end
    end
    println("Ending reward: "*string(lh.reward.value))

end
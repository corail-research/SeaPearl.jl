"""
    initroot!(toCall::Stack{Function}, ::DFSearch, model::CPModel, variableHeuristic::AbstractVariableSelection, valueSelection::ValueSelection)

Used as a generic function to instantiate the research based on a specific Strategy <: SearchStrategy. 
    
"""
function initroot!(toCall::Stack{Function}, ::DFSearch, model::CPModel, variableHeuristic::AbstractVariableSelection, valueSelection::ValueSelection)
    return expandDfs!(toCall, model, variableHeuristic, valueSelection)
end



"""
    expandDfs!(toCall::Stack{Function}, model::CPModel, variableHeuristic::Function, valueSelection::ValueSelection, newConstraints=nothing)

Add procedures to `toCall`, that, called in the stack order (LIFO) with the `model` parameter, will perform a DFS in the graph.
Some procedures will contain a call to `expandDfs!` itself. Each `expandDfs!` call is wrapped around a `saveState!` and a `restoreState!` to be
able to backtrack thanks to the trailer.
"""
function expandDfs!(toCall::Stack{Function}, model::CPModel, variableHeuristic::AbstractVariableSelection, valueSelection::ValueSelection, newConstraints=nothing; prunedDomains::Union{CPModification,Nothing}=nothing)

    # Dealing with limits
    model.statistics.numberOfNodes += 1
    model.statistics.numberOfNodesBeforeRestart += 1
    
    if !belowTimeLimit(model)
        return :TimeLimitStop
    end
    if !belowNodeLimit(model)
        return :NodeLimitStop
    end
    if !belowSolutionLimit(model)
        return :SolutionLimitStop
    end

    # Fix-point algorithm
    feasible, pruned = fixPoint!(model, newConstraints, prunedDomains; isFailureBased=isa(variableHeuristic, FailureBasedVariableSelection))
    model.statistics.lastPruning = sum(map(x-> length(x[2]),collect(pruned)))
    if !isnothing(model.objective)
        if haskey(pruned,model.objective.id)
            model.statistics.objectiveDownPruning = 0
            model.statistics.objectiveUpPruning = 0
            orderedPrunedValues = sort(pruned[model.objective.id])
            #println("pruned values"*string(orderedPrunedValues))
            # Last pruning takes all variables except the objective value into consideration
            model.statistics.lastPruning -= length(orderedPrunedValues)
            for val in orderedPrunedValues
                if val <= model.objective.domain.min.value
                    model.statistics.objectiveDownPruning += 1
                elseif val >= model.objective.domain.max.value
                    model.statistics.objectiveUpPruning += 1
                else
                    # Pruning from the middle of the domain of the objective variable
                    model.statistics.objectiveDownPruning += (model.objective.domain.max.value - val)/(model.objective.domain.max.value-model.objective.domain.min.value)
                    model.statistics.objectiveUpPruning += (val - model.objective.domain.min.value)/(model.objective.domain.max.value-model.objective.domain.min.value)
                end
            end
        else
            model.statistics.objectiveDownPruning = 0
            model.statistics.objectiveUpPruning = 0
        end
    end


    if !feasible
        model.statistics.numberOfInfeasibleSolutions += 1
        model.statistics.numberOfInfeasibleSolutionsBeforeRestart += 1

        return :Infeasible
    end
    if solutionFound(model)
        triggerFoundSolution!(model)
        return :FoundSolution
    end

    # Variable selection
    x = variableHeuristic(model)
    # Value selection
    v = valueSelection(DecisionPhase, model, x)
    #println("value: "*string(v))

    #println("Value : ", v, " assigned to : ", x.id)

    push!(toCall, (model) -> (restoreState!(model.trailer); :BackTracking))
    push!(toCall, (model) -> (
        prunedDomains = CPModification();
        addToPrunedDomains!(prunedDomains, x, remove!(x.domain, v));
        expandDfs!(toCall, model, variableHeuristic, valueSelection, getOnDomainChange(x); prunedDomains=prunedDomains)
    ))
    push!(toCall, (model) -> (saveState!(model.trailer); :SavingState))

    push!(toCall, (model) -> (restoreState!(model.trailer); :BackTracking))
    push!(toCall, (model) -> (
        prunedDomains = CPModification();
        addToPrunedDomains!(prunedDomains, x, assign!(x, v));
        expandDfs!(toCall, model, variableHeuristic, valueSelection, getOnDomainChange(x); prunedDomains=prunedDomains)
    ))
    push!(toCall, (model) -> (saveState!(model.trailer); :SavingState))

    return :Feasible
end

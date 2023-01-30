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

    feasible, pruned = fixPoint!(model, newConstraints, prunedDomains; isFailureBased=isa(variableHeuristic, FailureBasedVariableSelection))
    updateStatistics!(model,pruned)

    if !feasible
        model.statistics.numberOfInfeasibleSolutions += 1
        model.statistics.numberOfInfeasibleSolutionsBeforeRestart += 1

        return :Infeasible
    end
    if solutionFound(model)
        act = triggerFoundSolution!(model)
        if act == :tightenObjective
            if isa(valueSelection, LearnedHeuristic) && !valueSelection.trainMode || isa(valueSelection, Union{BasicHeuristic, ImpactHeuristic, ActivityHeuristic})
                tightenObjective!(model)
            end
        end
        return :FoundSolution
    end

    x = variableHeuristic(model)
    v = valueSelection(DecisionPhase, model, x)

    push!(toCall, (model, currentStatus) -> (restoreState!(model.trailer); :BackTracking))
    push!(toCall, (model, currentStatus) -> (
        prunedDomains = CPModification();
        addToPrunedDomains!(prunedDomains, x, remove!(x.domain, v));
        expandDfs!(toCall, model, variableHeuristic, valueSelection, getOnDomainChange(x); prunedDomains=prunedDomains)
    ))
    push!(toCall, (model, currentStatus) -> (saveState!(model.trailer); :SavingState))

    push!(toCall, (model, currentStatus) -> (restoreState!(model.trailer); :BackTracking))
    push!(toCall, (model, currentStatus) -> (
        prunedDomains = CPModification();
        addToPrunedDomains!(prunedDomains, x, assign!(x, v));
        expandDfs!(toCall, model, variableHeuristic, valueSelection, getOnDomainChange(x); prunedDomains=prunedDomains)
    ))
    push!(toCall, (model, currentStatus) -> (saveState!(model.trailer); :SavingState))

    return :Feasible
end
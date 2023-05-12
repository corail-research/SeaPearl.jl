"""
    initroot!(toCall::Stack{Function}, ::DFWBSearch, model::CPModel, variableHeuristic::AbstractVariableSelection, valueSelection::ValueSelection)

Used as a generic function to instantiate the research based on a specific Strategy <: SearchStrategy. 
    
"""
function initroot!(toCall::Stack{Function}, ::DFWBSearch, model::CPModel, variableHeuristic::AbstractVariableSelection, valueSelection::ValueSelection)
    return expandDfwbs!(toCall, model, variableHeuristic, valueSelection, direction= :Left)
end

"""
    expandDfwbs!(toCall::Stack{Function}, model::CPModel, variableHeuristic::Function, valueSelection::ValueSelection, newConstraints=nothing)
Expands the DFWBS search tree.
"""
function expandDfwbs!(toCall::Stack{Function}, model::CPModel, variableHeuristic::AbstractVariableSelection, valueSelection::ValueSelection, newConstraints=nothing; prunedDomains::Union{CPModification,Nothing}=nothing, direction::Symbol)

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
            if isa(valueSelection, LearnedHeuristic) && !valueSelection.trainMode || isa(valueSelection, Union{BasicHeuristic, ImpactHeuristic})
                tightenObjective!(model)
            end
        end
        return :FoundSolution
    end

    if direction == :Right
        valueSelection(InitializingPhase, model)
    end
    x = variableHeuristic(model)
    v = valueSelection(DecisionPhase, model, x)

    push!(toCall, (model, currentStatus) -> (restoreState!(model.trailer); :BackTracking))
    push!(toCall, (model, currentStatus) -> (
        prunedDomains = CPModification();
        addToPrunedDomains!(prunedDomains, x, remove!(x.domain, v));
        expandDfwbs!(toCall, model, variableHeuristic, valueSelection, getOnDomainChange(x); prunedDomains=prunedDomains, direction = :Right)
        ))
    push!(toCall, (model, currentStatus) -> (saveState!(model.trailer); :SavingState))
    push!(toCall, (model, currentStatus) -> (restoreState!(model.trailer); :BackTracking))
    push!(toCall, (model, currentStatus) -> (
        prunedDomains = CPModification();
        addToPrunedDomains!(prunedDomains, x, assign!(x, v));
        currentStatus = expandDfwbs!(toCall, model, variableHeuristic, valueSelection, getOnDomainChange(x); prunedDomains=prunedDomains, direction = :Left);
        if currentStatus != :Feasible
            valueSelection(EndingPhase, model, :End)
        end;
        return currentStatus
    ))
    push!(toCall, (model, currentStatus) -> (saveState!(model.trailer); :SavingState))

    return :Feasible
end

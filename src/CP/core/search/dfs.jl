"""
    initroot!(toCall::Stack{Function}, ::Type{DFSearch},model::CPModel, variableHeuristic::AbstractVariableSelection, valueSelection::ValueSelection, newConstraints=nothing)

Used as a generic function to instantiate the research based on a specific Strategy <: SearchStrategy. 
    
"""
function initroot!(toCall::Stack{Function}, ::Type{DFSearch}, model::CPModel, variableHeuristic::AbstractVariableSelection, valueSelection::ValueSelection, newConstraints=nothing)
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
    if !belowNodeLimit(model)
        return :NodeLimitStop
    end
    if !belowSolutionLimit(model)
        return :SolutionLimitStop
    end

    # Fix-point algorithm
    feasible, pruned = fixPoint!(model, newConstraints, prunedDomains)
    if !feasible
        return :Infeasible
    end
    if solutionFound(model)
        triggerFoundSolution!(model)
        return :FoundSolution
    end

    # Variable selection
    x = variableHeuristic(model)

    # Value selection
    v = valueSelection(DecisionPhase(), model, x, nothing)

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




"""
initroot!(toCall::Stack{Function}, ::ILDSearch, model::CPModel, variableHeuristic::AbstractVariableSelection, valueSelection::ValueSelection)

generic function to instantiate the research based on a specific Strategy <: SearchStrategy. The max discrepancy correspond to the number of branchable variables 
at the beginning of the search. Calls to expandIlds! with a decreasing discrepancy is stacked in the toCall Stack. 
"""
function initroot!(toCall::Stack{Function}, search::ILDSearch , model::CPModel, variableHeuristic::AbstractVariableSelection, valueSelection::ValueSelection)

    # Note that toCall stack is a LIFO data structure, expandIlds with a discrepancy threshold of 0 will be the first one to execute (then with 1, 2, 3, etc.)
    for k in search.d:-1:1
        push!(toCall, (model) -> (restart_search!(model); expandIlds!(toCall,k, model, variableHeuristic, valueSelection)))
    end
    return expandIlds!(toCall, 0, model, variableHeuristic, valueSelection,nothing)
end

"""
        expandIlds!(toCall::Stack{Function}, discrepancy::Int64, previousdepth::Int64, direction::Union{Nothing, Symbol} , model::CPModel, variableHeuristic::AbstractVariableSelection, valueSelection::ValueSelection, newConstraints=nothing)

This function fills the toCall Stack (LIFO) and perform a recursive Limited Discrepancy Search. Some procedures will contain a call to `expandIlds!` itself. Each `expandIlds!` 
call is wrapped around a `saveState!` and a `restoreState!` to be able to backtrack thanks to the trailer. 
    
This implementation is based on this paper : Limited Discrepancy Search - 1995 - William  D.  Harvey  and  Matthew  L.  Ginsberg. This method is not efficiant compared to the Korf approach but doesn't need any given max depth of the search 
tree, which is unknown for CP search tree.  
We should maybe look at this : https://www.researchgate.net/publication/220639800_Limited_discrepancy_search_revisited
"""
function expandIlds!(toCall::Stack{Function}, discrepancy::Int64, model::CPModel, variableHeuristic::AbstractVariableSelection, valueSelection::ValueSelection, newConstraints=nothing; prunedDomains::Union{CPModification,Nothing}=nothing)
    # Dealing with limits
    model.statistics.numberOfNodes += 1
    model.statistics.numberOfNodesBeforeRestart += 1

    if !belowNodeLimit(model)
        return :NodeLimitStop
    end
    if !belowSolutionLimit(model)
        return :SolutionLimitStop
    end
    # Fix-point algorithm
    feasible, pruned = fixPoint!(model, newConstraints, prunedDomains)
    model.statistics.lastPruning = sum(map(x-> length(x[2]),collect(pruned)))

    if !feasible
        model.statistics.numberOfInfeasibleSolutions += 1
        model.statistics.numberOfInfeasibleSolutionsBeforeRestart += 1

        return :Infeasible
    end
    if solutionFound(model)
        #TODO understand this 
        if (discrepancy == 0)
            triggerFoundSolution!(model)
            return :FoundSolution 
        end
        return :alreadyFoundSolution
    end
    # Variable selection
    x = variableHeuristic(model)
    # Value selection
    v = valueSelection(DecisionPhase, model, x)

    if (discrepancy>0)
    push!(toCall, (model) -> (restoreState!(model.trailer); :BackTracking))
    push!(toCall, (model) -> (
        prunedDomains = CPModification();
        addToPrunedDomains!(prunedDomains, x, remove!(x.domain, v));
        expandIlds!(toCall, discrepancy-1, model, variableHeuristic, valueSelection, getOnDomainChange(x), prunedDomains=prunedDomains)
    ))
    push!(toCall, (model) -> (saveState!(model.trailer); :SavingState))
    end
       
    push!(toCall, (model) -> (restoreState!(model.trailer); :BackTracking))
    push!(toCall, (model) -> (
        prunedDomains = CPModification();
        addToPrunedDomains!(prunedDomains, x, assign!(x, v));
        expandIlds!(toCall, discrepancy, model, variableHeuristic, valueSelection, getOnDomainChange(x), prunedDomains=prunedDomains)
    ))
    push!(toCall, (model) -> (saveState!(model.trailer); :SavingState))
    return :Feasible
end

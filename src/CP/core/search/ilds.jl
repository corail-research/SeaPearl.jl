


"""
initroot!(toCall::Stack{Function}, ::ILDSearch, model::CPModel, variableHeuristic::AbstractVariableSelection, valueSelection::ValueSelection)

generic function to instantiate the research based on a specific Strategy <: SearchStrategy. The max discrepancy correspond to the number of branchable variables 
at the beginning of the search. Calls to expandIlds! with a decreasing discrepancy is stacked in the toCall Stack. 
"""
function initroot!(toCall::Stack{Function}, ::ILDSearch , model::CPModel, variableHeuristic::AbstractVariableSelection, valueSelection::ValueSelection)
    isboundedlist = [!isbound(v) for (k,v) in model.variables]
    @assert !isempty(isboundedlist) "initialisation failed : no declared variables"
    depth = sum(isboundedlist)
    
    # Note that toCall stack is a LIFO data structure, expandIlds with a discrepancy threshold of 0 will be the first one to execute (then with 1, 2, 3, etc.)
    for k in depth:-1:1
        push!(toCall, (model) -> (restoreInitialState!(model.trailer); expandIlds!(toCall,k,depth, nothing, model, variableHeuristic, valueSelection)))
    end
    return expandIlds!(toCall,0,depth, nothing, model, variableHeuristic, valueSelection,nothing)
end

"""
        expandIlds!(toCall::Stack{Function}, discrepancy::Int64, previousdepth::Int64, direction::Union{Nothing, Symbol} , model::CPModel, variableHeuristic::AbstractVariableSelection, valueSelection::ValueSelection, newConstraints=nothing)

This function fills the toCall Stack (LIFO) and perform a recursive Limited Discrepancy Search. Some procedures will contain a call to `expandIlds!` itself. Each `expandIlds!` 
call is wrapped around a `saveState!` and a `restoreState!` to be able to backtrack thanks to the trailer. Depth is the virtual depth of the "bounding tree", and decrease as 
long as variables get bounded. Discrepancy is the virtual Discrepancy of the path in the "bounding tree". It is not updated each time the algorithm steps into the right sub-tree, but after
each right step that bounded one or more variable. ( after the fix-point algorithm ) This method allows to work with search tree where the depth ( and hence the max discrepancy ) 
is unknown.
    
This implementation is based on this paper : Improved Limited Discrepancy Search - 1996 - Richard E. Korf
"""
function expandIlds!(toCall::Stack{Function}, discrepancy::Int64, previousdepth::Int64, direction::Union{Nothing, Symbol} , model::CPModel, variableHeuristic::AbstractVariableSelection, valueSelection::ValueSelection, newConstraints=nothing; prunedDomains::Union{CPModification,Nothing}=nothing)
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
        model.statistics.numberOfInfeasibleSolutions += 1
        return :Infeasible
    end
    if solutionFound(model)
        if (direction ==:Left && discrepancy == 0)  || (direction ==:Right && discrepancy == 1 ) || isnothing(direction)
            triggerFoundSolution!(model) 
        end
        return :FoundSolution 
    end
    depth = sum([!isbound(v) for (k,v) in model.variables])  #recomputed at each step, maybe not efficient
    discrepancy =(depth != previousdepth && direction == :Right ) ? discrepancy - 1 : discrepancy   
    @assert depth > 0 "a least one variable should be branchable"
    # Variable selection
    x = variableHeuristic(model)
    # Value selection
    v = valueSelection(DecisionPhase, model, x)
    if (discrepancy>=0)   
        push!(toCall, (model) -> (restoreState!(model.trailer); :BackTracking))
        push!(toCall, (model) -> (
            prunedDomains = CPModification();
            addToPrunedDomains!(prunedDomains, x, remove!(x.domain, v));
            expandIlds!(toCall,discrepancy, depth, :Right, model, variableHeuristic, valueSelection, getOnDomainChange(x),prunedDomains=prunedDomains)
        ))
        push!(toCall, (model) -> (saveState!(model.trailer); :SavingState))
    end
    if (depth>discrepancy)
        push!(toCall, (model) -> (restoreState!(model.trailer); :BackTracking))
        push!(toCall, (model) -> (
            prunedDomains = CPModification();
            addToPrunedDomains!(prunedDomains, x, assign!(x, v));
            expandIlds!(toCall,discrepancy, depth-1, :Left, model, variableHeuristic, valueSelection, getOnDomainChange(x),prunedDomains=prunedDomains)
        ))
        push!(toCall, (model) -> (saveState!(model.trailer); :SavingState))
    end
    return :Feasible
end


function initroot!(toCall::Stack{Function}, ::Type{ILDSearch}, model::CPModel, variableHeuristic::AbstractVariableSelection, valueSelection::ValueSelection, newConstraints=nothing)
    isboundedlist = [!isbound(v) for (k,v) in model.variables]
    @assert !isempty(isboundedlist) "initialisation failed : no declared variables"
    depth = sum(isboundedlist)
    
    for k in depth:-1:1
        push!(toCall, (model) -> (nothing;expandIlds!(toCall,k,depth, nothing, model, variableHeuristic, valueSelection)))
    end
    return expandIlds!(toCall,0,depth, nothing, model, variableHeuristic, valueSelection)
end


function expandIlds!(toCall::Stack{Function}, discrepancy::Int64, previousdepth::Int64, direction::Union{Nothing, Symbol} , model::CPModel, variableHeuristic::AbstractVariableSelection, valueSelection::ValueSelection, newConstraints=nothing)
    # Dealing with limits
    model.statistics.numberOfNodes += 1
    if !belowNodeLimit(model)
        return :NodeLimitStop
    end
    if !belowSolutionLimit(model)
        return :SolutionLimitStop
    end

    # Fix-point algorithm
    feasible, pruned = fixPoint!(model, newConstraints)
    if !feasible
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
    v = valueSelection(DecisionPhase(), model, x, nothing)

    if (discrepancy>=0)   
        push!(toCall, (model) -> (restoreState!(model.trailer); :BackTracking))
        push!(toCall, (model) -> (remove!(x.domain, v); expandIlds!(toCall,discrepancy, depth, :Right, model, variableHeuristic, valueSelection, getOnDomainChange(x))))
        push!(toCall, (model) -> (saveState!(model.trailer); :SavingState))
    end

    if (depth>discrepancy)
        push!(toCall, (model) -> (restoreState!(model.trailer); :BackTracking))
        push!(toCall, (model) -> (assign!(x, v); expandIlds!(toCall,discrepancy, depth-1, :Left, model, variableHeuristic, valueSelection, getOnDomainChange(x))))
        push!(toCall, (model) -> (saveState!(model.trailer); :SavingState))
    end
    return :Feasible
end



"""
initroot!(toCall::Stack{Function}, ::Type{ILDSearch},model::CPModel, variableHeuristic::AbstractVariableSelection, valueSelection::ValueSelection, newConstraints=nothing)

Used as a generic function to instantiate the research based on a specific Strategy <: SearchStrategy. 
"""
function initroot!(toCall::Stack{Function}, ::Type{ILDSearch}, model::CPModel, variableHeuristic::AbstractVariableSelection, valueSelection::ValueSelection, newConstraints=nothing)
    
    depth = sum([v for (k,v)in model.branchable])
    println("hauteur de l'arbre de recherche : ", depth )
    
    for k in range depth:-1:1
        push!(toCall, (model) -> (;expandIlds!(toCall,k,depth, model, variableHeuristic, valueSelection)))
    end
    return expandIlds!(toCall,0,depth, model, variableHeuristic, valueSelection)
end


function expandIlds!(toCall::Stack{Function}, discrepancy::Int64, depth::Int64, model::CPModel, variableHeuristic::AbstractVariableSelection, valueSelection::ValueSelection, newConstraints=nothing)
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
        triggerFoundSolution!(model)
        return :FoundSolution 
    end

    # Variable selection
    x = variableHeuristic(model)

    # Value selection
    v = valueSelection(DecisionPhase(), model, x, nothing)
    #println("Value : ", v, " assigned to : ", x.id)

    if (discrepancy>0)
        push!(toCall, (model) -> (restoreState!(model.trailer); :BackTracking))
        push!(toCall, (model) -> (assign!(x, rand(x.domain.values)); expandILDS!(toCall,discrepancy-1, depth-1, model, variableHeuristic, valueSelection, getOnDomainChange(x))))
        push!(toCall, (model) -> (saveState!(model.trailer); :SavingState))
    end

    if (depth>discrepancy)
        push!(toCall, (model) -> (restoreState!(model.trailer); :BackTracking))
        push!(toCall, (model) -> (assign!(x, v); expandILDS!(toCall,discrepancy, depth-1, model, variableHeuristic, valueSelection, getOnDomainChange(x))))
        push!(toCall, (model) -> (saveState!(model.trailer); :SavingState))
    end

    return :Feasible
end
function solve!(model::CPModel, new_constraint::Array{Constraint}=nothing; variableHeuristic=selectVariable)
    if !belowLimits(model)
        return false
    end

    model.statistics.numberOfNodes += 1
    
    feasible, pruned = fixPoint!(model, new_constraint)
    
    if !feasible
        return false
    end
    if solutionFound(model)
        

        triggerFoundSolution!(model)
        return true
    end

    x = variableHeuristic(model)
    
    

    if isnothing(x)
        return false
    end
    foundASolution = false

    v = selectValue(x)


    
    saveState!(model.trailer)
    assign!(x, v)
    
    solve!(model, getOnDomainChange(x); variableHeuristic=variableHeuristic)
    restoreState!(model.trailer)

    saveState!(model.trailer)
    remove!(x.domain, v)
    
    solve!(model, getOnDomainChange(x); variableHeuristic=variableHeuristic)
    restoreState!(model.trailer)
    return false
end

function selectVariable(model::CPModel)
    selectedVar = nothing
    minSize = typemax(Int)
    for (k, x) in model.variables
        if length(x.domain) > 1 && length(x.domain) < minSize
            selectedVar = x
            minSize = length(x.domain)
        end
    end
    # @assert !isnothing(selectedVar)
    return selectedVar
end
function solve!(model::CPModel, new_constraint=nothing; variableHeuristic=selectVariable)
    
    feasible, pruned = fixPoint!(model, new_constraint)
    
    if !feasible
        return false
    end
    if solutionFound(model)
        solution = Solution()
        for (k, x) in model.variables
            solution[k] = x.domain.min.value
        end
        push!(model.solutions, solution)
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
    
    if solve!(model, x.onDomainChange; variableHeuristic=variableHeuristic)
        return true
    end
    restoreState!(model.trailer)

    saveState!(model.trailer)
    remove!(x.domain, v)
    
    if solve!(model, x.onDomainChange; variableHeuristic=variableHeuristic)
        return true
    end
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
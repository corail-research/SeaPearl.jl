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



    
    withNewState!(model.trailer) do

        assign!(x, v)
        
        if solve!(model, x.onDomainChange; variableHeuristic=variableHeuristic)
            foundASolution = true
        end
    end
    if foundASolution
        return true
    end
    withNewState!(model.trailer) do

        remove!(x.domain, v)
        
        if solve!(model, x.onDomainChange; variableHeuristic=variableHeuristic)
            foundASolution = true
        end

    end
    return foundASolution
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
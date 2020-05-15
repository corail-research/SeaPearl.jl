function solve!(model::CPModel, new_constraint=nothing)
    
    feasible, pruned = fixPoint!(model, new_constraint)
    
    if !feasible
        # println("Not feasible !")
        return false
    end
    if solutionFound(model)
        # feasible, pruned = fixPoint!(model)
        # for i in 1:length(keys(model.variables))
        #     println(model.variables[string(i)])
        # end
        # println(model.constraints[1])

        # if !feasible
        #     return false
        # end
        solution = Solution()
        for (k, x) in model.variables
            solution[k] = x.domain.min.value
        end
        push!(model.solutions, solution)
        return true
    end

    x = selectVariable(model)
    
    

    if isnothing(x)
        return false
    end
    foundASolution = false


    for v in x.domain.min.value:x.domain.max.value

        if foundASolution
            return true
        end
        if v in x.domain
            withNewState!(model.trailer) do

                assign!(x, v)
                
                if solve!(model, x.onDomainChange)
                    foundASolution = true
                end
            end
        end
    end
    
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
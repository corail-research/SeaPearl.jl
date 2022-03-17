using StatsBase: sample

"""
Used as a generic function to instantiate the research based on a specific Strategy <: SearchStrategy. 
"""
function initroot!(toCall::Stack{Function}, search::LNSearch, model::CPModel, variableHeuristic::AbstractVariableSelection, valueSelection::ValueSelection)
    return expandLns!(search, model, variableHeuristic, valueSelection)
end

"""
This function make a Large Neighboorhood Search. As initial solution we use the first feasible solution found by a DFS. 
Then a destroy and repair loop tries to upgrade the current solution until some stop critiria.
"""
function expandLns!(search::LNSearch, model::CPModel, variableHeuristic::AbstractVariableSelection, valueSelection::ValueSelection)

    # Make sure that the model is consistent with a LNS
    @assert !isnothing(model.objective)
    @assert isnothing(model.limit.numberOfNodes)
    @assert isnothing(model.limit.numberOfSolutions)
    @assert search.limitIterNoImprovement ≥ 1

    tic()
    globalTimeLimit = model.limit.searchingTime 
    objective = model.objective.id
    optimalScoreLowerBound = model.variables[objective].domain.min.value

    ### Get first solution using DFS ###

    model.limit.numberOfSolutions = 1
    status = search!(model, DFSearch(), variableHeuristic, valueSelection)
    model.limit.numberOfSolutions = nothing
    model.limit.searchingTime = nothing
    if status ∈ [:TimeLimitStop, :Infeasible, :Optimal]
        return status
    end
    currentSolution = model.statistics.solutions[findfirst(e -> !isnothing(e), model.statistics.solutions)]
    bestSolution = currentSolution
    
    ### Set parameters ###
    
    # `numberOfValuesToRemove` is initialised to 1 and increase by 1 after `limitIterNoImprovement` iterations 
    # with no improvement until `limitValuesToRemove` is reached.
    numberOfValuesToRemove = 1
    nbIterNoImprovement = 0

    # Upper bound of the number of values to be removed (set by user or as half of the branching variables by default)
    if isnothing(search.limitValuesToRemove)
        limitValuesToRemove = convert(Int, round(count(values(model.branchable))/2))
    else
        @assert search.limitValuesToRemove ≤ count(values(model.branchable))
        limitValuesToRemove = search.limitValuesToRemove
    end

    # Search strategie for repairing (set by user or DFS by default)
    repairSearch = search.repairSearch

    # Limits for repairing search (set by user or nothing by default)
    if !isnothing(search.repairLimits)
        for (key, value) in search.repairLimits
            setfield!(model.limit, Symbol(key), value)
        end
    end
    localSearchTimeLimit = model.limit.searchingTime

    ### Destroy and repair loop ###

    while (isnothing(globalTimeLimit) || peektimer() < globalTimeLimit) && bestSolution[objective] > optimalScoreLowerBound
        # Update searchingTime to ensure that time limits are respected
        if !isnothing(globalTimeLimit) 
            if !isnothing(localSearchTimeLimit) 
                model.limit.searchingTime = min(convert(Int64, round(globalTimeLimit - peektimer())), localSearchTimeLimit)
            else
                model.limit.searchingTime = convert(Int64, round(globalTimeLimit - peektimer()))
            end
        end

        tempSolution = repair!(destroy!(model, currentSolution, numberOfValuesToRemove, objective), repairSearch, objective, variableHeuristic, valueSelection)

        nbIterNoImprovement += 1
        if search.limitIterNoImprovement ≤ nbIterNoImprovement && numberOfValuesToRemove < limitValuesToRemove
            numberOfValuesToRemove += 1
            nbIterNoImprovement = 0
        end

        if !isnothing(tempSolution)
            if accept(tempSolution, currentSolution, objective)
                currentSolution = tempSolution
                nbIterNoImprovement = 0
            end
            if compare(tempSolution, bestSolution, objective)
                bestSolution = tempSolution
            end
        end
    end

    # Make sure that model has `bestSolution`
    if bestSolution ∉ model.statistics.solutions
        push!(model.statistics.solutions, bestSolution)
    end

    return bestSolution[objective] > optimalScoreLowerBound ? :NonOptimal : :Optimal
end

"""
Decide if we update the current solution with the neighboor solution get by destroy and repair (tempSolution)
"""
function accept(tempSolution, currentSolution, objective)
    return tempSolution[objective] < currentSolution[objective]
end

"""
Comparare the objective variable from tempSolution and bestSolution
"""
function compare(tempSolution, bestSolution, objective)
    return tempSolution[objective] < bestSolution[objective]
end

"""
Use the `repairSearch` to try to repair the destoyed solution 
"""
function repair!(model, repairSearch, objective, variableHeuristic, valueSelection)
    search!(model, repairSearch, variableHeuristic, valueSelection)
    solutions = filter(e -> !isnothing(e), model.statistics.solutions)

    if isempty(solutions)
        toReturn = nothing
    else
        scores = map(solution -> solution[objective], solutions)
        bestSolution = solutions[findfirst(score -> score == Base.minimum(scores), scores)]
        toReturn = bestSolution
    end
    return toReturn
end

"""
Reset to initial state `numberOfValuesToRemove` branchable variables and prune the objective domain to force the search for a better solution
"""
function destroy!(model, solution, numberOfValuesToRemove, objective)
    
    # Reset model
    objectiveBound = solution[objective] - 1
    SeaPearl.reset_model!(model)

    # Get variable fixed by current solution
    vars = collect(values(model.variables))
    branchableVariablesId = collect(filter(e -> model.branchable[e], keys(model.branchable)))
    varsToSet = sample(branchableVariablesId, count(values(model.branchable)) - numberOfValuesToRemove; replace=false)

    # Fix some variables as in current solution
    for var in varsToSet
        variable = vars[findfirst(e -> e.id == var, vars)]
        value = solution[var]
        SeaPearl.assign!(variable, value)
    end

    # Pruning the objective domain to force the search for a better solution
    objectiveVariable = vars[findfirst(e -> e.id == objective, vars)]
    SeaPearl.removeAbove!(objectiveVariable.domain, objectiveBound)

    return model
end


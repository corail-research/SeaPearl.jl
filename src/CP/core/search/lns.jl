using StatsBase: sample
using Random 
const Solution = Dict{String, Union{Int, Bool, Set{Int}}}

"""
initroot!(toCall::Stack{Function}, search::LNSearch, model::CPModel, variableHeuristic::AbstractVariableSelection, valueSelection::ValueSelection)

Used as a generic function to instantiate the research based on a specific Strategy <: SearchStrategy. 

    # Arguments
- toCall: In this search strategy, `toCall` is not used (an empty stack will be returned)
- search: Object containing the parameters of the search strategy
- model: CPModel to be solved
- variableHeuristic: Variable selection method to be used in the search
- valueSelection: Value selection method to be used in the search
"""
function initroot!(toCall::Stack{Function}, search::LNSearch, model::CPModel, variableHeuristic::AbstractVariableSelection, valueSelection::ValueSelection)
    return expandLns!(search, model, variableHeuristic, valueSelection)
end

"""
expandLns!(search::LNSearch, model::CPModel, variableHeuristic::AbstractVariableSelection, valueSelection::ValueSelection)

This function make a Large Neighbourhood Search. As initial solution we use the first feasible solution found by a DFS. 
Then a destroy and repair loop tries to upgrade the current solution until some stop critiria.

    # Arguments
- search: Object containing the parameters of the search strategy
- model: CPModel to be solved
- variableHeuristic: Variable selection method to be used in the search
- valueSelection: Value selection method to be used in the search
"""
function expandLns!(search::LNSearch, model::CPModel, variableHeuristic::AbstractVariableSelection, valueSelection::ValueSelection)

    # Make sure that the model is consistent with a LNS
    @assert !isnothing(model.objective)
    @assert isnothing(model.limit.numberOfNodes)
    @assert isnothing(model.limit.numberOfSolutions)
    @assert search.limitIterNoImprovement ≥ 1

    tic()
    globalTimeLimit = model.limit.searchingTime 
    objectiveId = model.objective.id
    optimalScoreLowerBound = model.variables[objectiveId].domain.min.value

    if !isnothing(search.seed)
        Random.seed!(search.seed)
    end

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
    println("first solution: ", bestSolution[objectiveId])
    
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

    while (isnothing(globalTimeLimit) || peektimer() < globalTimeLimit) && bestSolution[objectiveId] > optimalScoreLowerBound
        # Update searchingTime to ensure that time limits are respected
        if !isnothing(globalTimeLimit) 
            if !isnothing(localSearchTimeLimit) 
                model.limit.searchingTime = min(convert(Int64, round(globalTimeLimit - peektimer())), localSearchTimeLimit)
            else
                model.limit.searchingTime = convert(Int64, round(globalTimeLimit - peektimer()))
            end
        end

        tempSolution = repair!(destroy!(model, currentSolution, numberOfValuesToRemove, objectiveId), repairSearch, objectiveId, variableHeuristic, valueSelection)

        nbIterNoImprovement += 1
        if search.limitIterNoImprovement ≤ nbIterNoImprovement && numberOfValuesToRemove < limitValuesToRemove
            numberOfValuesToRemove += 1
            nbIterNoImprovement = 0
        end

        if !isnothing(tempSolution)
            if accept(tempSolution, currentSolution, objectiveId)
                currentSolution = tempSolution
                nbIterNoImprovement = 0
            end
            if compare(tempSolution, bestSolution, objectiveId)
                bestSolution = tempSolution
                println("better solution: ", bestSolution[objectiveId])
            end
        end
    end

    # Make sure that model has `bestSolution`
    if bestSolution ∉ model.statistics.solutions
        push!(model.statistics.solutions, bestSolution)
    end

    return bestSolution[objectiveId] > optimalScoreLowerBound ? :NonOptimal : :Optimal
end

"""
accept(tempSolution::Solution, currentSolution::Solution, objectiveId::String)

Decide if we update the current solution with the neighbour solution get by destroy and repair (tempSolution).
In this implementation, accept() and compare() have exactly the same behavior. In other versions of LNS, 
accept() can be different (e.g. stochastic behavior as simulated annealing).

    # Arguments
- tempSolution: Solution found by the destroy and repair loop
- currentSolution: Solution used as input in the destroy and repair loop 
- objectiveId: Id of the objective variable
"""
function accept(tempSolution::Solution, currentSolution::Solution, objectiveId::String)
    return tempSolution[objectiveId] < currentSolution[objectiveId]
end

"""
compare(tempSolution::Solution, bestSolution::Solution, objectiveId::String)

Comparare the objective variable value from tempSolution and bestSolution

    # Arguments
- tempSolution: Solution given as output by the destroy and repair loop
- bestSolution: Best solution found so far
- objectiveId: Id of the objective variable
"""
function compare(tempSolution::Solution, bestSolution::Solution, objectiveId::String)
    return tempSolution[objectiveId] < bestSolution[objectiveId]
end

"""
repair!(model::CPModel, repairSearch::SearchStrategy, objectiveId::String, variableHeuristic::AbstractVariableSelection, valueSelection::ValueSelection)

Use the `repairSearch` to try to repair the destoyed model 

    # Arguments
- model: CPModel with assigned and non-assigned variables
- repairSearch: Search strategy to be applied to `model`
- objectiveId: Id of the objective variable
- variableHeuristic: Variable selection method to be used in the search
- valueSelection: Value selection method to be used in the search
"""
function repair!(model::CPModel, repairSearch::SearchStrategy, objectiveId::String, variableHeuristic::AbstractVariableSelection, valueSelection::ValueSelection)
    search!(model, repairSearch, variableHeuristic, valueSelection)
    solutions = filter(e -> !isnothing(e), model.statistics.solutions)

    if isempty(solutions)
        toReturn = nothing
    else
        scores = map(solution -> solution[objectiveId], solutions)
        bestSolution = solutions[findfirst(score -> score == Base.minimum(scores), scores)]
        toReturn = bestSolution
    end
    return toReturn
end

"""
destroy!(model::CPModel, solution::Solution, numberOfValuesToRemove::Int, objectiveId::String)

Reset to initial state `numberOfValuesToRemove` branchable variables and prune the objective domain to force the search for a better solution

    # Arguments
- model: CPModel that will be reset and partially reconstructed with values from `solution`
- solution: Dict{variable => value} containing a solution to the model
- numberOfValuesToRemove: number of branchable variables to set to their initial state 
- objectiveId: id of the objective variable
"""
function destroy!(model::CPModel, solution::Solution, numberOfValuesToRemove::Int, objectiveId::String)
    
    # Reset model
    objectiveBound = solution[objectiveId] - 1
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
    objectiveVariable = vars[findfirst(e -> e.id == objectiveId, vars)]
    SeaPearl.removeAbove!(objectiveVariable.domain, objectiveBound)

    return model
end


using StatsBase: sample

"""
Used as a generic function to instantiate the research based on a specific Strategy <: SearchStrategy. 
"""
function initroot!(toCall::Stack{Function}, search::LNSearch, model::CPModel, variableHeuristic::AbstractVariableSelection, valueSelection::ValueSelection)
    return expandLns!(toCall, search, model, variableHeuristic, valueSelection)
end

"""
This function make a Large Neighboorhood Search. As initial solution we use the first feasible solution found by a DFS. 
Then a destroy and repair loop tries to upgrade the current solution until some stop critiria.
"""
function expandLns!(toCall::Stack{Function}, search::LNSearch, model::CPModel, variableHeuristic::AbstractVariableSelection, valueSelection::ValueSelection, newConstraints=nothing; prunedDomains::Union{CPModification,Nothing}=nothing)
    tic()
    timeLimit = model.limit.searchingTime 
    model.limit.searchingTime = nothing

    objective = model.objective.id
    optimalScore = model.variables[objective].domain.min.value

    ### Get first solution using DFS ###
    model.limit.numberOfSolutions = 1
    status = search!(model, DFSearch(), variableHeuristic, valueSelection)
    if status == :Infeasible
        return :Infeasible
    end
    model.limit.numberOfSolutions = nothing
    currentSolution = model.statistics.solutions[findfirst(e -> !isnothing(e), model.statistics.solutions)]
    bestSolution = currentSolution
    bestModel = model
    println("First solution: ", currentSolution[objective])
    
    ### Set parameters ###
    
    # increase by 1 after `limitIterNoImprovement` iterations with no improvement
    numberOfValuesToRemove = 1
    nbIterNoImprovement = 0

    # Upper bound of the number of values to be removed (set ny user or as half of the branching variables by default)
    if isnothing(search.limitValuesToRemove)
        limitValuesToRemove = convert(Int, round(length(collect(filter(e -> model.branchable[e], keys(model.branchable))))/2))
    else
        limitValuesToRemove = search.limitValuesToRemove
    end

    ### Destroy and repair loop ###
    while isnothing(timeLimit) || peektimer() < timeLimit
        # use timeLeft as timeLimit in the repairing search to ensure that timeLimit is respected
        timeLeft = isnothing(timeLimit) ? nothing : timeLimit - peektimer()
        nbIterNoImprovement += 1
        if search.limitIterNoImprovement < nbIterNoImprovement && numberOfValuesToRemove < limitValuesToRemove
            numberOfValuesToRemove += 1
            nbIterNoImprovement = 0
        end
        tempSolution = repair(destroy(model, timeLeft, currentSolution, numberOfValuesToRemove, objective, optimalScore))

        if !isnothing(tempSolution)
            if accept(tempSolution, currentSolution, objective)
                println("update current solution: ", tempSolution[objective])
                currentSolution = tempSolution
                nbIterNoImprovement = 0
            else
                nbIterNoImprovement +=1
            end
            if compare(tempSolution, bestSolution, objective)
                println("update best solution", tempSolution[objective])
                bestSolution = tempSolution
                bestModel = model

                # Stop search if optimal solution found
                if bestSolution[objective] == optimalScore
                    break
                end
            end
        end
    end
    return :Feasible
end

"""
Decide if we update the current solution with the neighboor solution get by destroy and repair (tempSolution)
"""
function accept(tempSolution, currentSolution, objective)
    # try a sort of simulated annealing?
    return tempSolution[objective] < currentSolution[objective]
end

"""
Comparare the objective variable from tempSolution and bestSolution
"""
function compare(tempSolution, bestSolution, objective)
    # try a sort of simulated annealing?
    return tempSolution[objective] < bestSolution[objective]
end

"""
Use a DFS to find the optimal solution to the repair problem
"""
function repair(model)
    # TODO chose another method as argument
    search!(model, DFSearch(), MinDomainVariableSelection(), BasicHeuristic())
    solutions = filter(e -> !isnothing(e), model.statistics.solutions)
    if isempty(solutions)
        toReturn = nothing
    else
        toReturn = pop!(solutions)
    end
    return toReturn
end

"""
Reset to initial state `numberOfValuesToRemove` branchable variables
"""
function destroy(model, timeLeft, solution, numberOfValuesToRemove, objective, optimalScore)

    # Reset model
    initialScore = model.objectiveBound #solution[objective]
    SeaPearl.reset_model!(model)
    model.limit.searchingTime = convert(Int, round(timeLeft))

    # Get variable fixed by current solution
    vars = collect(values(model.variables))
    branchableVariablesId = collect(filter(e -> model.branchable[e], keys(model.branchable)))
    varsToSet = sample(branchableVariablesId, numberOfValuesToRemove; replace=false)

    # Fix some variables as in current solution
    for var in varsToSet
        variable = vars[findfirst(e -> e.id == var, vars)]
        value = solution[var]
        SeaPearl.assign!(variable, value)
    end

    # Pruning the objective domain to force the search for a better solution (TODO? is this a good idea)
    # TODO new constraint
    objectiveVariable = vars[findfirst(e -> e.id == objective, vars)]
    # objectiveUpperBound = max(initialScore - 1, optimalScore)
    SeaPearl.removeAbove!(objectiveVariable.domain, initialScore)

    return model
end


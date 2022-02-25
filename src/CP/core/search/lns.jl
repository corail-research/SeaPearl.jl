using StatsBase: sample

"""
Used as a generic function to instantiate the research based on a specific Strategy <: SearchStrategy. 
"""
function initroot!(toCall::Stack{Function}, ::LNSearch, model::CPModel, variableHeuristic::AbstractVariableSelection, valueSelection::ValueSelection)
    return expandLns!(toCall, model, variableHeuristic, valueSelection)
end

"""
This function make a Large Neighboorhood Search. As initial solution we use the first feasible solution found by a DFS. 
Then a destroy and repair loop tries to upgrade the current solution until some stop critiria.
"""
function expandLns!(toCall::Stack{Function}, model::CPModel, variableHeuristic::AbstractVariableSelection, valueSelection::ValueSelection, newConstraints=nothing; prunedDomains::Union{CPModification,Nothing}=nothing)
    
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
    
    ### Set constants ###
    objective = model.objective.id
    println("First solution: ", currentSolution[objective])

    # increase by 1 after `limitIterNoImprovement` iterations with no improvement
    numberOfValuesToRemove = 1
    nbIterNoImprovement = 0

    #fix param
    limitValuesToRemove = convert(Int, round(length(collect(filter(e -> model.branchable[e], keys(model.branchable))))/2))

    #TODO fix param
    limitIterNoImprovement = 100

    nbIter = 0

    #TODO fix param
    limitIter = 500 

    ### Destroy and repair loop ###
    #TODO another stop criteria? Or no stopping criteria (eventually those defined in the model)?
    #TODO detect optimal solution
    while nbIter < limitIter
        nbIter += 1
        nbIterNoImprovement += 1

        if limitIterNoImprovement < nbIterNoImprovement && numberOfValuesToRemove < limitValuesToRemove
            numberOfValuesToRemove += 1
            nbIterNoImprovement = 0
        end
        tempSolution = repair(destroy(model, currentSolution, numberOfValuesToRemove))

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
    # TODO try an heuristic repair?
    # TODO avoid get same solution as current solution (reducing the objective variable by 1)
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
function destroy(model, solution, numberOfValuesToRemove)

    # Reset model
    SeaPearl.reset_model!(model)

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

    return model
end


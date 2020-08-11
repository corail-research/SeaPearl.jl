
"""
    search!(model::CPModel, ::Type{DFSearch}, variableHeuristic, valueSelection::ValueSelection=BasicHeuristic())

Perform a Depth-First search in the `model` using `variableHeuristic` to choose which domain will be changed
at each branching and using `valueSelection` to choose how the branching will be done. 
This strategy, starting at the root node, will explore as deep as possible before backtracking.
"""
function search!(model::CPModel, ::Type{DFSearch}, variableHeuristic::AbstractVariableSelection, valueSelection::ValueSelection=BasicHeuristic(), out_solver::Bool=false)

    # create env and get first observation
    valueSelection(InitializingPhase(), model, nothing, nothing)

    toCall = Stack{Function}()

    # Starting at the root node with an empty stack
    currentStatus = expandDfs!(toCall, model, variableHeuristic, valueSelection)
    
    while !isempty(toCall)
        # Stop right away if reached a limit
        if currentStatus == :NodeLimitStop || currentStatus == :SolutionLimitStop || (out_solver && (currentStatus in [:Infeasible, :FoundSolution]))
            break
        end

        if currentStatus != :SavingState
            # set reward and metrics
            valueSelection(StepPhase(), model, nothing, currentStatus)
        end

        currentProcedure = pop!(toCall)
        currentStatus = currentProcedure(model)
    end

    # set final reward and last observation
    valueSelection(EndingPhase(), model, nothing, nothing)

    if currentStatus == :NodeLimitStop || currentStatus == :SolutionLimitStop || (out_solver & (currentStatus in [:Infeasible, :FoundSolution]))
        return currentStatus
    end
    

    if length(model.solutions) > 0
        return :Optimal
    end

    return :Infeasible
end

"""
    expandDfs!(toCall::Stack{Function}, model::CPModel, variableHeuristic::Function, valueSelection::ValueSelection, newConstraints=nothing)

Add procedures to `toCall`, that, called in the stack order (LIFO) with the `model` parameter, will perform a DFS in the graph.
Some procedures will contain a call to `expandDfs!` itself. Each `expandDfs!` call is wrapped around a `saveState!` and a `restoreState!` to be
able to backtrack thanks to the trailer.
"""
function expandDfs!(toCall::Stack{Function}, model::CPModel, variableHeuristic::AbstractVariableSelection, valueSelection::ValueSelection, newConstraints=nothing)
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

    push!(toCall, (model) -> (restoreState!(model.trailer); :BackTracking))
    push!(toCall, (model) -> (remove!(x.domain, v); expandDfs!(toCall, model, variableHeuristic, valueSelection, getOnDomainChange(x))))
    push!(toCall, (model) -> (saveState!(model.trailer); :SavingState))

    push!(toCall, (model) -> (restoreState!(model.trailer); :BackTracking))
    push!(toCall, (model) -> (assign!(x, v); expandDfs!(toCall, model, variableHeuristic, valueSelection, getOnDomainChange(x))))
    push!(toCall, (model) -> (saveState!(model.trailer); :SavingState))

    return :Feasible
end

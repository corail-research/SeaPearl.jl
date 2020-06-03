abstract type DFSearch <: SearchStrategy end

"""
    search!(model::CPModel, ::Type{DFSearch}, variableHeuristic)

Perform a Depth-First search in the `model` using `variableHeuristic` to choose which domain will be changed
at each branching. This strategy, starting at the root node, will explore as deep as possible before backtracking.
"""
function search!(model::CPModel, ::Type{DFSearch}, variableHeuristic)
    toCall = Stack{Function}()

    # Starting at the root node with an empty stack
    currentStatus = expandDfs!(toCall, model, variableHeuristic)
    
    while !isempty(toCall)
        # Stop right away if reached a limit
        if currentStatus == :NodeLimitStop || currentStatus == :SolutionLimitStop
            break
        end

        currentProcedure = pop!(toCall)
        currentStatus = currentProcedure(model)
    end

    if currentStatus == :NodeLimitStop || currentStatus == :SolutionLimitStop
        return currentStatus
    end
    

    if length(model.solutions) > 0
        return :Optimal
    end

    return :Infeasible
end

"""
    expandDfs!(toCall::Stack{Function}, model::CPModel, variableHeuristic::Function, newConstraints=nothing)

Add procedures to `toCall`, that, called in the stack order (LIFO) with the `model` parameter, will perform a DFS in the graph.
Some procedures will contain a call to `expandDfs!` itself.
"""
function expandDfs!(toCall::Stack{Function}, model::CPModel, variableHeuristic::Function, newConstraints=nothing)
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
        return :Feasible
    end

    # Variable selection
    x = variableHeuristic(model)

    # Value selection
    v = selectValue(x)


    push!(toCall, (model) -> (restoreState!(model.trailer); :Feasible))
    push!(toCall, (model) -> (remove!(x.domain, v); expandDfs!(toCall, model, variableHeuristic, getOnDomainChange(x))))
    push!(toCall, (model) -> (saveState!(model.trailer); :Feasible))

    push!(toCall, (model) -> (restoreState!(model.trailer); :Feasible))
    push!(toCall, (model) -> (assign!(x, v); expandDfs!(toCall, model, variableHeuristic, getOnDomainChange(x))))
    push!(toCall, (model) -> (saveState!(model.trailer); :Feasible))

    return :Feasible
end

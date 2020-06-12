abstract type DFSearch <: SearchStrategy end

"""
    search!(model::CPModel, ::Type{DFSearch}, variableHeuristic)

Perform a Depth-First search in the `model` using `variableHeuristic` to choose which domain will be changed
at each branching. This strategy, starting at the root node, will explore as deep as possible before backtracking.
"""
function search!(model::CPModel, ::Type{DFSearch}, variableHeuristic)

    # the agent will probably be given as a parameter of the search function

    # create the environment (will be under valueSelection later)
    # env = RLEnv(model::CPModel)

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

    # in our framework, the changesare made by the cpmodel, thus, the env do not launch the 
    # changes, that is why there is no env(action) here but there is a synchronisation of the env with
    # the cpmodel: sync!(env, model, x)
    # sync!(env, model, x)

    # obs = observe(env, x)
    # agent(POST_ACT_STAGE, obs) # get terminal and reward
    # eventually: hook(POST_ACT_STAGE, agent, env, obs, action)

    # v = agent(PRE_ACT_STAGE, obs) # choose action, store it with the state
    # eventually hook(PRE_ACT_STAGE, agent, env, obs, action)

    
    # Value selection
    v = selectValue(x) # will disappear


    push!(toCall, (model) -> (restoreState!(model.trailer); :Feasible))
    push!(toCall, (model) -> (remove!(x.domain, v); expandDfs!(toCall, model, variableHeuristic, getOnDomainChange(x))))
    push!(toCall, (model) -> (saveState!(model.trailer); :Feasible))

    push!(toCall, (model) -> (restoreState!(model.trailer); :Feasible))
    push!(toCall, (model) -> (assign!(x, v); expandDfs!(toCall, model, variableHeuristic, getOnDomainChange(x))))
    push!(toCall, (model) -> (saveState!(model.trailer); :Feasible))

    return :Feasible
end

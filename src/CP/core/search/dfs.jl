
"""
    search!(model::CPModel, ::Type{DFSearch}, variableHeuristic, valueSelection::ValueSelection=BasicHeuristic())

Perform a Depth-First search in the `model` using `variableHeuristic` to choose which domain will be changed
at each branching. This strategy, starting at the root node, will explore as deep as possible before backtracking.
"""
function search!(model::CPModel, ::Type{DFSearch}, variableHeuristic, valueSelection::ValueSelection=BasicHeuristic())

    if require_env(valueSelection)
        # create the environment
        valueSelection.current_env = RLEnv(model::CPModel)
        false_x = first(values(model.variables))
        obs = observe!(valueSelection.env, model, false_x)
        valueSelection.agent(RL.PRE_EPISODE_STAGE, obs) # just empty the buffer
        # eventually hook(PRE_EPISODE_STAGE, agent, env, obs)
    end

    # the first decision will be taken after the first call at the fixPoint!
    # consequently, we do nothing here nothing here 

    toCall = Stack{Function}()

    # Starting at the root node with an empty stack
    currentStatus = expandDfs!(toCall, model, variableHeuristic, valueSelection)
    
    while !isempty(toCall)
        # Stop right away if reached a limit
        if currentStatus == :NodeLimitStop || currentStatus == :SolutionLimitStop
            break
        end

        # the RL EPISODE continue
        # change reward in case of :Unfeasible status (I would like it for :FoundSolution if possible)
        # if is unnecessary but i keep it for visual issue atm 
        if require_env(valueSelection) && currentStatus in [:Unfeasible, :FoundSolution]
            set_reward!(valueSelection.current_env, currentStatus)
            # when we go back to expandDfs, env will be able to add the reward to the observation
        end

        currentProcedure = pop!(toCall)
        currentStatus = currentProcedure(model)
    end

    if require_env(valueSelection)
        # the RL EPISODE stops
        set_done!(valueSelection.current_env, true)
        set_final_reward!(valueSelection.current_env, model)
        obs = observe!(valueSelection.current_env, model, false_x)
    
        valueSelection.agent(RL.POST_ACT_STAGE, obs) # get terminal and reward
        # eventually: hook(POST_ACT_STAGE, agent, env, obs, action)
    
        valueSelection.agent(RL.POST_EPISODE_STAGE, obs)  # let the agent see the last observation
        # eventually hook(POST_EPISODE_STAGE, agent, env, obs)
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
    expandDfs!(toCall::Stack{Function}, model::CPModel, variableHeuristic::Function, valueSelection::ValueSelection, newConstraints=nothing)

Add procedures to `toCall`, that, called in the stack order (LIFO) with the `model` parameter, will perform a DFS in the graph.
Some procedures will contain a call to `expandDfs!` itself.
"""
function expandDfs!(toCall::Stack{Function}, model::CPModel, variableHeuristic::Function, valueSelection::ValueSelection, newConstraints=nothing)
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
        #return :FoundSolution
        return :Feasible
    end

    # All the transformations due to the next action have been done 

    # Variable selection
    x = variableHeuristic(model)

    if require_env(valueSelection)
        obs = observe!(valueSelection.current_env, model, x)
        if model.statistics.numberOfNodes > 1
            valueSelection.agent(RL.POST_ACT_STAGE, obs) # get terminal and reward
            # eventually: hook(POST_ACT_STAGE, agent, env, obs, action)
        end
        v = valueSelection.agent(RL.PRE_ACT_STAGE, obs) # choose action, store it with the state
        # eventually hook(PRE_ACT_STAGE, agent, env, obs, action)
    else
        v = valueSelection.selectValue(x)
    end
    # here we should check if we are still in the game ! But by definition, we are in it.
    # the hard part are the :Infeasible, as they are not here even if still in the game !


    push!(toCall, (model) -> (restoreState!(model.trailer); :Feasible))
    push!(toCall, (model) -> (remove!(x.domain, v); expandDfs!(toCall, model, variableHeuristic, valueSelection, getOnDomainChange(x))))
    push!(toCall, (model) -> (saveState!(model.trailer); :Feasible))

    push!(toCall, (model) -> (restoreState!(model.trailer); :Feasible))
    push!(toCall, (model) -> (assign!(x, v); expandDfs!(toCall, model, variableHeuristic, valueSelection, getOnDomainChange(x))))
    push!(toCall, (model) -> (saveState!(model.trailer); :Feasible))

    return :Feasible
end

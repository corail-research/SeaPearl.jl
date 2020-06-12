abstract type DFSearch <: SearchStrategy end

"""
    search!(model::CPModel, ::Type{DFSearch}, variableHeuristic, agent::RL.Agent)

Perform a Depth-First search in the `model` using `variableHeuristic` to choose which domain will be changed
at each branching. This strategy, starting at the root node, will explore as deep as possible before backtracking.
"""
function search!(model::CPModel, ::Type{DFSearch}, variableHeuristic, agent::RL.Agent)

    # the agent will probably be given as a parameter of the search function

    # create the environment: state is taken randomly but will be synchronized later
    env = RLEnv(model::CPModel)
    false_x = first(values(model.variables))
    sync_state!(env, model, false_x)
    obs = observe(env, false_x)
    agent(RL.PRE_EPISODE_STAGE, obs) # just empty the buffer
    # eventually hook(PRE_EPISODE_STAGE, agent, env, obs)

    # the first decision will be taken after the first call at the fixPoint!
    # nothing here 

    toCall = Stack{Function}()

    # Starting at the root node with an empty stack
    currentStatus = expandDfs!(toCall, model, variableHeuristic, env, agent)
    
    while !isempty(toCall)
        # Stop right away if reached a limit
        if currentStatus == :NodeLimitStop || currentStatus == :SolutionLimitStop
            break
        end

        # the RL EPISODE continue
        # change reward in case of :Unfeasible status (I would like it for :FoundSolution if possible)
        # if is unnecessary but i keep it for visual issue atm 
        if currentStatus in [:Unfeasible, :FoundSolution]
            set_reward!(env, currentStatus)
            # when we go back to expandDfs, env will be able to add the reward to the observation
        end

        currentProcedure = pop!(toCall)
        currentStatus = currentProcedure(model)
    end

    # the RL EPISODE stops
    set_done!(env, true)
    set_final_reward!(env, model)
    sync_state!(env, model, false_x)
    obs = observe(env, false_x)
    
    agent(RL.POST_ACT_STAGE, obs) # get terminal and reward
    # eventually: hook(POST_ACT_STAGE, agent, env, obs, action)
    
    agent(RL.POST_EPISODE_STAGE, obs)  # let the agent see the last observation
    # eventually hook(POST_EPISODE_STAGE, agent, env, obs)

    if currentStatus == :NodeLimitStop || currentStatus == :SolutionLimitStop
        return currentStatus
    end
    

    if length(model.solutions) > 0
        return :Optimal
    end

    return :Infeasible
end

"""
    expandDfs!(toCall::Stack{Function}, model::CPModel, variableHeuristic::Function, env::RLEnv, agent::RL.Agent, newConstraints=nothing)

Add procedures to `toCall`, that, called in the stack order (LIFO) with the `model` parameter, will perform a DFS in the graph.
Some procedures will contain a call to `expandDfs!` itself.
"""
function expandDfs!(toCall::Stack{Function}, model::CPModel, variableHeuristic::Function, env::RLEnv, agent::RL.Agent, newConstraints=nothing)
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

    # All the transformations due to the next action have been done 

    # Variable selection
    x = variableHeuristic(model)

    # in our framework, the changes are made by the cpmodel, thus, the env do not launch the 
    # changes, that is why there is no env(action) here but there is a synchronisation of the env with
    # the cpmodel: sync!(env, model, x)
    sync_state!(env, model, x)

    obs = observe(env, x)
    if model.statistics.numberOfNodes >= 1
        agent(RL.POST_ACT_STAGE, obs) # get terminal and reward
        # eventually: hook(POST_ACT_STAGE, agent, env, obs, action)
    end

    # here we should check if we are still in the game ! But by definition, we are in it.
    # the hard part are the :Infeasible, as they are not here even if still in the game !

    v = agent(RL.PRE_ACT_STAGE, obs) # choose action, store it with the state
    # eventually hook(PRE_ACT_STAGE, agent, env, obs, action)

    
    # Value selection
    v = selectValue(x) # will disappear


    push!(toCall, (model) -> (restoreState!(model.trailer); :Feasible))
    push!(toCall, (model) -> (remove!(x.domain, v); expandDfs!(toCall, model, variableHeuristic, env, agent, getOnDomainChange(x))))
    push!(toCall, (model) -> (saveState!(model.trailer); :Feasible))

    push!(toCall, (model) -> (restoreState!(model.trailer); :Feasible))
    push!(toCall, (model) -> (assign!(x, v); expandDfs!(toCall, model, variableHeuristic, env, agent, getOnDomainChange(x))))
    push!(toCall, (model) -> (saveState!(model.trailer); :Feasible))

    return :Feasible
end

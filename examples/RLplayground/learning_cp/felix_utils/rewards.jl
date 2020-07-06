
function CPRL.set_reward!(env::CPRL.RLEnv, model::CPRL.CPModel, symbol::Symbol)
    env.reward += -1
    if symbol == :Infeasible
        if isempty(model.solutions)
            env.reward += - 5 * (20) * env.search_metrics.last_backtrack
        else
            env.reward += - 5 * (model.objectiveBound + 1 - 3) * env.search_metrics.last_backtrack
        end
        env.search_metrics.last_backtrack = 1
    else
        env.search_metrics.last_backtrack += 1
    end

    if symbol == :FoundSolution
        env.reward += + 50 * (6 - model.objectiveBound - 1)/ (1 + env.search_metrics.last_foundsolution)
        env.search_metrics.last_backtrack = 1
        env.search_metrics.last_foundsolution = 1
    else
        env.search_metrics.last_foundsolution += 1
    end
    nothing
end


function CPRL.set_final_reward!(env::CPRL.RLEnv, model::CPRL.CPModel, symbol::Symbol)
    #env.reward = - 10 * model.statistics.numberOfNodes
    #env.reward += - 30/(model.statistics.numberOfNodes)
    nothing
end

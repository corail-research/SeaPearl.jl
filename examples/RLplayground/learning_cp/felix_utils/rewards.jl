function CPRL.set_reward!(env::CPRL.RLEnv, model::CPRL.CPModel, symbol::Symbol)
    if symbol == :Infeasible
        env.reward += - 0.5 * (20 - model.objectiveBound + 1) * env.nslbt
        env.nslbt = 1
    else
        env.nslbt += 1
    end

    if symbol == :FoundSolution
        env.reward += + 50 * (20 - model.objectiveBound + 1)/ env.nslfs
        env.nslfs = 1
        env.nslbt = 1
    else
        env.nslfs += 1
    end
    nothing
end

function CPRL.set_final_reward!(env::CPRL.RLEnv, model::CPRL.CPModel)
    #env.reward = - model.statistics.numberOfNodes
    #env.reward += - 30/(model.statistics.numberOfNodes)
    nothing
end

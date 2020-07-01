
function CPRL.set_reward!(env::CPRL.RLEnv, model::CPRL.CPModel, symbol::Symbol)
    env.reward += 1
    if symbol == :Infeasible
        if isempty(model.solutions)
            env.reward += - 5 * (20) * env.nslbt
        else
            env.reward += - 5 * (model.objectiveBound + 1 - 3) * env.nslbt
        end
        env.nslbt = 1
    else
        env.nslbt += 1
    end

    if symbol == :FoundSolution
        env.reward += + 50 * (7 - model.objectiveBound - 1)/ env.nslfs
        env.nslfs = 1
        env.nslbt = 1
    else
        env.nslfs += 1
    end
    nothing
end


function CPRL.set_final_reward!(env::CPRL.RLEnv, model::CPRL.CPModel)
    #env.reward = - 10 * model.statistics.numberOfNodes
    #env.reward += - 30/(model.statistics.numberOfNodes)
    nothing
end

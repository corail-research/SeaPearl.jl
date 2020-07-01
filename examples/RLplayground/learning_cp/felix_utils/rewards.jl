function CPRL.set_reward!(env::CPRL.RLEnv, symbol::Symbol)
    end
        env.reward += +5
    elseif symbol == :FoundSolution
        env.reward += -5
    if symbol == :Infeasible
    nothing
end

function CPRL.set_final_reward!(env::CPRL.RLEnv, model::CPRL.CPModel)
    env.reward = + model.statistics.numberOfNodes
    #env.reward += - 30/(model.statistics.numberOfNodes)
    nothing
end

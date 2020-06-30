function CPRL.set_reward!(env::CPRL.RLEnv, symbol::Symbol)
    env.reward = 0
    nothing
end

function CPRL.set_final_reward!(env::CPRL.RLEnv, model::CPRL.CPModel)
    env.reward = - model.statistics.numberOfNodes
    nothing
end


struct InspectReward <: CPRL.AbstractReward end 

function CPRL.set_reward!(env::CPRL.RLEnv{InspectReward}, model::CPRL.CPModel, symbol::Union{Nothing, Symbol})
    #= if !isnothing(env.search_metrics.current_best) && env.search_metrics.current_best == 3
        env.reward = 0
    else
        env.reward += -1
        if symbol == :Infeasible
            if isempty(model.solutions)
                env.reward += - 5 * (15) * env.search_metrics.last_unfeasible
            else
                env.reward += - 5 * (env.search_metrics.current_best - 4) * env.search_metrics.last_unfeasible
            end
        end

        if symbol == :FoundSolution
            if isempty(model.solutions)
                env.reward += + 50 * (4 - env.search_metrics.current_best)/ (1 + env.search_metrics.last_foundsolution)
            else
                env.reward += + 50 * (20)/ (1 + env.search_metrics.last_foundsolution)
            end
        end
    end =#
    println("Rewarding phase : ", symbol, env.search_metrics)
    nothing
end

function CPRL.set_before_next_decision_reward!(env::CPRL.RLEnv{InspectReward}, model::CPRL.CPModel) 
    #env.reward -= 0
    println("Decision phase : ", env.search_metrics)
    nothing 
end

function CPRL.set_final_reward!(env::CPRL.RLEnv{InspectReward}, model::CPRL.CPModel, symbol::Union{Nothing, Symbol})
    #env.reward = - 10 * model.statistics.numberOfNodes
    #env.reward += - 30/(model.statistics.numberOfNodes)
    #env.reward = + env.search_metrics.total
    nothing
end

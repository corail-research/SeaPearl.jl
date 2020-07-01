"""
    struct DefaultReward <: AbstractReward end

This is the default reward, that will be used if no custom reward is specified when constructing the `LearnedHeuristic`.
"""
struct DefaultReward <: AbstractReward end

"""
    set_backtracking_reward!(env::RLEnv{DefaultReward}, model::CPModel, current_status::Union{Nothing, Symbol})

Change the "reward" attribute of `env`. Called whenever there is a backtracking and is associated with a
`current_status` symbol so the reward can be customized using that information.
"""
function set_backtracking_reward!(env::RLEnv{DefaultReward}, model::CPModel, current_status::Union{Nothing, Symbol})
    env.reward += -1/80
    nothing
end

"""
    set_before_next_decision_reward!(env::RLEnv{DefaultReward}, model::CPModel)

Change the reward of `env`. This is called right before making the next decision, so you know you have the very last state before the new decision
and every computation like fixPoints and backtracking has been done.
"""
function set_before_next_decision_reward!(env::RLEnv{DefaultReward}, model::CPModel)
    env.reward += -1/40
    nothing
end

"""
    set_after_decision_reward!(env::RLEnv{DefaultReward}, model::CPModel)

Change the "reward" attribute of `env`. Called right after the decision, can be used to set an "initial state" to the reward.
"""
function set_after_decision_reward!(env::RLEnv{DefaultReward}, model::CPModel)
    env.reward = 0
    nothing
end


"""
    set_final_reward!(env::RLEnv{DefaultReward}, model::CPModel)

Change the "reward" attribute of the env. Called when the optimality is proved.
"""
function set_final_reward!(env::RLEnv{DefaultReward}, model::CPModel)
    env.reward += 30/(model.statistics.numberOfNodes)
    nothing
end
"""
    struct DefaultReward <: AbstractReward end

This is the default reward, that will be used if no custom reward is specified when constructing the `LearnedHeuristic`.
"""
struct DefaultReward <: AbstractReward end

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
    set_final_reward!(env::RLEnv{DefaultReward}, model::CPModel)

Change the "reward" attribute of the env. Called when the optimality is proved.
"""
function set_final_reward!(env::RLEnv{DefaultReward}, model::CPModel)
    env.reward += 30/(model.statistics.numberOfNodes)
    nothing
end
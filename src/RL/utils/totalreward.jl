"""
    last_episode_total_reward(t::AbstractTrajectory)

Compute the sum of every reward of the last episode of the trajectory. 

For example, if the t[:terminal] = [0, 0, 1, 0, 1, 1, 1, 0, 0, 1], The 7-th state is a terminal state, which means that the last episode started at step 8. Hence, last_episode_total_reward corresponds to the 3 lasts decisions.
"""
function last_episode_total_reward(t::AbstractTrajectory)
    last_index = length(t[:terminal])
    last_index == 0 && return 0

    totalReward = t[:reward][last_index]
    
    i = 1
    while i < last_index && !t[:terminal][last_index - i]
        totalReward += t[:reward][last_index - i]

        i += 1
    end
    return totalReward
end
 
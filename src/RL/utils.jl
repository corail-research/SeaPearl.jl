"""
    last_episode_total_reward(t::AbstractTrajectory)

Compute the sum of every reward of the last episode of the trajectory
"""
function last_episode_total_reward(t::AbstractTrajectory)
    last_index = length(t[:terminal])

    #if t[:terminal][last_index]   #TODO understand why they wrote this

    totalReward = t[:reward][last_index]
    
    i = 1
    while i < last_index && !t[:terminal][last_index - i]
        totalReward += t[:reward][last_index - i]

        i += 1
    end
    return totalReward
end

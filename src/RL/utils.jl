"""
    last_episode_total_reward(t::AbstractTrajectory)

Compute the sum of every reward of the last episode of the trajectory
"""
function last_episode_total_reward(t::AbstractTrajectory)
    last_index = length(t[:terminal])

    @assert t[:terminal][last_index]

    total_reward = t[:reward][last_index]
    
    i = 1
    while !t[:terminal][last_index - i]
        total_reward += t[:reward][last_index - i]

        i += 1
    end
    return total_reward
end

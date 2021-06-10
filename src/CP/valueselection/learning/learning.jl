include("environment.jl")
include("learnedheuristic.jl")
include("rewards/rewards.jl")
include("utils.jl")

LearnedHeuristic(agent::RL.Agent) = LearnedHeuristic{DefaultStateRepresentation{SeaPearl.DefaultFeaturization, SeaPearl.DefaultTrajectoryState}, DefaultReward, FixedOutput}(agent)

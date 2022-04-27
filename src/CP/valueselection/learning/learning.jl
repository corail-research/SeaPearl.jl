include("environment.jl")
include("learnedheuristic.jl")
include("rewards/rewards.jl")
include("utils.jl")
include("supervisedlearnedheuristic.jl")

LearnedHeuristic(agent::RL.Agent) = LearnedHeuristic{DefaultStateRepresentation{DefaultFeaturization, DefaultTrajectoryState}, DefaultReward, FixedOutput}(agent)

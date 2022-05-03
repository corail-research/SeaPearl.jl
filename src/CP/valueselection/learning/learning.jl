include("environment.jl")
include("learnedheuristic.jl")
include("rewards/rewards.jl")
include("utils.jl")
include("supervisedlearnedheuristic.jl")

SimpleLearnedHeuristic(agent::RL.Agent) = SimpleLearnedHeuristic{DefaultStateRepresentation{DefaultFeaturization, DefaultTrajectoryState}, DefaultReward, FixedOutput}(agent)
SupervisedLearnedHeuristic(agent::RL.Agent) = SupervisedLearnedHeuristic{DefaultStateRepresentation{DefaultFeaturization, DefaultTrajectoryState}, DefaultReward, FixedOutput}(agent)
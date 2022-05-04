include("environment.jl")
include("learnedheuristic.jl")
include("rewards/rewards.jl")
include("utils.jl")
include("simplelearnedheuristic.jl")
include("supervisedlearnedheuristic.jl")

SimpleLearnedHeuristic(agent::RL.Agent) = SimpleLearnedHeuristic{DefaultStateRepresentation{DefaultFeaturization, DefaultTrajectoryState}, DefaultReward, FixedOutput}(agent)

SupervisedLearnedHeuristic(agent::RL.Agent;
    helpVariableHeuristic::AbstractVariableSelection=MinDomainVariableSelection(),
    helpValueHeuristic::ValueSelection=BasicHeuristic(),
    eta_init::Float64=0.5,
    eta_stable::Float64=0.5,
    warmup_steps::Int64=0,
    decay_steps::Int64=0,
    rng::Union{Nothing, AbstractRNG}=MersenneTwister()
) = SupervisedLearnedHeuristic{DefaultStateRepresentation{DefaultFeaturization, DefaultTrajectoryState}, DefaultReward, FixedOutput}(
        agent;
        helpVariableHeuristic,
        helpValueHeuristic,
        eta_init,
        eta_stable,
        warmup_steps,
        decay_steps,
        rng
    )
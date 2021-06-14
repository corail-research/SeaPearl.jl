approximator_GNN = GeometricFlux.GraphConv(64 => 64, Flux.leakyrelu)
target_approximator_GNN = GeometricFlux.GraphConv(64 => 64, Flux.leakyrelu)
gnnlayers = 1
approximator_model = SeaPearl.FlexGNN(
    graphChain = Flux.Chain(
        GeometricFlux.GraphConv(3 => 64, Flux.leakyrelu),
        [approximator_GNN for i = 1:gnnlayers]...
    ),
    nodeChain = Flux.Chain(
        Flux.Dense(64, 32, Flux.leakyrelu),
        Flux.Dense(32, 32, Flux.leakyrelu),
        Flux.Dense(32, 16, Flux.leakyrelu),
    ),
    outputLayer = Flux.Dense(16, 4),
) |> gpu
target_approximator_model = SeaPearl.FlexGNN(
    graphChain = Flux.Chain(
        GeometricFlux.GraphConv(3 => 64, Flux.leakyrelu),
        [target_approximator_GNN for i = 1:gnnlayers]...
    ),
    nodeChain = Flux.Chain(
        Flux.Dense(64, 32, Flux.leakyrelu),
        Flux.Dense(32, 32, Flux.leakyrelu),
        Flux.Dense(32, 16, Flux.leakyrelu),
    ),
    outputLayer = Flux.Dense(16, 4),
) |> gpu
            
agent = RL.Agent(
    policy = RL.QBasedPolicy(
        learner = RL.DQNLearner(
            approximator = RL.NeuralNetworkApproximator(
                model = approximator_model,
                optimizer = ADAM(0.001f0)
            ),
            target_approximator = RL.NeuralNetworkApproximator(
                model = target_approximator_model,
                optimizer = ADAM(0.001f0)
            ),
            loss_func = Flux.Losses.huber_loss,
            stack_size = nothing,
            γ = 0.99f0,
            batch_size = 32,
            update_horizon = 1,
            min_replay_history = 1,
            update_freq = 1,
            target_update_freq = 100,
        ), 
        explorer = RL.EpsilonGreedyExplorer(
            ϵ_stable = 0.01,
            kind = :exp,
            ϵ_init = 1.0,
            warmup_steps = 0,
            decay_steps = 500,
            step = 1,
            is_break_tie = false, 
            #is_training = true,
            rng = MersenneTwister(33)
        )
    ),
    trajectory = RL.CircularArraySLARTTrajectory(
        capacity = 500,
        state = SeaPearl.DefaultTrajectoryState[] => (),
        action = Int => (),
        legal_actions_mask = Vector{Bool} => (4, ),
    )
)

@testset "learning.jl" begin
    include("searchmetrics.jl")
    include("rewards/rewards.jl")
    include("utils.jl")
    include("learnedheuristic.jl")
    include("searchmetrics.jl")

    LearnedHeristicBasicConstructor = SeaPearl.LearnedHeuristic(agent)
    @test isa(LearnedHeristicBasicConstructor,SeaPearl.LearnedHeuristic{SeaPearl.DefaultStateRepresentation{SeaPearl.DefaultFeaturization, SeaPearl.DefaultTrajectoryState}, SeaPearl.DefaultReward, SeaPearl.FixedOutput})
    @test LearnedHeristicBasicConstructor.fitted_problem == nothing
    @test LearnedHeristicBasicConstructor.fitted_strategy == nothing
    @test LearnedHeristicBasicConstructor.action_space == nothing
    @test LearnedHeristicBasicConstructor.current_state == nothing
    @test LearnedHeristicBasicConstructor.reward == nothing
    @test LearnedHeristicBasicConstructor.search_metrics == nothing


end
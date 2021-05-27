@testset "training.jl inside the solver (with backtracking)" begin
    
    println("Training inside the solver -------- ")

    generator = SeaPearl.HomogenousGraphColoringGenerator(10, 0.1)

    numInFeatures = 3

    state_size = SeaPearl.arraybuffer_dims(generator, SeaPearl.DefaultStateRepresentation{SeaPearl.DefaultFeaturization})
    maxNumberOfCPNodes = state_size[1]

    agent = RL.Agent(
        policy = RL.QBasedPolicy(
            learner = RL.DQNLearner(
                approximator = RL.NeuralNetworkApproximator(
                    model = SeaPearl.FlexGNN(
                        graphChain = Flux.Chain(
                            GeometricFlux.GCNConv(numInFeatures => 20),
                            GeometricFlux.GCNConv(20 => 20),
                        ),
                        nodeChain = Flux.Chain(
                            Flux.Dense(20, 20),
                        ),
                        outputLayer = Flux.Dense(20, generator.nb_nodes)
                    ),
                    optimizer = ADAM(0.001f0)
                ),
                target_approximator = RL.NeuralNetworkApproximator(
                    model = SeaPearl.FlexGNN(
                        graphChain = Flux.Chain(
                            GeometricFlux.GCNConv(numInFeatures => 20),
                            GeometricFlux.GCNConv(20 => 20),
                        ),
                        nodeChain = Flux.Chain(
                            Flux.Dense(20, 20),
                        ),
                        outputLayer = Flux.Dense(20, generator.nb_nodes)
                    ),
                    optimizer = ADAM(0.001f0)
                ),
                loss_func = Flux.Losses.huber_loss,
                stack_size = nothing,
                γ = 0.99f0,
                batch_size = 2,
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
            state = Matrix{Float32} => state_size,
            legal_actions_mask = Vector{Bool} => (generator.nb_nodes, ),
        )
    )

    learnedHeuristic = SeaPearl.LearnedHeuristic(agent, maxNumberOfCPNodes)

    initial_params = deepcopy(params(learnedHeuristic.agent.policy.learner.approximator.model))

    metrics,evalmetrics = SeaPearl.train!(
        valueSelectionArray=learnedHeuristic, 
        generator=generator,
        nbEpisodes= 3, #3,
        strategy=SeaPearl.DFSearch,
        variableHeuristic=SeaPearl.MinDomainVariableSelection{true}(),
        out_solver = false,
        verbose = false,
        evaluator=SeaPearl.SameInstancesEvaluator([learnedHeuristic],generator)  #need to be a vector of Heuristic
    )

    final_params = params(learnedHeuristic.agent.policy.learner.approximator.model)

    @test final_params != initial_params

end

@testset "training.jl outside the solver (without backtracking)" begin

    println("Let's try without backtracking   :   ------------")

    generator = SeaPearl.HomogenousGraphColoringGenerator(10, 0.1)

    numInFeatures = 3

    state_size = SeaPearl.arraybuffer_dims(generator, SeaPearl.DefaultStateRepresentation{SeaPearl.DefaultFeaturization})
    maxNumberOfCPNodes = state_size[1]


    agent = RL.Agent(
        policy = RL.QBasedPolicy(
            learner = RL.DQNLearner(
                approximator = RL.NeuralNetworkApproximator(
                    model = SeaPearl.FlexGNN(
                        graphChain = Flux.Chain(
                            GeometricFlux.GCNConv(numInFeatures => 20),
                            GeometricFlux.GCNConv(20 => 20),
                        ),
                        nodeChain = Flux.Chain(
                            Flux.Dense(20, 20),
                        ),
                        outputLayer = Flux.Dense(20, generator.nb_nodes)
                    ),
                    optimizer = ADAM(0.001f0)
                ),
                target_approximator = RL.NeuralNetworkApproximator(
                    model = SeaPearl.FlexGNN(
                        graphChain = Flux.Chain(
                            GeometricFlux.GCNConv(numInFeatures => 20),
                            GeometricFlux.GCNConv(20 => 20),
                        ),
                        nodeChain = Flux.Chain(
                            Flux.Dense(20, 20),
                        ),
                        outputLayer = Flux.Dense(20, generator.nb_nodes)
                    ),
                    optimizer = ADAM(0.001f0)
                ),
                loss_func = Flux.Losses.huber_loss,
                stack_size = nothing,
                γ = 0.99f0,
                batch_size = 2,
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
            state = Matrix{Float32} => state_size,
            legal_actions_mask = Vector{Bool} => (generator.nb_nodes, ),
        )
    )

    learnedHeuristic = SeaPearl.LearnedHeuristic(agent, maxNumberOfCPNodes)

    initial_params = deepcopy(params(learnedHeuristic.agent.policy.learner.approximator.model))

    metrics,evalmetrics = SeaPearl.train!(
        valueSelectionArray=learnedHeuristic, 
        generator=generator,
        nbEpisodes=3,
        strategy=SeaPearl.DFSearch,
        variableHeuristic=SeaPearl.MinDomainVariableSelection{false}(),
        out_solver = true,
        evaluator=nothing 
    )

    final_params = params(learnedHeuristic.agent.policy.learner.approximator.model)

    @test final_params != initial_params


end
@testset "training.jl inside the solver (with backtracking)" begin
    
    println("Training inside the solver -------- ")

    generator = SeaPearl.HomogenousGraphColoringGenerator(10, 0.1)

    numInFeatures = 3
    # Model definition
    approximator_GNN = GeometricFlux.GraphConv(64 => 64, Flux.leakyrelu)
    target_approximator_GNN = GeometricFlux.GraphConv(64 => 64, Flux.leakyrelu)
    gnnlayers = 10

    approximator_model = SeaPearl.CPNN(
        graphChain = Flux.Chain(
            GeometricFlux.GraphConv(numInFeatures => 64, Flux.leakyrelu),
            [approximator_GNN for i = 1:gnnlayers]...
        ),
        nodeChain = Flux.Chain(
            Flux.Dense(64, 32, Flux.leakyrelu),
            Flux.Dense(32, 32, Flux.leakyrelu),
            Flux.Dense(32, 16, Flux.leakyrelu),
        ),
        outputChain = Flux.Dense(16, generator.nb_nodes),
    ) 
    target_approximator_model = SeaPearl.CPNN(
        graphChain = Flux.Chain(
            GeometricFlux.GraphConv(numInFeatures => 64, Flux.leakyrelu),
            [target_approximator_GNN for i = 1:gnnlayers]...
        ),
        nodeChain = Flux.Chain(
            Flux.Dense(64, 32, Flux.leakyrelu),
            Flux.Dense(32, 32, Flux.leakyrelu),
            Flux.Dense(32, 16, Flux.leakyrelu),
        ),
        outputChain = Flux.Dense(16, generator.nb_nodes),
    ) 

    # Agent definition
    agent = RL.Agent(
        policy = RL.QBasedPolicy(
            learner = RL.DQNLearner(
                approximator = RL.NeuralNetworkApproximator(
                    model = approximator_model,
                    optimizer = ADAM(0.0005f0)
                ),
                target_approximator = RL.NeuralNetworkApproximator(
                    model = target_approximator_model,
                    optimizer = ADAM(0.0005f0)
                ),
                loss_func = Flux.Losses.huber_loss,
                stack_size = nothing,
                γ = 0.99f0,
                batch_size = 32,
                update_horizon = 4,
                min_replay_history = 32,
                update_freq = 4,
                target_update_freq = 20,
            ), 
            explorer = RL.EpsilonGreedyExplorer(
                ϵ_stable = 0.001,
                kind = :exp,
                ϵ_init = 1.0,
                warmup_steps = 0,
                decay_steps = 5000,
                step = 1,
                is_break_tie = false, 
                #is_training = true,
                rng = MersenneTwister(33)
            )
        ),
        trajectory = RL.CircularArraySARTTrajectory(
            capacity = 800,
            state = SeaPearl.DefaultTrajectoryState[] => (),
        )
    )

    learnedHeuristic = SeaPearl.LearnedHeuristic(agent)

    initial_params = deepcopy(params(learnedHeuristic.agent.policy.learner.approximator.model))

    metrics,evalmetrics = SeaPearl.train!(
        valueSelectionArray=learnedHeuristic, 
        generator=generator,
        nbEpisodes= 10, #3,
        strategy=SeaPearl.DFSearch(),
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

    # Model definition
    approximator_GNN = GeometricFlux.GraphConv(64 => 64, Flux.leakyrelu)
    target_approximator_GNN = GeometricFlux.GraphConv(64 => 64, Flux.leakyrelu)
    gnnlayers = 10

    approximator_model = SeaPearl.CPNN(
        graphChain = Flux.Chain(
            GeometricFlux.GraphConv(numInFeatures => 64, Flux.leakyrelu),
            [approximator_GNN for i = 1:gnnlayers]...
        ),
        nodeChain = Flux.Chain(
            Flux.Dense(64, 32, Flux.leakyrelu),
            Flux.Dense(32, 32, Flux.leakyrelu),
            Flux.Dense(32, 16, Flux.leakyrelu),
        ),
        outputChain = Flux.Dense(16, generator.nb_nodes),
    ) 
    target_approximator_model = SeaPearl.CPNN(
        graphChain = Flux.Chain(
            GeometricFlux.GraphConv(numInFeatures => 64, Flux.leakyrelu),
            [target_approximator_GNN for i = 1:gnnlayers]...
        ),
        nodeChain = Flux.Chain(
            Flux.Dense(64, 32, Flux.leakyrelu),
            Flux.Dense(32, 32, Flux.leakyrelu),
            Flux.Dense(32, 16, Flux.leakyrelu),
        ),
        outputChain = Flux.Dense(16, generator.nb_nodes),
    ) 

    # Agent definition
    agent = RL.Agent(
        policy = RL.QBasedPolicy(
            learner = RL.DQNLearner(
                approximator = RL.NeuralNetworkApproximator(
                    model = approximator_model,
                    optimizer = ADAM(0.0005f0)
                ),
                target_approximator = RL.NeuralNetworkApproximator(
                    model = target_approximator_model,
                    optimizer = ADAM(0.0005f0)
                ),
                loss_func = Flux.Losses.huber_loss,
                stack_size = nothing,
                γ = 0.99f0,
                batch_size = 32,
                update_horizon = 4,
                min_replay_history = 32,
                update_freq = 4,
                target_update_freq = 20,
            ), 
            explorer = RL.EpsilonGreedyExplorer(
                ϵ_stable = 0.001,
                kind = :exp,
                ϵ_init = 1.0,
                warmup_steps = 0,
                decay_steps = 5000,
                step = 1,
                is_break_tie = false, 
                #is_training = true,
                rng = MersenneTwister(33)
            )
        ),
        trajectory = RL.CircularArraySLARTTrajectory(
            capacity = 800,
            state = SeaPearl.DefaultTrajectoryState[] => (),
            legal_actions_mask = Vector{Bool} => (generator.nb_nodes, ),

        )
    )

    learnedHeuristic = SeaPearl.LearnedHeuristic(agent)
    initial_params = deepcopy(params(learnedHeuristic.agent.policy.learner.approximator.model))

    metrics,evalmetrics = SeaPearl.train!(
        valueSelectionArray=learnedHeuristic, 
        generator=generator,
        nbEpisodes=10,
        strategy=SeaPearl.DFSearch(),
        variableHeuristic=SeaPearl.MinDomainVariableSelection{true}(),
        out_solver = true,
        verbose = false,
        evaluator=nothing 
    )

    final_params = params(learnedHeuristic.agent.policy.learner.approximator.model)

    @test final_params != initial_params


end
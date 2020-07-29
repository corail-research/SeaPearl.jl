@testset "training.jl" begin
    generator = SeaPearl.HomogenousGraphColoringGenerator(10, 0.1)
    numInFeatures = 3

    maxNumberOfCPNodes = 150


    state_size = (maxNumberOfCPNodes, numInFeatures + maxNumberOfCPNodes + 2 + 1) 
    agent = RL.Agent(
            policy = RL.QBasedPolicy(
                learner = SeaPearl.CPDQNLearner(
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
                    loss_func = huber_loss,
                    stack_size = nothing,
                    γ = 0.99f0,
                    batch_size = 32,
                    update_horizon = 1,
                    min_replay_history = 1,
                    update_freq = 1,
                    target_update_freq = 100,
                    seed = 22,
                ), 
                explorer = SeaPearl.CPEpsilonGreedyExplorer(
                    ϵ_stable = 0.01,
                    kind = :exp,
                    ϵ_init = 1.0,
                    warmup_steps = 0,
                    decay_steps = 500,
                    step = 1,
                    is_break_tie = false, 
                    #is_training = true,
                    seed = 33
                )
            ),
            trajectory = RL.CircularCompactSARTSATrajectory(
                capacity = 500, 
                state_type = Float32, 
                state_size = state_size,
                action_type = Int,
                action_size = (),
                reward_type = Float32,
                reward_size = (),
                terminal_type = Bool,
                terminal_size = ()
            ),
            role = :DEFAULT_PLAYER
        )
    
    learnedHeuristic = SeaPearl.LearnedHeuristic(agent, maxNumberOfCPNodes)

    initial_params = deepcopy(params(learnedHeuristic.agent.policy.learner.approximator.model))

    bestsolutions, nodevisited, timeneeded = SeaPearl.train!(
        valueSelectionArray=learnedHeuristic, 
        generator=generator,
        nb_episodes=3,
        strategy=SeaPearl.DFSearch,
        variableHeuristic=SeaPearl.MinDomainVariableSelection{true}()
    )

    final_params = params(learnedHeuristic.agent.policy.learner.approximator.model)

    @test final_params != initial_params

    println(bestsolutions)
    println(nodevisited)

end
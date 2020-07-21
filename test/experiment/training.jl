@testset "training.jl" begin
    generator = CPRL.GraphColoringGenerator(10, 1.5)

    agent = RL.Agent(
            policy = RL.QBasedPolicy(
                learner = CPRL.CPDQNLearner(
                    approximator = RL.NeuralNetworkApproximator(
                        model = Chain(
                            Flux.flatten,
                            Dense(46*52, 100, Flux.relu),
                            Dense(100, 50, Flux.relu),
                            Dense(50, 10, Flux.relu)
                        ),
                        optimizer = ADAM(0.0005f0)
                    ),
                    target_approximator = RL.NeuralNetworkApproximator(
                        model = Chain(
                            Flux.flatten,
                            Dense(46*52, 100, Flux.relu),
                            Dense(100, 50, Flux.relu),
                            Dense(50, 10, Flux.relu)
                        ),
                        optimizer = ADAM(0.0005f0)
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
                explorer = CPRL.CPEpsilonGreedyExplorer(
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
                state_size = (46, 52, 1),
                action_type = Int,
                action_size = (),
                reward_type = Float32,
                reward_size = (),
                terminal_type = Bool,
                terminal_size = ()
            ),
            role = :DEFAULT_PLAYER
        )
    
    learnedHeuristic = CPRL.LearnedHeuristic(agent)

    initial_params = deepcopy(params(learnedHeuristic.agent.policy.learner.approximator.model))

    bestsolutions, nodevisited, timeneeded = CPRL.train!(
        valueSelectionArray=learnedHeuristic, 
        generator=generator,
        nb_episodes=3,
        strategy=CPRL.DFSearch,
        variableHeuristic=CPRL.MinDomainVariableSelection{false}()
    )

    final_params = params(learnedHeuristic.agent.policy.learner.approximator.model)

    @test final_params != initial_params

    println(bestsolutions)
    println(nodevisited)

end
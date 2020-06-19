@testset "training.jl" begin
    
    problem_generator = Dict(
        :coloring => CPRL.fill_with_coloring!
    )

    coloring_params = Dict(
        "nb_nodes" => 10,
        "density" => 1.5
    )

    agent = RL.Agent(
            policy = RL.QBasedPolicy(
                learner = RL.DQNLearner(
                    approximator = RL.NeuralNetworkApproximator(
                        model = Chain(
                            Flux.flatten,
                            Dense(46*93, 100, Flux.relu),
                            Dense(100, 50, Flux.relu),
                            Dense(50, 10, Flux.relu)
                        ),
                        optimizer = ADAM(0.001f0)
                    ),
                    target_approximator = RL.NeuralNetworkApproximator(
                        model = Chain(
                            Flux.flatten,
                            Dense(46*93, 100, Flux.relu),
                            Dense(100, 50, Flux.relu),
                            Dense(50, 10, Flux.relu)
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
                explorer = RL.EpsilonGreedyExplorer(
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
                capacity = 1000, 
                state_type = Float32, 
                state_size = (46, 93, 1),
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

    function selectNonObjVariable(model::CPRL.CPModel)
        selectedVar = nothing
        minSize = typemax(Int)
        for (k, x) in model.variables
            if length(x.domain) > 1 && length(x.domain) < minSize #&& k != "numberOfColors"
                selectedVar = x
                minSize = length(x.domain)
            end
        end
        # @assert !isnothing(selectedVar)
        return selectedVar
    end

    initial_params = deepcopy(params(learnedHeuristic.agent.policy.learner.approximator.model))

    bestsolutions, nodevisited = CPRL.train!(
        learnedHeuristic=learnedHeuristic, 
        problem_type=:coloring,
        problem_params=coloring_params,
        nb_episodes=3,
        strategy=CPRL.DFSearch,
        variableHeuristic=selectNonObjVariable
    )

    final_params = params(learnedHeuristic.agent.policy.learner.approximator.model)

    @test final_params != initial_params

    println(bestsolutions)
    println(nodevisited)

end
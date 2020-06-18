using Flux

@testset "valueselection.jl" begin 

    @testset "RL.jl" begin 

        include("../../RL/RL.jl") 

    end

    @testset "selectValue function" begin 
        trailer = CPRL.Trailer()
        model = CPRL.CPModel(trailer)

        x = CPRL.IntVar(2, 6, "x", trailer)

        @test CPRL.selectValue(x) == 6
    end

    @testset "BasicHeuristic" begin 
        valueselection = CPRL.BasicHeuristic()

        @test valueselection.selectValue == CPRL.selectValue

        my_heuristic(x::CPRL.IntVar) = minimum(x.domain)
        new_valueselection = CPRL.BasicHeuristic(my_heuristic)

        @test new_valueselection.selectValue == my_heuristic
        
        trailer = CPRL.Trailer()
        model = CPRL.CPModel(trailer)

        x = CPRL.IntVar(2, 6, "x", trailer)

        @test valueselection.selectValue(x) == 6
        @test new_valueselection.selectValue(x) == 2
    end

    @testset "LearnedHeuristic" begin 
        agent = RL.Agent(
            policy = RL.QBasedPolicy(
                learner = RL.DQNLearner(
                    approximator = RL.NeuralNetworkApproximator(
                        model = Chain(
                            Flux.flatten,
                            Dense(11*23, 20, Flux.relu),
                            Dense(20, 20, Flux.relu),
                            Dense(20, 4, Flux.relu)
                        ),
                        optimizer = ADAM(0.001f0)
                    ),
                    target_approximator = RL.NeuralNetworkApproximator(
                        model = Chain(
                            Flux.flatten,
                            Dense(11*23, 20, Flux.relu),
                            Dense(20, 20, Flux.relu),
                            Dense(20, 4, Flux.relu)
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
                state_size = (11, 23, 1),
                action_type = Int,
                action_size = (),
                reward_type = Float32,
                reward_size = (),
                terminal_type = Bool,
                terminal_size = ()
            ),
            role = :DEFAULT_PLAYER
        )

        learnedheuristic = CPRL.LearnedHeuristic(agent)

        @test learnedheuristic.agent == agent
        @test isnothing(learnedheuristic.fitted_problem)
        @test isnothing(learnedheuristic.fitted_strategy)
        @test isnothing(learnedheuristic.current_env)

        learnedheuristic.fitted_problem = :coloring
        learnedheuristic.fitted_strategy = CPRL.DFSearch

        @test learnedheuristic.fitted_problem == :coloring
        @test learnedheuristic.fitted_strategy == CPRL.DFSearch

    end

    @testset "LearnedHeuristic in action" begin 
    
        agent = RL.Agent(
            policy = RL.QBasedPolicy(
                learner = RL.DQNLearner(
                    approximator = RL.NeuralNetworkApproximator(
                        model = Chain(
                            Flux.flatten,
                            Dense(11*23, 20, Flux.relu),
                            Dense(20, 20, Flux.relu),
                            Dense(20, 4, Flux.relu)
                        ),
                        optimizer = ADAM(0.001f0)
                    ),
                    target_approximator = RL.NeuralNetworkApproximator(
                        model = Chain(
                            Flux.flatten,
                            Dense(11*23, 20, Flux.relu),
                            Dense(20, 20, Flux.relu),
                            Dense(20, 4, Flux.relu)
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
                state_size = (11, 23, 1),
                action_type = Int,
                action_size = (),
                reward_type = Float32,
                reward_size = (),
                terminal_type = Bool,
                terminal_size = ()
            ),
            role = :DEFAULT_PLAYER
        )

        valueSelection = CPRL.LearnedHeuristic(agent)

        trailer = CPRL.Trailer()
        model = CPRL.CPModel(trailer)

        x1 = CPRL.IntVar(1, 2, "x1", trailer)
        x2 = CPRL.IntVar(1, 2, "x2", trailer)
        x3 = CPRL.IntVar(2, 3, "x3", trailer)
        x4 = CPRL.IntVar(1, 4, "x4", trailer)
        CPRL.addVariable!(model, x1)
        CPRL.addVariable!(model, x2)
        CPRL.addVariable!(model, x3)
        CPRL.addVariable!(model, x4)

        push!(model.constraints, CPRL.NotEqual(x1, x2, trailer))
        push!(model.constraints, CPRL.NotEqual(x2, x3, trailer))
        push!(model.constraints, CPRL.NotEqual(x3, x4, trailer))

        env = CPRL.RLEnv(model)

        valueSelection.current_env = env

        @test valueSelection.current_env == env

        false_x = first(values(model.variables))
        obs = CPRL.observe!(valueSelection.current_env, model, false_x)
        valueSelection.agent(RL.PRE_EPISODE_STAGE, obs)


        obs = CPRL.observe!(valueSelection.current_env, model, x1)
        v1 = valueSelection.agent(RL.PRE_ACT_STAGE, obs)

        CPRL.assign!(x1, v1)
        _, _ = CPRL.fixPoint!(model, CPRL.getOnDomainChange(x1))


        obs = CPRL.observe!(valueSelection.current_env, model, x2)
        valueSelection.agent(RL.POST_ACT_STAGE, obs)

        v2 = valueSelection.agent(RL.PRE_ACT_STAGE, obs)

        CPRL.assign!(x2, v2)
        _, _ = CPRL.fixPoint!(model, CPRL.getOnDomainChange(x2))

        
        obs = CPRL.observe!(valueSelection.current_env, model, x3)
        valueSelection.agent(RL.POST_ACT_STAGE, obs)

        v3 = valueSelection.agent(RL.PRE_ACT_STAGE, obs)
        
        CPRL.assign!(x3, v3)
        _, _ = CPRL.fixPoint!(model, CPRL.getOnDomainChange(x2))

        
        obs = CPRL.observe!(valueSelection.current_env, model, x4)
        valueSelection.agent(RL.POST_ACT_STAGE, obs)

        v4 = valueSelection.agent(RL.PRE_ACT_STAGE, obs)

    end

end
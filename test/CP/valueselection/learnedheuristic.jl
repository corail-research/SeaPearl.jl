agent = RL.Agent(
    policy = RL.QBasedPolicy(
        learner = CPRL.CPDQNLearner(
            approximator = RL.NeuralNetworkApproximator(
                model = Chain(
                    Flux.flatten,
                    Dense(11*17, 20, Flux.relu),
                    Dense(20, 20, Flux.relu),
                    Dense(20, 4, Flux.relu)
                ),
                optimizer = ADAM(0.001f0)
            ),
            target_approximator = RL.NeuralNetworkApproximator(
                model = Chain(
                    Flux.flatten,
                    Dense(11*17, 20, Flux.relu),
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
        capacity = 1000, 
        state_type = Float32, 
        state_size = (11, 17, 1),
        action_type = Int,
        action_size = (),
        reward_type = Float32,
        reward_size = (),
        terminal_type = Bool,
        terminal_size = ()
    ),
    role = :DEFAULT_PLAYER
)

@testset "learnedheuristic.jl" begin

    include("searchmetrics.jl")
    include("reward.jl")

    @testset "LearnedHeuristic" begin 

        learnedheuristic = CPRL.LearnedHeuristic(agent)

        @test learnedheuristic.agent == agent
        @test isnothing(learnedheuristic.fitted_problem)
        @test isnothing(learnedheuristic.fitted_strategy)
        @test isnothing(learnedheuristic.action_space)
        @test isnothing(learnedheuristic.current_state)
        @test isnothing(learnedheuristic.current_reward)
        @test isnothing(learnedheuristic.search_metrics)

        learnedheuristic.fitted_problem = CPRL.GraphColoringGenerator
        learnedheuristic.fitted_strategy = CPRL.DFSearch

        @test learnedheuristic.fitted_problem == CPRL.GraphColoringGenerator
        @test learnedheuristic.fitted_strategy == CPRL.DFSearch

    end

    @testset "learnedheuristic utils" begin

        @testset "update_with_cpmodel!()" begin
            trailer = CPRL.Trailer()
            model = CPRL.CPModel(trailer)

            x = CPRL.IntVar(2, 3, "x", trailer)
            y = CPRL.IntVar(2, 3, "y", trailer)
            CPRL.addVariable!(model, x)
            CPRL.addVariable!(model, y)
            push!(model.constraints, CPRL.Equal(x, y, trailer))
            push!(model.constraints, CPRL.NotEqual(x, y, trailer))

            lh = CPRL.LearnedHeuristic(agent)

            CPRL.update_with_cpmodel!(lh, model)

            @test typeof(lh.action_space) == RL.DiscreteSpace{Array{Int64,1}}
            @test lh.action_space.span == [2, 3]
            @test typeof(lh.current_state) == CPRL.CPGraph
            @test lh.current_reward == 0
            @test isa(lh.search_metrics, CPRL.SearchMetrics)
        end 

        @testset "sync_state!()" begin
            trailer = CPRL.Trailer()
            model = CPRL.CPModel(trailer)

            x = CPRL.IntVar(2, 3, "x", trailer)
            y = CPRL.IntVar(2, 3, "y", trailer)
            CPRL.addVariable!(model, x)
            CPRL.addVariable!(model, y)
            push!(model.constraints, CPRL.Equal(x, y, trailer))
            push!(model.constraints, CPRL.NotEqual(x, y, trailer))

            lh = CPRL.LearnedHeuristic(agent)
            CPRL.update_with_cpmodel!(lh, model)

            CPRL.sync_state!(lh, model, x)

            @test Matrix(lh.current_state.featuredgraph.graph[]) == [0 0 1 1 0 0
                                                            0 0 1 1 0 0
                                                            1 1 0 0 1 1
                                                            1 1 0 0 1 1
                                                            0 0 1 1 0 0
                                                            0 0 1 1 0 0]

            @test lh.current_state.featuredgraph.feature[] == Float32[ 1 1 0 0 0 0
                                                                0 0 1 1 0 0
                                                                0 0 0 0 1 1]
            
            @test lh.current_state.variable_id == 3

            CPRL.assign!(x, 2)
            CPRL.sync_state!(lh, model, y)

            @test Matrix(lh.current_state.featuredgraph.graph[]) == [0 0 1 1 0 0
                                                            0 0 1 1 0 0
                                                            1 1 0 0 1 0
                                                            1 1 0 0 1 1
                                                            0 0 1 1 0 0
                                                            0 0 0 1 0 0]

            @test lh.current_state.featuredgraph.feature[] == Float32[ 1 1 0 0 0 0
                                                                0 0 1 1 0 0
                                                                0 0 0 0 1 1]
            
            @test lh.current_state.variable_id == 4
        end

        @testset "get_observation!()" begin
            trailer = CPRL.Trailer()
            model = CPRL.CPModel(trailer)

            x = CPRL.IntVar(2, 3, "x", trailer)
            y = CPRL.IntVar(2, 3, "y", trailer)
            CPRL.addVariable!(model, x)
            CPRL.addVariable!(model, y)
            push!(model.constraints, CPRL.Equal(x, y, trailer))
            push!(model.constraints, CPRL.NotEqual(x, y, trailer))

            lh = CPRL.LearnedHeuristic(agent)
            CPRL.update_with_cpmodel!(lh, model)

            obs = CPRL.get_observation!(lh, model, x)

            @test obs.reward == 0
            @test obs.terminal == false 
            @test obs.legal_actions == [2, 3]
            @test obs.legal_actions_mask == [true, true]

            CPRL.remove!(x.domain, 2)

            obs = CPRL.get_observation!(lh, model, x)

            @test obs.reward == 0
            @test obs.terminal == false 
            @test obs.legal_actions == [3]
            @test obs.legal_actions_mask == [false, true]

        end

    end

    @testset "LearnedHeuristic in action" begin 

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

        lh = CPRL.LearnedHeuristic(agent)
        CPRL.update_with_cpmodel!(lh, model)

        false_x = first(values(model.variables))
        obs = CPRL.get_observation!(lh, model, false_x)
        lh.agent(RL.PRE_EPISODE_STAGE, obs)


        obs = CPRL.get_observation!(lh, model, x1)
        v1 = lh.agent(RL.PRE_ACT_STAGE, obs)

        CPRL.assign!(x1, v1)
        _, _ = CPRL.fixPoint!(model, CPRL.getOnDomainChange(x1))


        obs = CPRL.get_observation!(lh, model, x2)
        lh.agent(RL.POST_ACT_STAGE, obs)

        v2 = lh.agent(RL.PRE_ACT_STAGE, obs)

        CPRL.assign!(x2, v2)
        _, _ = CPRL.fixPoint!(model, CPRL.getOnDomainChange(x2))


        obs = CPRL.get_observation!(lh, model, x3)
        lh.agent(RL.POST_ACT_STAGE, obs)

        v3 = lh.agent(RL.PRE_ACT_STAGE, obs)

        CPRL.assign!(x3, v3)
        _, _ = CPRL.fixPoint!(model, CPRL.getOnDomainChange(x2))


        obs = CPRL.get_observation!(lh, model, x4)
        lh.agent(RL.POST_ACT_STAGE, obs)

        v4 = lh.agent(RL.PRE_ACT_STAGE, obs)

    end

end
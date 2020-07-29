agent = RL.Agent(
    policy = RL.QBasedPolicy(
        learner = SeaPearl.CPDQNLearner(
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
    include("lh_utils.jl")

    @testset "LearnedHeuristic" begin 

        learnedheuristic = SeaPearl.LearnedHeuristic(agent)

        @test learnedheuristic.agent == agent
        @test isnothing(learnedheuristic.fitted_problem)
        @test isnothing(learnedheuristic.fitted_strategy)
        @test isnothing(learnedheuristic.action_space)
        @test isnothing(learnedheuristic.current_state)
        @test isnothing(learnedheuristic.current_reward)
        @test isnothing(learnedheuristic.search_metrics)

        learnedheuristic.fitted_problem = SeaPearl.LegacyGraphColoringGenerator
        learnedheuristic.fitted_strategy = SeaPearl.DFSearch

        @test learnedheuristic.fitted_problem == SeaPearl.LegacyGraphColoringGenerator
        @test learnedheuristic.fitted_strategy == SeaPearl.DFSearch

    end


    @testset "LearnedHeuristic in action" begin 

        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        x1 = SeaPearl.IntVar(1, 2, "x1", trailer)
        x2 = SeaPearl.IntVar(1, 2, "x2", trailer)
        x3 = SeaPearl.IntVar(2, 3, "x3", trailer)
        x4 = SeaPearl.IntVar(1, 4, "x4", trailer)
        SeaPearl.addVariable!(model, x1)
        SeaPearl.addVariable!(model, x2)
        SeaPearl.addVariable!(model, x3)
        SeaPearl.addVariable!(model, x4)

        push!(model.constraints, SeaPearl.NotEqual(x1, x2, trailer))
        push!(model.constraints, SeaPearl.NotEqual(x2, x3, trailer))
        push!(model.constraints, SeaPearl.NotEqual(x3, x4, trailer))

        lh = SeaPearl.LearnedHeuristic(agent)
        SeaPearl.update_with_cpmodel!(lh, model)

        false_x = first(values(model.variables))
        obs = SeaPearl.get_observation!(lh, model, false_x)
        lh.agent(RL.PRE_EPISODE_STAGE, obs)


        obs = SeaPearl.get_observation!(lh, model, x1)
        v1 = lh.agent(RL.PRE_ACT_STAGE, obs)

        SeaPearl.assign!(x1, v1)
        _, _ = SeaPearl.fixPoint!(model, SeaPearl.getOnDomainChange(x1))


        obs = SeaPearl.get_observation!(lh, model, x2)
        lh.agent(RL.POST_ACT_STAGE, obs)

        v2 = lh.agent(RL.PRE_ACT_STAGE, obs)

        SeaPearl.assign!(x2, v2)
        _, _ = SeaPearl.fixPoint!(model, SeaPearl.getOnDomainChange(x2))


        obs = SeaPearl.get_observation!(lh, model, x3)
        lh.agent(RL.POST_ACT_STAGE, obs)

        v3 = lh.agent(RL.PRE_ACT_STAGE, obs)

        SeaPearl.assign!(x3, v3)
        _, _ = SeaPearl.fixPoint!(model, SeaPearl.getOnDomainChange(x2))


        obs = SeaPearl.get_observation!(lh, model, x4)
        lh.agent(RL.POST_ACT_STAGE, obs)

        v4 = lh.agent(RL.PRE_ACT_STAGE, obs)

    end

end
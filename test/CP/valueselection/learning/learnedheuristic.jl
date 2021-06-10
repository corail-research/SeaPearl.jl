using Flux


@testset "learnedheuristic.jl" begin

    @testset "LearnedHeuristic" begin 

        learnedheuristic = SeaPearl.LearnedHeuristic(agent)

        @test learnedheuristic.agent == agent
        @test isnothing(learnedheuristic.fitted_problem)
        @test isnothing(learnedheuristic.fitted_strategy)
        @test isnothing(learnedheuristic.action_space)
        @test isnothing(learnedheuristic.current_state)
        @test isnothing(learnedheuristic.reward)
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

        _, _ = SeaPearl.fixPoint!(model)

        obs = SeaPearl.get_observation!(lh, model, x1)
        v1 = lh.agent(obs)
        lh.agent(RL.PRE_ACT_STAGE, obs, v1)

        SeaPearl.assign!(x1, v1)
        _, _ = SeaPearl.fixPoint!(model, SeaPearl.getOnDomainChange(x1))


        obs = SeaPearl.get_observation!(lh, model, x2)
        lh.agent(RL.POST_ACT_STAGE, obs)

        v2 = lh.agent(obs)
        lh.agent(RL.PRE_ACT_STAGE, obs, v2)

        SeaPearl.assign!(x2, v2)
        _, _ = SeaPearl.fixPoint!(model, SeaPearl.getOnDomainChange(x2))


        obs = SeaPearl.get_observation!(lh, model, x3)
        lh.agent(RL.POST_ACT_STAGE, obs)

        v3 = lh.agent(obs)
        lh.agent(RL.PRE_ACT_STAGE, obs, v3)

        SeaPearl.assign!(x3, v3)
        _, _ = SeaPearl.fixPoint!(model, SeaPearl.getOnDomainChange(x2))


        obs = SeaPearl.get_observation!(lh, model, x4)
        lh.agent(RL.POST_ACT_STAGE, obs)

        v4 = lh.agent(obs)
        lh.agent(RL.PRE_ACT_STAGE, obs, v4)

    end

end
@testset "learnedheuristic utils" begin

    @testset "update_with_cpmodel!()" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        x = SeaPearl.IntVar(2, 3, "x", trailer)
        y = SeaPearl.IntVar(2, 3, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        push!(model.constraints, SeaPearl.Equal(x, y, trailer))
        push!(model.constraints, SeaPearl.NotEqual(x, y, trailer))

        lh = SeaPearl.LearnedHeuristic(agent)

        SeaPearl.update_with_cpmodel!(lh, model)

        @test typeof(lh.action_space) == RL.DiscreteSpace{Array{Int64,1}}
        @test lh.action_space.span == [2, 3]
        @test typeof(lh.current_state) == SeaPearl.DefaultStateRepresentation{SeaPearl.DefaultFeaturization}
        @test lh.current_reward == 0
        @test isa(lh.search_metrics, SeaPearl.SearchMetrics)
    end 

    @testset "sync_state!()" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        x = SeaPearl.IntVar(2, 3, "x", trailer)
        y = SeaPearl.IntVar(2, 3, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        push!(model.constraints, SeaPearl.Equal(x, y, trailer))
        push!(model.constraints, SeaPearl.NotEqual(x, y, trailer))

        lh = SeaPearl.LearnedHeuristic(agent)
        SeaPearl.update_with_cpmodel!(lh, model)

        SeaPearl.sync_state!(lh, model, x)

        @test Matrix(LightGraphs.LinAlg.adjacency_matrix(lh.current_state.cplayergraph)) == [0 0 1 1 0 0
                                                        0 0 1 1 0 0
                                                        1 1 0 0 1 1
                                                        1 1 0 0 1 1
                                                        0 0 1 1 0 0
                                                        0 0 1 1 0 0]

        @test lh.current_state.features == Float32[ 1 1 0 0 0 0
                                                            0 0 1 1 0 0
                                                            0 0 0 0 1 1]
        
        @test lh.current_state.variable_id == 3

        SeaPearl.assign!(x, 2)
        SeaPearl.sync_state!(lh, model, y)

        @test Matrix(LightGraphs.LinAlg.adjacency_matrix(lh.current_state.cplayergraph)) == [0 0 1 1 0 0
                                                        0 0 1 1 0 0
                                                        1 1 0 0 1 0
                                                        1 1 0 0 1 1
                                                        0 0 1 1 0 0
                                                        0 0 0 1 0 0]

        @test lh.current_state.features == Float32[ 1 1 0 0 0 0
                                                            0 0 1 1 0 0
                                                            0 0 0 0 1 1]
        
        @test lh.current_state.variable_id == 4
    end

    @testset "get_observation!()" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        x = SeaPearl.IntVar(2, 3, "x", trailer)
        y = SeaPearl.IntVar(2, 3, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        push!(model.constraints, SeaPearl.Equal(x, y, trailer))
        push!(model.constraints, SeaPearl.NotEqual(x, y, trailer))

        lh = SeaPearl.LearnedHeuristic(agent)
        SeaPearl.update_with_cpmodel!(lh, model)

        obs = SeaPearl.get_observation!(lh, model, x)

        @test obs.reward == 0
        @test obs.terminal == false 
        @test obs.legal_actions == [2, 3]
        @test obs.legal_actions_mask == [true, true]

        SeaPearl.remove!(x.domain, 2)

        obs = SeaPearl.get_observation!(lh, model, x)

        @test obs.reward == 0
        @test obs.terminal == false 
        @test obs.legal_actions == [3]
        @test obs.legal_actions_mask == [false, true]

    end

    @testset "action_to_value(::FixedOutput)" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        x = SeaPearl.IntVar(2, 3, "x", trailer)
        y = SeaPearl.IntVar(2, 3, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)

        lh = SeaPearl.LearnedHeuristic{SeaPearl.DefaultStateRepresentation, SeaPearl.DefaultReward, SeaPearl.FixedOutput}(agent)
        SeaPearl.update_with_cpmodel!(lh, model)

        obs = SeaPearl.get_observation!(lh, model, x)

        @test SeaPearl.action_to_value(lh, 1, obs.state, model) == 2
        @test SeaPearl.action_to_value(lh, 2, obs.state, model) == 3
        @test_throws BoundsError SeaPearl.action_to_value(lh, 3, obs.state, model)
    end

    @testset "action_to_value(::VariableOutput)" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        x = SeaPearl.IntVar(2, 3, "x", trailer)
        y = SeaPearl.IntVar(2, 4, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)


        lh = SeaPearl.LearnedHeuristic{SeaPearl.DefaultStateRepresentation, SeaPearl.DefaultReward, SeaPearl.VariableOutput}(agent)
        SeaPearl.update_with_cpmodel!(lh, model)

        obs = SeaPearl.get_observation!(lh, model, y)
        @test SeaPearl.action_to_value(lh, 1, obs.state, model) == 4
        @test SeaPearl.action_to_value(lh, 2, obs.state, model) == 2
        @test SeaPearl.action_to_value(lh, 3, obs.state, model) == 3
        @test_throws BoundsError SeaPearl.action_to_value(lh, 4, obs.state, model)


        SeaPearl.remove!(y.domain, 3)
        SeaPearl.update_with_cpmodel!(lh, model)

        obs = SeaPearl.get_observation!(lh, model, y)
        @test SeaPearl.action_to_value(lh, 1, obs.state, model) == 4
        @test SeaPearl.action_to_value(lh, 2, obs.state, model) == 2
        @test_throws BoundsError SeaPearl.action_to_value(lh, 3, obs.state, model)

        obs = SeaPearl.get_observation!(lh, model, x)
        @test SeaPearl.action_to_value(lh, 1, obs.state, model) == 2
        @test SeaPearl.action_to_value(lh, 2, obs.state, model) == 3
        @test_throws BoundsError SeaPearl.action_to_value(lh, 4, obs.state, model)
    end
end
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
        @test typeof(lh.current_state) == CPRL.DefaultStateRepresentation{CPRL.DefaultFeaturization}
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

        CPRL.assign!(x, 2)
        CPRL.sync_state!(lh, model, y)

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

    @testset "action_to_value(::FixedOutput)" begin
        trailer = CPRL.Trailer()
        model = CPRL.CPModel(trailer)

        x = CPRL.IntVar(2, 3, "x", trailer)
        y = CPRL.IntVar(2, 3, "y", trailer)
        CPRL.addVariable!(model, x)
        CPRL.addVariable!(model, y)

        lh = CPRL.LearnedHeuristic{CPRL.DefaultStateRepresentation, CPRL.DefaultReward, CPRL.FixedOutput}(agent)
        CPRL.update_with_cpmodel!(lh, model)

        obs = CPRL.get_observation!(lh, model, x)

        @test CPRL.action_to_value(lh, 1, obs.state, model) == 2
        @test CPRL.action_to_value(lh, 2, obs.state, model) == 3
        @test_throws BoundsError CPRL.action_to_value(lh, 3, obs.state, model)
    end

    @testset "action_to_value(::VariableOutput)" begin
        trailer = CPRL.Trailer()
        model = CPRL.CPModel(trailer)

        x = CPRL.IntVar(2, 3, "x", trailer)
        y = CPRL.IntVar(2, 4, "y", trailer)
        CPRL.addVariable!(model, x)
        CPRL.addVariable!(model, y)


        lh = CPRL.LearnedHeuristic{CPRL.DefaultStateRepresentation, CPRL.DefaultReward, CPRL.VariableOutput}(agent)
        CPRL.update_with_cpmodel!(lh, model)

        obs = CPRL.get_observation!(lh, model, y)
        @test CPRL.action_to_value(lh, 1, obs.state, model) == 4
        @test CPRL.action_to_value(lh, 2, obs.state, model) == 2
        @test CPRL.action_to_value(lh, 3, obs.state, model) == 3
        @test_throws BoundsError CPRL.action_to_value(lh, 4, obs.state, model)


        CPRL.remove!(y.domain, 3)
        CPRL.update_with_cpmodel!(lh, model)

        obs = CPRL.get_observation!(lh, model, y)
        @test CPRL.action_to_value(lh, 1, obs.state, model) == 4
        @test CPRL.action_to_value(lh, 2, obs.state, model) == 2
        @test_throws BoundsError CPRL.action_to_value(lh, 3, obs.state, model)

        obs = CPRL.get_observation!(lh, model, x)
        @test CPRL.action_to_value(lh, 1, obs.state, model) == 2
        @test CPRL.action_to_value(lh, 2, obs.state, model) == 3
        @test_throws BoundsError CPRL.action_to_value(lh, 4, obs.state, model)
    end
end
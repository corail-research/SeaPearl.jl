@testset "utils" begin

    @testset "update_with_cpmodel!()" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        x = SeaPearl.IntVar(2, 3, "x", trailer)
        y = SeaPearl.IntVar(3, 4, "y", trailer)
        z = SeaPearl.IntVar(4, 5, "z", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        SeaPearl.addVariable!(model, z; branchable=false)
        SeaPearl.addConstraint!(model, SeaPearl.Equal(x, y, trailer))
        SeaPearl.addConstraint!(model, SeaPearl.NotEqual(x, y, trailer))

        lh = SeaPearl.LearnedHeuristic(agent)

        SeaPearl.update_with_cpmodel!(lh, model)

        @test typeof(lh.action_space) == Array{Int64,1}
        @test lh.action_space == [2, 3, 4]
        @test typeof(lh.current_state) == SeaPearl.DefaultStateRepresentation{SeaPearl.DefaultFeaturization, SeaPearl.DefaultTrajectoryState}
        @test lh.reward.value == 0
        @test isa(lh.search_metrics, SeaPearl.SearchMetrics)
    end 

    @testset "sync_state!()" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        x = SeaPearl.IntVar(2, 3, "x", trailer)
        y = SeaPearl.IntVar(2, 3, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        SeaPearl.addConstraint!(model, SeaPearl.Equal(x, y, trailer))
        SeaPearl.addConstraint!(model, SeaPearl.NotEqual(x, y, trailer))

        lh = SeaPearl.LearnedHeuristic(agent)
        SeaPearl.update_with_cpmodel!(lh, model)

        SeaPearl.sync_state!(lh, model, x)

        @test Matrix(LightGraphs.LinAlg.adjacency_matrix(lh.current_state.cplayergraph)) == [0 0 1 1 0 0
                                                        0 0 1 1 0 0
                                                        1 1 0 0 1 1
                                                        1 1 0 0 1 1
                                                        0 0 1 1 0 0
                                                        0 0 1 1 0 0]

        @test lh.current_state.nodeFeatures == Float32[ 1 1 0 0 0 0
                                                            0 0 1 1 0 0
                                                            0 0 0 0 1 1]
        
        @test lh.current_state.variableIdx == 3

        SeaPearl.assign!(x, 2)
        SeaPearl.sync_state!(lh, model, y)

        @test Matrix(LightGraphs.LinAlg.adjacency_matrix(lh.current_state.cplayergraph)) == [0 0 1 1 0 0
                                                        0 0 1 1 0 0
                                                        1 1 0 0 1 0
                                                        1 1 0 0 1 1
                                                        0 0 1 1 0 0
                                                        0 0 0 1 0 0]

        @test lh.current_state.nodeFeatures == Float32[ 1 1 0 0 0 0
                                                            0 0 1 1 0 0
                                                            0 0 0 0 1 1]
        
        @test lh.current_state.variableIdx == 4
    end

    @testset "get_observation!()" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        x = SeaPearl.IntVar(2, 4, "x", trailer)
        y = SeaPearl.IntVar(6, 8, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        SeaPearl.addConstraint!(model, SeaPearl.Equal(x, y, trailer))
        SeaPearl.addConstraint!(model, SeaPearl.NotEqual(x, y, trailer))

        lh = SeaPearl.LearnedHeuristic(agent)
        SeaPearl.update_with_cpmodel!(lh, model)

        obs = SeaPearl.get_observation!(lh, model, x)

        @test obs.reward == 0
        @test obs.terminal == false 
        @test obs.actions_index==[1, 2, 3, 4, 5, 6]  #correspond to the index of branchable values [2, 3, 4, 6, 7, 8] for ALL variables
        @test obs.legal_actions == [2, 3, 4]
        @test obs.legal_actions_mask == [true, true, true, false, false, false]

        SeaPearl.remove!(x.domain, 2)

        obs = SeaPearl.get_observation!(lh, model, x)

        @test obs.reward == 0
        @test obs.terminal == false 
        @test obs.actions_index==[1, 2, 3, 4, 5, 6]  #correspond to the index of branchable values [2, 3, 4, 6, 7, 8] for ALL variables
        @test obs.legal_actions == [3, 4]
        @test obs.legal_actions_mask == [false, true, true, false, false, false]

        SeaPearl.remove!(y.domain, 7)

        obs = SeaPearl.get_observation!(lh, model, y)

        @test obs.reward == 0
        @test obs.terminal == false 
        @test obs.actions_index==[1, 2, 3, 4, 5, 6]  #correspond to the index of branchable values [2, 3, 4, 6, 7, 8] for ALL variables
        @test obs.legal_actions == [6, 8]
        @test obs.legal_actions_mask == [false, false, false, true, false, true]

    end

    @testset "action_to_value(::FixedOutput)" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        x = SeaPearl.IntVar(2, 3, "x", trailer)
        y = SeaPearl.IntVar(2, 3, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)

        lh = SeaPearl.LearnedHeuristic{SeaPearl.DefaultStateRepresentation{SeaPearl.DefaultFeaturization,SeaPearl.DefaultTrajectoryState}, SeaPearl.DefaultReward, SeaPearl.FixedOutput}(agent)
        SeaPearl.update_with_cpmodel!(lh, model)

        obs = SeaPearl.get_observation!(lh, model, x)

        @test SeaPearl.action_to_value(lh, 1, obs.state, model) == 2
        @test SeaPearl.action_to_value(lh, 2, obs.state, model) == 3
        @test_throws BoundsError SeaPearl.action_to_value(lh, 3, obs.state, model)
    end

    #TODO repair TSPTW testset
    """
    @testset "action_to_value(::VariableOutput)" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        x = SeaPearl.IntVar(2, 3, "x", trailer)
        y = SeaPearl.IntVar(2, 3, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)

        lh = SeaPearl.LearnedHeuristic{SeaPearl.DefaultStateRepresentation{SeaPearl.DefaultFeaturization,SeaPearl.DefaultTrajectoryState}, SeaPearl.DefaultReward, SeaPearl.VariableOutput}(agent)
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
    """
    
    @testset "branchable_values()" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        x = SeaPearl.IntVar(2, 3, "x", trailer)
        y = SeaPearl.IntVar(3, 4, "y", trailer)
        z = SeaPearl.IntSetVar(4, 5, "z", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y; branchable=false)
        SeaPearl.addVariable!(model, z; branchable=false)

        @test SeaPearl.branchable_values(model) == [2, 3]
    end
end
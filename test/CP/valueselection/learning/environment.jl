@testset "environment.jl" begin
    
    @testset "CPEnv{TS}" begin
        graph = Matrix(LightGraphs.adjacency_matrix(LightGraphs.random_regular_graph(6, 3)))
        ts = SeaPearl.DefaultTrajectoryState(SeaPearl.FeaturedGraph(graph; nf=rand(3, 6)), 1, collect(1:4), [1, 4])
        env = SeaPearl.CPEnv{SeaPearl.DefaultTrajectoryState}(
            .0, 
            false, 
            ts, 
            collect(1:4), 
            [1, 4], 
            [true, false, false, true]
        )

        Random.seed!(0)
        actions = Set([agent(env) for I = 1:10])
        
        @test actions == Set([1,4])
    end

    @testset "state copy during solving" begin 

        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        x = SeaPearl.IntVar(2, 4, "x", trailer)
        y = SeaPearl.IntVar(3, 4, "y", trailer)
        z = SeaPearl.IntVar(3, 5, "z", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        SeaPearl.addVariable!(model, z)

        SeaPearl.addConstraint!(model, SeaPearl.NotEqual(x, y, trailer))
        SeaPearl.addConstraint!(model, SeaPearl.NotEqual(y, z, trailer))

        chosen_features = Dict(
            "constraint_activity" => false,
            "constraint_type" => true,
            "nb_involved_constraint_propagation" => false,
            "nb_not_bounded_variable" => false,
            "variable_domain_size" => true,
            "variable_initial_domain_size" => true,
            "variable_is_bound" => false,
            "values_onehot" => true,
            "values_raw" => false,
        )

        lh = SeaPearl.SimpleLearnedHeuristic{SeaPearl.HeterogeneousStateRepresentation{SeaPearl.DefaultFeaturization,SeaPearl.HeterogeneousTrajectoryState}, SeaPearl.DefaultReward, SeaPearl.VariableOutput}(agent; chosen_features=chosen_features)
        
        SeaPearl.update_with_cpmodel!(lh, model, chosen_features=chosen_features)

        state1 = SeaPearl.get_observation!(lh, model, x).state
        SeaPearl.assign!(x, 2)
        state2 = SeaPearl.get_observation!(lh, model, y).state

        @test state1.fg.varnf != state2.fg.varnf
        @test state1.fg.valtovar != state2.fg.valtovar
    end
end
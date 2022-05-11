@testset "heterogeneousstaterepresentation.jl" begin

    @testset "HeterogeneousStateRepresentation structure" begin
        g = SeaPearl.CPLayerGraph()
        variableNodeFeatures = [1.0f0 1.0f0; 2.0f0 2.0f0]
        constraintNodeFeatures = [3.0f0 3.0f0; 4.0f0 4.0f0]
        valueNodeFeatures = [6.0f0 6.0f0; 6.0f0 6.0f0]
        variableIdx = 1
        hsr = SeaPearl.HeterogeneousStateRepresentation{SeaPearl.DefaultFeaturization,SeaPearl.HeterogeneousTrajectoryState}(g, variableNodeFeatures, constraintNodeFeatures, valueNodeFeatures, nothing, variableIdx, nothing, nothing, nothing, nothing, 2, 2, 2)

        @test hsr.cplayergraph == g
        @test hsr.variableNodeFeatures == variableNodeFeatures
        @test hsr.constraintNodeFeatures == constraintNodeFeatures
        @test hsr.valueNodeFeatures == valueNodeFeatures
        @test hsr.variableIdx == 1
    end

    @testset "HeterogeneousSR from CPModel without chosen_features" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        x = SeaPearl.IntVar(3, 3, "x", trailer)
        y = SeaPearl.IntVar(1, 3, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        SeaPearl.addConstraint!(model, SeaPearl.Equal(x, y, trailer))
        SeaPearl.addConstraint!(model, SeaPearl.NotEqual(x, y, trailer))

        hsr = SeaPearl.HeterogeneousStateRepresentation(model)
        SeaPearl.update_representation!(hsr, model, x)

        @test Matrix(LightGraphs.LinAlg.adjacency_matrix(hsr.cplayergraph)) == [
            0 0 1 1 0 0 0
            0 0 1 1 0 0 0
            1 1 0 0 0 1 0
            1 1 0 0 1 1 1
            0 0 0 1 0 0 0
            0 0 1 1 0 0 0
            0 0 0 1 0 0 0]

        # Because chosen_features is not specified, there is no feature
        @test size(hsr.variableNodeFeatures) == (0, 2)
        @test size(hsr.constraintNodeFeatures) == (0, 2)
        @test size(hsr.valueNodeFeatures) == (0, 3)
        @test hsr.variableIdx == 1

        SeaPearl.assign!(y, 2)
        SeaPearl.update_representation!(hsr, model, y)

        @test Matrix(LightGraphs.LinAlg.adjacency_matrix(hsr.cplayergraph)) == [
            0 0 1 1 0 0 0
            0 0 1 1 0 0 0
            1 1 0 0 0 1 0
            1 1 0 0 1 0 0
            0 0 0 1 0 0 0
            0 0 1 0 0 0 0
            0 0 0 0 0 0 0]

        # Because chosen_features is not specified, there is no feature
        @test size(hsr.variableNodeFeatures) == (0, 2)
        @test size(hsr.constraintNodeFeatures) == (0, 2)
        @test size(hsr.valueNodeFeatures) == (0, 3)
        @test hsr.variableIdx == 2
    end


    @testset "HeterogeneousSR from CPModel with chosen_features 1" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        x = SeaPearl.IntVar(3, 3, "x", trailer)
        y = SeaPearl.IntVar(1, 3, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        SeaPearl.addConstraint!(model, SeaPearl.Equal(x, y, trailer))
        SeaPearl.addConstraint!(model, SeaPearl.NotEqual(x, y, trailer))

        chosen_features = Dict(
            "constraint_type" => true,
            "variable_initial_domain_size" => true,
            "values_raw" => true,
        )

        hsr = SeaPearl.HeterogeneousStateRepresentation{SeaPearl.DefaultFeaturization, SeaPearl.HeterogeneousTrajectoryState}(model; chosen_features=chosen_features)
        SeaPearl.update_representation!(hsr, model, x)

        @test Matrix(LightGraphs.LinAlg.adjacency_matrix(hsr.cplayergraph)) == [
            0 0 1 1 0 0 0
            0 0 1 1 0 0 0
            1 1 0 0 0 1 0
            1 1 0 0 1 1 1
            0 0 0 1 0 0 0
            0 0 1 1 0 0 0
            0 0 0 1 0 0 0]

        @test hsr.variableNodeFeatures == [1 3]
        @test hsr.constraintNodeFeatures == [1 0; 0 1]
        @test hsr.valueNodeFeatures == [2 3 1]
        @test hsr.variableIdx == 1

        SeaPearl.assign!(y, 2)
        SeaPearl.update_representation!(hsr, model, y)

        @test Matrix(LightGraphs.LinAlg.adjacency_matrix(hsr.cplayergraph)) == [
            0 0 1 1 0 0 0
            0 0 1 1 0 0 0
            1 1 0 0 0 1 0
            1 1 0 0 1 0 0
            0 0 0 1 0 0 0
            0 0 1 0 0 0 0
            0 0 0 0 0 0 0]

        @test hsr.variableNodeFeatures == [1 3]
        @test hsr.constraintNodeFeatures == [1 0; 0 1]
        @test hsr.valueNodeFeatures == [2 3 1]
        @test hsr.variableIdx == 2
    end

    @testset "HeterogeneousSR from CPModel with chosen_features 2" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        x = SeaPearl.IntVar(3, 3, "x", trailer)
        y = SeaPearl.IntVar(1, 3, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        SeaPearl.addConstraint!(model, SeaPearl.Equal(x, y, trailer))
        SeaPearl.addConstraint!(model, SeaPearl.NotEqual(x, y, trailer))

        chosen_features = Dict(
            "constraint_type" => true,
            "nb_not_bounded_variable" => true,
            "constraint_activity" => true,
            "variable_initial_domain_size" => true,
            "variable_domain_size" => true,
            "variable_is_bound" => true,
            "values_onehot" => true,
        )

        action_space = SeaPearl.branchable_values(model)
        hsr = SeaPearl.HeterogeneousStateRepresentation{SeaPearl.DefaultFeaturization, SeaPearl.HeterogeneousTrajectoryState}(model; action_space=action_space, chosen_features=chosen_features)
        SeaPearl.update_representation!(hsr, model, x)

        @test Matrix(LightGraphs.LinAlg.adjacency_matrix(hsr.cplayergraph)) == [
            0 0 1 1 0 0 0
            0 0 1 1 0 0 0
            1 1 0 0 0 1 0
            1 1 0 0 1 1 1
            0 0 0 1 0 0 0
            0 0 1 1 0 0 0
            0 0 0 1 0 0 0]

        @test hsr.variableNodeFeatures == [1 3; 1 3; 1 0]
        @test hsr.constraintNodeFeatures == [1 1; 1 1; 1 0; 0 1]
        @test hsr.valueNodeFeatures == [1 0 0; 0 1 0; 0 0 1]
        @test hsr.variableIdx == 1

        SeaPearl.assign!(y, 2)
        SeaPearl.update_representation!(hsr, model, y)

        @test Matrix(LightGraphs.LinAlg.adjacency_matrix(hsr.cplayergraph)) == [
            0 0 1 1 0 0 0
            0 0 1 1 0 0 0
            1 1 0 0 0 1 0
            1 1 0 0 1 0 0
            0 0 0 1 0 0 0
            0 0 1 0 0 0 0
            0 0 0 0 0 0 0]

        @test hsr.variableNodeFeatures == [1 3; 1 1; 1 1]
        @test hsr.constraintNodeFeatures == [1 1; 0 0; 1 0; 0 1]
        @test hsr.valueNodeFeatures == [1 0 0; 0 1 0; 0 0 1]
        @test hsr.variableIdx == 2
    end


end
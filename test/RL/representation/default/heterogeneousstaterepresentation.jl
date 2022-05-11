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

        hsr = SeaPearl.HeterogeneousStateRepresentation{SeaPearl.DefaultFeaturization,SeaPearl.HeterogeneousTrajectoryState}(model; chosen_features=chosen_features)
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

        hsr = SeaPearl.HeterogeneousStateRepresentation{SeaPearl.DefaultFeaturization,SeaPearl.HeterogeneousTrajectoryState}(model; action_space=action_space, chosen_features=chosen_features)
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


    @testset "HeterogeneousTrajectoryState constructor" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        x = SeaPearl.IntVar(2, 3, "x", trailer)
        y = SeaPearl.IntVar(2, 3, "y", trailer)
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

        hsr = SeaPearl.HeterogeneousStateRepresentation{SeaPearl.DefaultFeaturization,SeaPearl.HeterogeneousTrajectoryState}(model; action_space=action_space, chosen_features=chosen_features)
        SeaPearl.update_representation!(hsr, model, x) #add x as the branching variable
        hts = SeaPearl.HeterogeneousTrajectoryState(hsr)  #creates the HeterogeneousTrajectoryState object

        batchedHtsSingle = hts |> cpu
        @test batchedHtsSingle.fg.contovar[:, :, 1] == hts.fg.contovar
        @test batchedHtsSingle.fg.valtovar[:, :, 1] == hts.fg.valtovar
        @test batchedHtsSingle.fg.varnf[:, :, 1] == hts.fg.varnf
        @test batchedHtsSingle.fg.connf[:, :, 1] == hts.fg.connf
        @test batchedHtsSingle.fg.valnf[:, :, 1] == hts.fg.valnf
        @test batchedHtsSingle.fg.gf[:, 1] == hts.fg.gf
        @test batchedHtsSingle.variableIdx[1] == hts.variableIdx

        SeaPearl.assign!(x, 2)
        SeaPearl.fixPoint!(model, SeaPearl.getOnDomainChange(x))
        SeaPearl.update_representation!(hsr, model, x) #add x as the branching variable
        hts2 = SeaPearl.HeterogeneousTrajectoryState(hsr)  #creates the HeterogeneousTrajectoryState object

        batchedHts = [hts, hts2] |> cpu
        @test size(batchedHts.fg.contovar, 3) == 2
        @test size(batchedHts.fg.valtovar, 3) == 2
        @test size(batchedHts.fg.varnf, 3) == 2
        @test size(batchedHts.fg.connf, 3) == 2
        @test size(batchedHts.fg.valnf, 3) == 2
        @test size(batchedHts.fg.gf, 2) == 2
        @test size(batchedHts.variableIdx, 1) == 2
    end

    @testset "HeterogeneousSR with on the square graph coloring problem" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        # Testing chosen_features on a toy example: the square graph coloring problem
        x = SeaPearl.IntVar[]
        for i in 1:4
            push!(x, SeaPearl.IntVar(1, 4, string(i), model.trailer))
            SeaPearl.addVariable!(model, last(x))
        end
        # Edge constraints
        SeaPearl.addConstraint!(model, SeaPearl.NotEqual(x[1], x[2], model.trailer))
        SeaPearl.addConstraint!(model, SeaPearl.NotEqual(x[2], x[3], model.trailer))
        SeaPearl.addConstraint!(model, SeaPearl.NotEqual(x[3], x[4], model.trailer))
        SeaPearl.addConstraint!(model, SeaPearl.NotEqual(x[4], x[1], model.trailer))
        # Objective
        numberOfColors = SeaPearl.IntVar(1, 4, "numberOfColors", model.trailer)
        SeaPearl.addVariable!(model, numberOfColors)
        for var in x
            SeaPearl.addConstraint!(model, SeaPearl.LessOrEqual(var, numberOfColors, model.trailer))
        end
        model.objective = numberOfColors

        # Choosing features and initializing the state representation
        chosen_features = Dict(
            "constraint_type" => true,
            "nb_not_bounded_variable" => true,
            "constraint_activity" => true,
            "variable_initial_domain_size" => true,
            "variable_domain_size" => true,
            "variable_is_bound" => true,
            "values_onehot" => true,
        )
        hsr = SeaPearl.HeterogeneousStateRepresentation{SeaPearl.DefaultFeaturization,SeaPearl.HeterogeneousTrajectoryState}(model; action_space=1:4, chosen_features=chosen_features)

        contovar, valtovar = SeaPearl.adjacency_matrices(hsr.cplayergraph)

        @test contovar == [
            1 1 0 0 0
            0 1 1 0 0
            0 0 1 1 0
            1 0 0 1 0
            1 0 0 0 1
            0 1 0 0 1
            0 0 1 0 1
            0 0 0 1 1
        ]

        @test valtovar == [
            1 1 1 1 1
            1 1 1 1 1
            1 1 1 1 1
            1 1 1 1 1
        ]

        @test SeaPearl.branchable_values(model) == [4, 2, 3, 1]

        # Testing the initialization of the node features
        @test hsr.variableNodeFeatures == [4 4 4 4 4; 4 4 4 4 4; 0 0 0 0 0]
        @test hsr.constraintNodeFeatures == [1 1 1 1 1 1 1 1; 2 2 2 2 2 2 2 2; 1 1 1 1 0 0 0 0; 0 0 0 0 1 1 1 1]
        @test hsr.valueNodeFeatures == [0 0 0 1; 0 1 0 0; 0 0 1 0; 1 0 0 0]

        # assign color 1 to x[1]
        prunedDomains = SeaPearl.CPModification()
        SeaPearl.addToPrunedDomains!(prunedDomains, x[1], SeaPearl.assign!(x[1].domain, 1))
        feasible, pruned = SeaPearl.fixPoint!(model, nothing, prunedDomains)
        SeaPearl.update_features!(hsr, model)

        contovar, valtovar = SeaPearl.adjacency_matrices(hsr.cplayergraph)

        println(valtovar)

        @test contovar == [
            1 1 0 0 0
            0 1 1 0 0
            0 0 1 1 0
            1 0 0 1 0
            1 0 0 0 1
            0 1 0 0 1
            0 0 1 0 1
            0 0 0 1 1
        ]

        @test valtovar == [
            0 1 1 1 1
            0 1 1 1 1
            0 1 1 1 1
            1 0 1 0 0
        ]

        # Testing the node features after fixPoint!
        @test hsr.variableNodeFeatures == [4 4 4 4 4; 1 3 4 3 3; 1 0 0 0 0]
        @test hsr.constraintNodeFeatures == [0 1 1 0 0 1 1 1; 1 2 2 1 1 2 2 2; 1 1 1 1 0 0 0 0; 0 0 0 0 1 1 1 1]
        @test hsr.valueNodeFeatures == [0 0 0 1; 0 1 0 0; 0 0 1 0; 1 0 0 0]
    end

end
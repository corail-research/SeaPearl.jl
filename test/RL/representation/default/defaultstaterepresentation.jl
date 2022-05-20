adj = [0 1 0 1;
       1 0 1 0;
       0 1 0 1;
       1 0 1 0]

@testset "defaultstaterepresentation.jl" begin
    
    @testset "DefaultStateRepresentation structure" begin
        g = SeaPearl.CPLayerGraph()
        nodeFeatures = [1.0f0 1.0f0; 2.0f0 2.0f0]
        variableIdx = 1
        dsr = SeaPearl.DefaultStateRepresentation{SeaPearl.DefaultFeaturization,SeaPearl.DefaultTrajectoryState}(g, nodeFeatures, nothing, variableIdx, nothing, nothing, nothing, nothing, nothing, 3)

        @test dsr.cplayergraph == g
        @test dsr.nodeFeatures == nodeFeatures
        @test dsr.variableIdx == 1

    end

    @testset "DefaultSR from CPModel" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        x = SeaPearl.IntVar(3, 3, "x", trailer)
        y = SeaPearl.IntVar(2, 3, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        SeaPearl.addConstraint!(model, SeaPearl.Equal(x, y, trailer))
        SeaPearl.addConstraint!(model, SeaPearl.NotEqual(x, y, trailer))

        dsr = SeaPearl.DefaultStateRepresentation(model)
        SeaPearl.update_representation!(dsr, model, x)


        @test Matrix(LightGraphs.LinAlg.adjacency_matrix(dsr.cplayergraph)) == [0 0 1 1 0 0
                                                                                0 0 1 1 0 0
                                                                                1 1 0 0 0 1
                                                                                1 1 0 0 1 1
                                                                                0 0 0 1 0 0
                                                                                0 0 1 1 0 0]

        @test dsr.nodeFeatures == Float32[  1 1 0 0 0 0
                                        0 0 1 1 0 0
                                        0 0 0 0 1 1]
        @test dsr.variableIdx == 3
        @test SeaPearl.cpVertexFromIndex(SeaPearl.CPLayerGraph(model), dsr.variableIdx).variable == model.variables["x"]
    end

    @testset "update_representation!()" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        x = SeaPearl.IntVar(2, 3, "x", trailer)
        y = SeaPearl.IntVar(2, 3, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        SeaPearl.addConstraint!(model, SeaPearl.Equal(x, y, trailer))
        SeaPearl.addConstraint!(model, SeaPearl.NotEqual(x, y, trailer))

        dsr = SeaPearl.DefaultStateRepresentation(model)
        SeaPearl.update_representation!(dsr, model, x)

        @test Matrix(LightGraphs.LinAlg.adjacency_matrix(dsr.cplayergraph)) == [0 0 1 1 0 0
                                                    0 0 1 1 0 0
                                                    1 1 0 0 1 1
                                                    1 1 0 0 1 1
                                                    0 0 1 1 0 0
                                                    0 0 1 1 0 0]

        @test dsr.nodeFeatures == Float32[   1 1 0 0 0 0
                                                        0 0 1 1 0 0
                                                        0 0 0 0 1 1]

        @test dsr.variableIdx == 3
        @test SeaPearl.cpVertexFromIndex(SeaPearl.CPLayerGraph(model), dsr.variableIdx).variable == model.variables["x"]

        SeaPearl.assign!(y, 2)
        g = SeaPearl.CPLayerGraph(model)

        SeaPearl.update_representation!(dsr, model, y)

        @test Matrix(LightGraphs.LinAlg.adjacency_matrix(dsr.cplayergraph)) == [0 0 1 1 0 0
                                                    0 0 1 1 0 0
                                                    1 1 0 0 1 1
                                                    1 1 0 0 1 0
                                                    0 0 1 1 0 0
                                                    0 0 1 0 0 0]

        @test dsr.nodeFeatures == Float32[   1 1 0 0 0 0
                                                        0 0 1 1 0 0
                                                        0 0 0 0 1 1]
        @test dsr.variableIdx == 4
        @test SeaPearl.cpVertexFromIndex(g, dsr.variableIdx).variable == model.variables["y"]

    end


    @testset "trajectoryState constructor" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
    
        x = SeaPearl.IntVar(2, 3, "x", trailer)
        y = SeaPearl.IntVar(2, 3, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        SeaPearl.addConstraint!(model, SeaPearl.Equal(x, y, trailer))
        SeaPearl.addConstraint!(model, SeaPearl.NotEqual(x, y, trailer))
    

        dsr = SeaPearl.DefaultStateRepresentation(model)
        SeaPearl.update_representation!(dsr, model, x) #add x as the branching variable
        dts = SeaPearl.DefaultTrajectoryState(dsr)  #creates the DefaultTrajectoryState object

        @test dts.variableIdx == SeaPearl.indexFromCpVertex(dsr.cplayergraph, SeaPearl.VariableVertex(x))

    end

    @testset "BatchedDefaultTrajectoryState constructor" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
    
        x = SeaPearl.IntVar(2, 3, "x", trailer)
        y = SeaPearl.IntVar(2, 3, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        SeaPearl.addConstraint!(model, SeaPearl.Equal(x, y, trailer))
        SeaPearl.addConstraint!(model, SeaPearl.NotEqual(x, y, trailer))
    

        dsr = SeaPearl.DefaultStateRepresentation(model)
        SeaPearl.update_representation!(dsr, model, x) #add x as the branching variable
        dts = SeaPearl.DefaultTrajectoryState(dsr)  #creates the DefaultTrajectoryState object

        batchedDtsSingle = dts |> cpu   
        @test batchedDtsSingle.fg.graph[:,:,1]== dts.fg.graph
        @test batchedDtsSingle.fg.nf[:,:,1] == dts.fg.nf
        @test batchedDtsSingle.fg.ef[:,:,:,1] == dts.fg.ef
        @test batchedDtsSingle.fg.gf[:,1] == dts.fg.gf
        @test batchedDtsSingle.variableIdx[1] == dts.variableIdx

        SeaPearl.assign!(x, 2)
        SeaPearl.fixPoint!(model, SeaPearl.getOnDomainChange(x))
        SeaPearl.update_representation!(dsr, model, x) #add x as the branching variable
        dts2 = SeaPearl.DefaultTrajectoryState(dsr)  #creates the DefaultTrajectoryState object


        batchedDts = [dts,dts2] |> cpu   
        @test size(batchedDts.fg.graph,3) == 2
        @test size(batchedDts.fg.nf,3) == 2
        @test size(batchedDts.fg.ef,4) == 2
        @test size(batchedDts.fg.gf,2) == 2
        @test size(batchedDts.variableIdx,1) == 2
    end

    @testset "DefaultFeaturization with chosen_features without ordered values" begin
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
        SeaPearl.addVariable!(model, numberOfColors; branchable=false)
        for var in x
            SeaPearl.addConstraint!(model, SeaPearl.LessOrEqual(var, numberOfColors, model.trailer))
        end
        model.objective = numberOfColors
        
        # Choosing features and initializing the state representation
        chosen_features = Dict(
            "constraint_activity" => true, 
            "constraint_type" => true,
            "values_onehot" => true,
            "values_raw" => false,
            "variable_initial_domain_size" => true,
            "variable_domain_size" => false,
            "variable_is_bound" => false,
            "variable_is_branchable" => true,
            "variable_is_objective" => true,
            "nb_involved_constraint_propagation" => true,
            "nb_not_bounded_variable" => false
        )
        sr = SeaPearl.DefaultStateRepresentation{SeaPearl.DefaultFeaturization, SeaPearl.DefaultTrajectoryState}(model; action_space = 1:4, chosen_features=chosen_features)

        # Testing the initialization of the node features
        # TODO: improve the tests here
        @test sr.nodeFeatures[1:3,:] == Float32[1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0; 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 1.0 1.0 1.0 1.0 1.0 0.0 0.0 0.0 0.0; 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 1.0 1.0 1.0 1.0]
        @test sr.nodeFeatures[4,:] == Float32[1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        @test sr.nodeFeatures[5,:] == Float32[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        @test sr.nodeFeatures[6,:] == Float32[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 4.0, 4.0, 4.0, 4.0, 4.0, 0.0, 0.0, 0.0, 0.0]
        @test sr.nodeFeatures[7,:] == Float32[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        @test sr.nodeFeatures[8,:] == Float32[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0]
        @test sum(sr.nodeFeatures[9:10,:],dims=1) == Float32[1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0]
        @test sr.nodeFeatures[11:14,:] == Float32[0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 1.0; 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 1.0 0.0 0.0; 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 1.0 0.0; 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 1.0 0.0 0.0 0.0]

        
        # assign color 1 to x[1]
        prunedDomains = SeaPearl.CPModification();
        SeaPearl.addToPrunedDomains!(prunedDomains, x[1], SeaPearl.assign!(x[1].domain, 1));
        feasible, pruned = SeaPearl.fixPoint!(model, nothing, prunedDomains)
        SeaPearl.update_features!(sr, model)

        # TODO: improve the tests here
        @test sr.nodeFeatures[1:3,:] == Float32[1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0; 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 1.0 1.0 1.0 1.0 1.0 0.0 0.0 0.0 0.0; 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 1.0 1.0 1.0 1.0]
        @test sr.nodeFeatures[4,:] == Float32[0.0, 1.0, 1.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        @test all(sr.nodeFeatures[5,1:8] .> Float32[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
        @test sr.nodeFeatures[6,:] == Float32[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 4.0, 4.0, 4.0, 4.0, 4.0, 0.0, 0.0, 0.0, 0.0]
        @test sr.nodeFeatures[7,:] == Float32[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        @test sr.nodeFeatures[8,:] == Float32[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0]
        @test sum(sr.nodeFeatures[9:10,:],dims=1) == Float32[1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0]
        @test sr.nodeFeatures[11:14,:] == Float32[0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 1.0; 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 1.0 0.0 0.0; 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 1.0 0.0; 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 1.0 0.0 0.0 0.0]
        
    end

    @testset "DefaultFeaturization with chosen_features with value ordering" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        # Testing chosen_features on a toy example
        x = SeaPearl.IntVar(1, 4, "x", model.trailer)
        y = SeaPearl.IntVar(4, 5, "y", model.trailer)
        z = SeaPearl.IntVar(2, 6, "z", model.trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        SeaPearl.addVariable!(model, z)
        # Edge constraints
        SeaPearl.addConstraint!(model, SeaPearl.LessOrEqual(z, y, model.trailer))
        SeaPearl.addConstraint!(model, SeaPearl.LessOrEqual(y, x, model.trailer))
        # Objective
        model.objective = 3*z

        # Choosing features and initializing the state representation
        chosen_features = Dict(
            "constraint_activity" => true,
            "constraint_type" => true,
            "values_onehot" => false,
            "values_raw" => true,
            "variable_initial_domain_size" => true,
            "variable_domain_size" => false,
            "variable_is_bound" => false,
            "nb_involved_constraint_propagation" => true,
            "nb_not_bounded_variable" => false
        )
        sr = SeaPearl.DefaultStateRepresentation{SeaPearl.DefaultFeaturization, SeaPearl.DefaultTrajectoryState}(model; chosen_features=chosen_features)

        # Testing the initialization of the node features
        # TODO: improve the tests here
        @test sr.nodeFeatures[1:3,:] == Float32[1.0 1.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0; 0.0 0.0 1.0 1.0 1.0 0.0 0.0 0.0 0.0 0.0 0.0; 0.0 0.0 0.0 0.0 0.0 1.0 1.0 1.0 1.0 1.0 1.0]
        @test sr.nodeFeatures[4,:] == Float32[1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        @test sr.nodeFeatures[5,:] == Float32[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        @test sr.nodeFeatures[6,:] == Float32[0.0, 0.0, 4.0, 2.0, 5.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        @test sr.nodeFeatures[7,:] == Float32[1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        @test sum(sr.nodeFeatures[8,:]) == sum(Float32[0.0, 0.0, 0.0, 0.0, 0.0, 5.0, 4.0, 6.0, 2.0, 3.0, 1.0])

        
        # assign value 4 to x
        prunedDomains = SeaPearl.CPModification();
        SeaPearl.addToPrunedDomains!(prunedDomains, x, SeaPearl.assign!(x.domain, 4));
        feasible, pruned = SeaPearl.fixPoint!(model, nothing, prunedDomains)
        SeaPearl.update_features!(sr, model)

        # TODO: improve the tests here
        @test sr.nodeFeatures[1:3,:] == Float32[1.0 1.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0; 0.0 0.0 1.0 1.0 1.0 0.0 0.0 0.0 0.0 0.0 0.0; 0.0 0.0 0.0 0.0 0.0 1.0 1.0 1.0 1.0 1.0 1.0]
        @test sr.nodeFeatures[4,:] == Float32[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        @test all(sr.nodeFeatures[5,1:2] .> Float32[0.0, 0.0])
        @test sr.nodeFeatures[6,:] == Float32[0.0, 0.0, 4.0, 2.0, 5.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        @test sr.nodeFeatures[7,:] == Float32[1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        @test sum(sr.nodeFeatures[8,:]) == sum(Float32[0.0, 0.0, 0.0, 0.0, 0.0, 5.0, 4.0, 6.0, 2.0, 3.0, 1.0])
    end
end
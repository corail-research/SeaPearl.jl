using GraphSignals

adj = [0 1 0 1;
       1 0 1 0;
       0 1 0 1;
       1 0 1 0]

@testset "defaultstaterepresentation.jl" begin
    
    @testset "DefaultStateRepresentation structure" begin
        g = SeaPearl.CPLayerGraph()
        features = [1.0f0 1.0f0; 2.0f0 2.0f0]
        variableIdx = 1
        dsr = SeaPearl.DefaultStateRepresentation{SeaPearl.DefaultFeaturization,SeaPearl.DefaultTrajectoryState}(g, features, variableIdx)

        @test dsr.cplayergraph == g
        @test dsr.features == features
        @test dsr.variableIdx == 1

    end

    @testset "DefaultSR from CPModel" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        x = SeaPearl.IntVar(3, 3, "x", trailer)
        y = SeaPearl.IntVar(2, 3, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        push!(model.constraints, SeaPearl.Equal(x, y, trailer))
        push!(model.constraints, SeaPearl.NotEqual(x, y, trailer))

        dsr = SeaPearl.DefaultStateRepresentation(model)
        SeaPearl.update_representation!(dsr, model, x)


        @test Matrix(LightGraphs.LinAlg.adjacency_matrix(dsr.cplayergraph)) == [0 0 1 1 0 0
                                                                                0 0 1 1 0 0
                                                                                1 1 0 0 0 1
                                                                                1 1 0 0 1 1
                                                                                0 0 0 1 0 0
                                                                                0 0 1 1 0 0]

        @test dsr.features == Float32[  1 1 0 0 0 0
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
        push!(model.constraints, SeaPearl.Equal(x, y, trailer))
        push!(model.constraints, SeaPearl.NotEqual(x, y, trailer))

        dsr = SeaPearl.DefaultStateRepresentation(model)
        SeaPearl.update_representation!(dsr, model, x)

        @test Matrix(LightGraphs.LinAlg.adjacency_matrix(dsr.cplayergraph)) == [0 0 1 1 0 0
                                                    0 0 1 1 0 0
                                                    1 1 0 0 1 1
                                                    1 1 0 0 1 1
                                                    0 0 1 1 0 0
                                                    0 0 1 1 0 0]

        @test dsr.features == Float32[   1 1 0 0 0 0
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

        @test dsr.features == Float32[   1 1 0 0 0 0
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
        push!(model.constraints, SeaPearl.Equal(x, y, trailer))
        push!(model.constraints, SeaPearl.NotEqual(x, y, trailer))
    

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
        push!(model.constraints, SeaPearl.Equal(x, y, trailer))
        push!(model.constraints, SeaPearl.NotEqual(x, y, trailer))
    

        dsr = SeaPearl.DefaultStateRepresentation(model)
        SeaPearl.update_representation!(dsr, model, x) #add x as the branching variable
        dts = SeaPearl.DefaultTrajectoryState(dsr)  #creates the DefaultTrajectoryState object

        batchedDtsSingle = dts |> cpu   
        @test batchedDtsSingle.adjacencies[:,:,1]== adjacency_matrix(dts.fg)
        @test batchedDtsSingle.nodeFeatures[:,:,1] == dts.fg.nf
        @test batchedDtsSingle.edgeFeatures[:,:,1] == dts.fg.ef
        @test batchedDtsSingle.globalFeatures[:,1] == dts.fg.gf
        @test batchedDtsSingle.variables[1] == dts.variableIdx

        SeaPearl.assign!(x, 2)
        SeaPearl.fixPoint!(model, SeaPearl.getOnDomainChange(x))
        SeaPearl.update_representation!(dsr, model, x) #add x as the branching variable
        dts2 = SeaPearl.DefaultTrajectoryState(dsr)  #creates the DefaultTrajectoryState object


        batchedDts = [dts,dts2] |> cpu   
        @test size(batchedDts.adjacencies,3) == 2
        @test size(batchedDts.nodeFeatures,3) == 2
        @test size(batchedDts.edgeFeatures,3) == 2
        @test size(batchedDts.globalFeatures,2) == 2
        @test size(batchedDts.variables,1) == 2
    end
end
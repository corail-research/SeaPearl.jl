adj = [0 1 0 1;
       1 0 1 0;
       0 1 0 1;
       1 0 1 0]

@testset "defaultstaterepresentation.jl" begin
    
    @testset "DefaultStateRepresentation structure" begin
        g = CPRL.CPLayerGraph()
        features = [1.0f0 1.0f0; 2.0f0 2.0f0]
        variable_id = 1
        dsr = CPRL.DefaultStateRepresentation{CPRL.DefaultFeaturization}(g, features, variable_id, [1, 2, 3])

        @test dsr.cplayergraph == g
        @test dsr.features == features
        @test dsr.variable_id == 1
        @test dsr.possible_value_ids == [1, 2, 3]

    end

    @testset "DefaultSR from CPModel" begin
        trailer = CPRL.Trailer()
        model = CPRL.CPModel(trailer)

        x = CPRL.IntVar(3, 3, "x", trailer)
        y = CPRL.IntVar(2, 3, "y", trailer)
        CPRL.addVariable!(model, x)
        CPRL.addVariable!(model, y)
        push!(model.constraints, CPRL.Equal(x, y, trailer))
        push!(model.constraints, CPRL.NotEqual(x, y, trailer))

        dsr = CPRL.DefaultStateRepresentation(model)
        CPRL.update_representation!(dsr, model, x)


        @test Matrix(LightGraphs.LinAlg.adjacency_matrix(dsr.cplayergraph)) == [0 0 1 1 0 0
                                                                                0 0 1 1 0 0
                                                                                1 1 0 0 0 1
                                                                                1 1 0 0 1 1
                                                                                0 0 0 1 0 0
                                                                                0 0 1 1 0 0]

        @test dsr.features == Float32[  1 1 0 0 0 0
                                        0 0 1 1 0 0
                                        0 0 0 0 1 1]
        @test dsr.variable_id == 3
        @test dsr.possible_value_ids == [6]
        @test CPRL.cpVertexFromIndex(CPRL.CPLayerGraph(model), dsr.variable_id).variable == model.variables["x"]
    end

    @testset "update_representation!()" begin
        trailer = CPRL.Trailer()
        model = CPRL.CPModel(trailer)

        x = CPRL.IntVar(2, 3, "x", trailer)
        y = CPRL.IntVar(2, 3, "y", trailer)
        CPRL.addVariable!(model, x)
        CPRL.addVariable!(model, y)
        push!(model.constraints, CPRL.Equal(x, y, trailer))
        push!(model.constraints, CPRL.NotEqual(x, y, trailer))

        dsr = CPRL.DefaultStateRepresentation(model)
        CPRL.update_representation!(dsr, model, x)

        @test Matrix(LightGraphs.LinAlg.adjacency_matrix(dsr.cplayergraph)) == [0 0 1 1 0 0
                                                    0 0 1 1 0 0
                                                    1 1 0 0 1 1
                                                    1 1 0 0 1 1
                                                    0 0 1 1 0 0
                                                    0 0 1 1 0 0]

        @test dsr.features == Float32[   1 1 0 0 0 0
                                                        0 0 1 1 0 0
                                                        0 0 0 0 1 1]

        @test dsr.variable_id == 3
        @test dsr.possible_value_ids == [5, 6]
        @test CPRL.cpVertexFromIndex(CPRL.CPLayerGraph(model), dsr.variable_id).variable == model.variables["x"]

        CPRL.assign!(y, 2)
        g = CPRL.CPLayerGraph(model)

        CPRL.update_representation!(dsr, model, y)

        @test Matrix(LightGraphs.LinAlg.adjacency_matrix(dsr.cplayergraph)) == [0 0 1 1 0 0
                                                    0 0 1 1 0 0
                                                    1 1 0 0 1 1
                                                    1 1 0 0 1 0
                                                    0 0 1 1 0 0
                                                    0 0 1 0 0 0]

        @test dsr.features == Float32[   1 1 0 0 0 0
                                                        0 0 1 1 0 0
                                                        0 0 0 0 1 1]
        @test dsr.variable_id == 4
        @test dsr.possible_value_ids == [5]
        @test CPRL.cpVertexFromIndex(g, dsr.variable_id).variable == model.variables["y"]

    end

    @testset "featuredgraph() from array" begin

        array = Float32[    1 0 0 1 1 0 0 0 0 1 0 0 0 0
                            1 0 0 1 1 0 0 0 0 1 0 0 0 0
                            1 1 1 0 0 1 1 0 0 0 1 0 1 0
                            1 1 1 0 0 1 1 0 0 0 1 0 0 0
                            1 0 0 1 1 0 0 0 0 0 0 1 0 0
                            1 0 0 1 1 0 0 0 0 0 0 1 0 1
                            0 0 0 0 0 0 0 0 0 0 0 0 0 0
                            0 0 0 0 0 0 0 0 0 0 0 0 0 0]

        fg = CPRL.featuredgraph(array)

        @test Matrix(fg.graph[]) == Float32[ 0 0 1 1 0 0
                                                            0 0 1 1 0 0
                                                            1 1 0 0 1 1
                                                            1 1 0 0 1 1
                                                            0 0 1 1 0 0
                                                            0 0 1 1 0 0]

        @test fg.feature[] == Float32[   1 1 0 0 0 0
                                                        0 0 1 1 0 0
                                                        0 0 0 0 1 1]

    end

    @testset "branchingvariable_id() from array" begin

        array = Float32[    1 0 0 1 1 0 0 0 0 1 0 0 0 0
                            1 0 0 1 1 0 0 0 0 1 0 0 0 0
                            1 1 1 0 0 1 1 0 0 0 1 0 1 0
                            1 1 1 0 0 1 1 0 0 0 1 0 0 0
                            1 0 0 1 1 0 0 0 0 0 0 1 0 0
                            1 0 0 1 1 0 0 0 0 0 0 1 0 1
                            0 0 0 0 0 0 0 0 0 0 0 0 0 0
                            0 0 0 0 0 0 0 0 0 0 0 0 0 0]

        var_id = CPRL.branchingvariable_id(array)

        @test var_id == 3

    end

    @testset "possible_value_ids()" begin
        array = Float32[1 0 0 1 1 0 0 0 0 1 0 0 0 1
                        1 0 0 1 1 0 0 0 0 1 0 0 0 0
                        1 1 1 0 0 1 1 0 0 0 1 0 1 0
                        1 1 1 0 0 1 1 0 0 0 1 0 0 0
                        1 0 0 1 1 0 0 0 0 0 0 1 0 0
                        1 0 0 1 1 0 0 0 0 0 0 1 0 1
                        0 0 0 0 0 0 0 0 0 0 0 0 0 0
                        0 0 0 0 0 0 0 0 0 0 0 0 0 0]
        @test CPRL.possible_value_ids(array) == [1, 6]
    end

    @testset "to_arraybuffer()" begin

        trailer = CPRL.Trailer()
        model = CPRL.CPModel(trailer)

        x = CPRL.IntVar(2, 3, "x", trailer)
        y = CPRL.IntVar(2, 3, "y", trailer)
        CPRL.addVariable!(model, x)
        CPRL.addVariable!(model, y)
        push!(model.constraints, CPRL.Equal(x, y, trailer))
        push!(model.constraints, CPRL.NotEqual(x, y, trailer))

        dsr = CPRL.DefaultStateRepresentation(model)
        CPRL.update_representation!(dsr, model, x)

        max_cpnodes = 8

        @test CPRL.to_arraybuffer(dsr, max_cpnodes) == Float32[   1 0 0 1 1 0 0 0 0 1 0 0 0 0
                                                            1 0 0 1 1 0 0 0 0 1 0 0 0 0
                                                            1 1 1 0 0 1 1 0 0 0 1 0 1 0
                                                            1 1 1 0 0 1 1 0 0 0 1 0 0 0
                                                            1 0 0 1 1 0 0 0 0 0 0 1 0 1
                                                            1 0 0 1 1 0 0 0 0 0 0 1 0 1
                                                            0 0 0 0 0 0 0 0 0 0 0 0 0 0
                                                            0 0 0 0 0 0 0 0 0 0 0 0 0 0]

    end

    @testset "possible_values()" begin
        trailer = CPRL.Trailer()
        model = CPRL.CPModel(trailer)

        x = CPRL.IntVar(2, 3, "x", trailer)
        y = CPRL.IntVar(3, 3, "y", trailer)
        CPRL.addVariable!(model, x)
        CPRL.addVariable!(model, y)
        push!(model.constraints, CPRL.Equal(x, y, trailer))
        push!(model.constraints, CPRL.NotEqual(x, y, trailer))

        g = CPRL.CPLayerGraph(model)


        @test CPRL.possible_values(CPRL.indexFromCpVertex(g, CPRL.VariableVertex(y)), g) == [6]
        @test CPRL.possible_values(CPRL.indexFromCpVertex(g, CPRL.VariableVertex(x)), g) == [5, 6]
    end

end
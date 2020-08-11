adj = [0 1 0 1;
       1 0 1 0;
       0 1 0 1;
       1 0 1 0]

@testset "defaultstaterepresentation.jl" begin
    
    @testset "DefaultStateRepresentation structure" begin
        g = SeaPearl.CPLayerGraph()
        features = [1.0f0 1.0f0; 2.0f0 2.0f0]
        variable_id = 1
        dsr = SeaPearl.DefaultStateRepresentation{SeaPearl.DefaultFeaturization}(g, features, variable_id, [1, 2, 3])

        @test dsr.cplayergraph == g
        @test dsr.features == features
        @test dsr.variable_id == 1
        @test dsr.possible_value_ids == [1, 2, 3]

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
        @test dsr.variable_id == 3
        @test dsr.possible_value_ids == [6]
        @test SeaPearl.cpVertexFromIndex(SeaPearl.CPLayerGraph(model), dsr.variable_id).variable == model.variables["x"]
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

        @test dsr.variable_id == 3
        @test dsr.possible_value_ids == [5, 6]
        @test SeaPearl.cpVertexFromIndex(SeaPearl.CPLayerGraph(model), dsr.variable_id).variable == model.variables["x"]

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
        @test dsr.variable_id == 4
        @test dsr.possible_value_ids == [5]
        @test SeaPearl.cpVertexFromIndex(g, dsr.variable_id).variable == model.variables["y"]

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

        fg = SeaPearl.featuredgraph(array, SeaPearl.DefaultStateRepresentation)

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

        var_id = SeaPearl.branchingvariable_id(array, SeaPearl.DefaultStateRepresentation)

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
        @test SeaPearl.possible_value_ids(array, SeaPearl.DefaultStateRepresentation) == [1, 6]
    end

    @testset "to_arraybuffer()" begin

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

        max_cpnodes = 8

        @test SeaPearl.to_arraybuffer(dsr, max_cpnodes) == Float32[   1 0 0 1 1 0 0 0 0 1 0 0 0 0
                                                            1 0 0 1 1 0 0 0 0 1 0 0 0 0
                                                            1 1 1 0 0 1 1 0 0 0 1 0 1 0
                                                            1 1 1 0 0 1 1 0 0 0 1 0 0 0
                                                            1 0 0 1 1 0 0 0 0 0 0 1 0 1
                                                            1 0 0 1 1 0 0 0 0 0 0 1 0 1
                                                            0 0 0 0 0 0 0 0 0 0 0 0 0 0
                                                            0 0 0 0 0 0 0 0 0 0 0 0 0 0]

    end

    @testset "possible_values()" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        x = SeaPearl.IntVar(2, 3, "x", trailer)
        y = SeaPearl.IntVar(3, 3, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        push!(model.constraints, SeaPearl.Equal(x, y, trailer))
        push!(model.constraints, SeaPearl.NotEqual(x, y, trailer))

        g = SeaPearl.CPLayerGraph(model)


        @test SeaPearl.possible_values(SeaPearl.indexFromCpVertex(g, SeaPearl.VariableVertex(y)), g) == [6]
        @test SeaPearl.possible_values(SeaPearl.indexFromCpVertex(g, SeaPearl.VariableVertex(x)), g) == [5, 6]
    end

end
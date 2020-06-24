adj = [0 1 0 1;
       1 0 1 0;
       0 1 0 1;
       1 0 1 0]

@testset "cpgraph_space.jl" begin

    @testset "CPGraph structure" begin
        fg = GeometricFlux.FeaturedGraph(adj, nothing)
        variable_id = 1
        cpg = CPRL.CPGraph(fg, variable_id)

        @test cpg.featuredgraph == fg
        @test cpg.variable_id == 1

    end

    @testset "CPGraph from CPLayerGraph" begin
        trailer = CPRL.Trailer()
        model = CPRL.CPModel(trailer)

        x = CPRL.IntVar(2, 3, "x", trailer)
        y = CPRL.IntVar(2, 3, "y", trailer)
        CPRL.addVariable!(model, x)
        CPRL.addVariable!(model, y)
        push!(model.constraints, CPRL.Equal(x, y, trailer))
        push!(model.constraints, CPRL.NotEqual(x, y, trailer))

        g = CPRL.CPLayerGraph(model)

        cpg = CPRL.CPGraph(g, x)

        @test Matrix(cpg.featuredgraph.graph[]) == [0 0 1 1 0 0
                                                    0 0 1 1 0 0
                                                    1 1 0 0 1 1
                                                    1 1 0 0 1 1
                                                    0 0 1 1 0 0
                                                    0 0 1 1 0 0]

        @test cpg.featuredgraph.feature[] == [1.0 0 0 0 0 0
                                              0 1.0 0 0 0 0
                                              0 0 1.0 0 0 0
                                              0 0 0 1.0 0 0
                                              0 0 0 0 1.0 0
                                              0 0 0 0 0 1.0]
        @test cpg.variable_id == 3
        @test CPRL.cpVertexFromIndex(g, cpg.variable_id).variable == model.variables["x"]
    end

    @testset "update_graph!()" begin
        trailer = CPRL.Trailer()
        model = CPRL.CPModel(trailer)

        x = CPRL.IntVar(2, 3, "x", trailer)
        y = CPRL.IntVar(2, 3, "y", trailer)
        CPRL.addVariable!(model, x)
        CPRL.addVariable!(model, y)
        push!(model.constraints, CPRL.Equal(x, y, trailer))
        push!(model.constraints, CPRL.NotEqual(x, y, trailer))

        g = CPRL.CPLayerGraph(model)

        cpg = CPRL.CPGraph(g, x)

        @test Matrix(cpg.featuredgraph.graph[]) == [0 0 1 1 0 0
                                                    0 0 1 1 0 0
                                                    1 1 0 0 1 1
                                                    1 1 0 0 1 1
                                                    0 0 1 1 0 0
                                                    0 0 1 1 0 0]

        @test cpg.featuredgraph.feature[] == [1.0 0 0 0 0 0
                                              0 1.0 0 0 0 0
                                              0 0 1.0 0 0 0
                                              0 0 0 1.0 0 0
                                              0 0 0 0 1.0 0
                                              0 0 0 0 0 1.0]
        @test cpg.variable_id == 3
        @test CPRL.cpVertexFromIndex(g, cpg.variable_id).variable == model.variables["x"]

        CPRL.assign!(x, 2)
        g = CPRL.CPLayerGraph(model)

        CPRL.update_graph!(cpg, g, y)

        @test Matrix(cpg.featuredgraph.graph[]) == [0 0 1 1 0 0
                                                    0 0 1 1 0 0
                                                    1 1 0 0 1 0
                                                    1 1 0 0 1 1
                                                    0 0 1 1 0 0
                                                    0 0 0 1 0 0]

        @test cpg.featuredgraph.feature[] == [1.0 0 0 0 0 0
                                              0 1.0 0 0 0 0
                                              0 0 1.0 0 0 0
                                              0 0 0 1.0 0 0
                                              0 0 0 0 1.0 0
                                              0 0 0 0 0 1.0f0]
        @test cpg.variable_id == 4
        @test CPRL.cpVertexFromIndex(g, cpg.variable_id).variable == model.variables["y"]

    end

    @testset "CPGraph() from array" begin

        array = [0 0 1 1 0 0 1f0 0 0 0 0 0 0
                 0 0 1 1 0 0 0 1f0 0 0 0 0 0
                 1 1 0 0 1 1 0 0 1f0 0 0 0 1.0f0
                 1 1 0 0 1 1 0 0 0 1f0 0 0 0
                 0 0 1 1 0 0 0 0 0 0 1f0 0 0
                 0 0 1 1 0 0 0 0 0 0 0 1f0 0]

        cpg = CPRL.CPGraph(array)

        @test Matrix(cpg.featuredgraph.graph[]) == [0 0 1 1 0 0
                                                    0 0 1 1 0 0
                                                    1 1 0 0 1 1
                                                    1 1 0 0 1 1
                                                    0 0 1 1 0 0
                                                    0 0 1 1 0 0]

        @test cpg.featuredgraph.feature[] == [1.0 0 0 0 0 0
                                              0 1.0 0 0 0 0
                                              0 0 1.0 0 0 0
                                              0 0 0 1.0 0 0
                                              0 0 0 0 1.0 0
                                              0 0 0 0 0 1.0f0]
        @test cpg.variable_id == 3

    end

    @testset "to_cpgraph()" begin

        trailer = CPRL.Trailer()
        model = CPRL.CPModel(trailer)

        x = CPRL.IntVar(2, 3, "x", trailer)
        y = CPRL.IntVar(2, 3, "y", trailer)
        CPRL.addVariable!(model, x)
        CPRL.addVariable!(model, y)
        push!(model.constraints, CPRL.Equal(x, y, trailer))
        push!(model.constraints, CPRL.NotEqual(x, y, trailer))

        g = CPRL.CPLayerGraph(model)

        cpg = CPRL.CPGraph(g, x)

        @test CPRL.to_array(cpg) == [0 0 1 1 0 0 1.0 0 0 0 0 0 0
                                     0 0 1 1 0 0 0 1.0 0 0 0 0 0
                                     1 1 0 0 1 1 0 0 1.0 0 0 0 1.0f0
                                     1 1 0 0 1 1 0 0 0 1.0 0 0 0
                                     0 0 1 1 0 0 0 0 0 0 1.0 0 0
                                     0 0 1 1 0 0 0 0 0 0 0 1.0 0]

    end
    

end
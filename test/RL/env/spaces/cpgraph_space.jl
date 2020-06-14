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
    end

end
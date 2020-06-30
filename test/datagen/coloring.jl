@testset "coloring.jl" begin
    @testset "fill_with_coloring!" begin
        trailer = CPRL.Trailer()
        model = CPRL.CPModel(trailer)

        nb_nodes = 10
        density = 1.5

        for _ in 1:20
            CPRL.fill_with_coloring!(model, nb_nodes, density)

            @test length(keys(model.variables)) == nb_nodes + 1
            @test length(model.constraints) == floor(Int64, density * nb_nodes) + nb_nodes
            empty!(model)
        end
    end
    @testset "fill_with_coloring! with array" begin
        trailer = CPRL.Trailer()
        model = CPRL.CPModel(trailer)
        trailer2 = CPRL.Trailer()
        model2 = CPRL.CPModel(trailer2)

        models = CPRL.CPModel[model, model2]

        nb_nodes = 10
        density = 1.5

        for _ in 1:3
            CPRL.fill_with_coloring!(models, nb_nodes, density)

            @test length(keys(model.variables)) == nb_nodes + 1
            @test length(model.constraints) == floor(Int64, density * nb_nodes) + nb_nodes
            empty!(model)
            @test length(keys(model2.variables)) == nb_nodes + 1
            @test length(model2.constraints) == floor(Int64, density * nb_nodes) + nb_nodes
            empty!(model2)
        end
    end

end
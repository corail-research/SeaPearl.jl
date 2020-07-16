@testset "coloring.jl" begin
    @testset "fill_with_coloring!" begin
        trailer = CPRL.Trailer()
        model = CPRL.CPModel(trailer)

        nb_nodes = 10
        density = 1.5

        generator = CPRL.GraphColoringGenerator(nb_nodes, density)

        for _ in 1:20
            CPRL.fill_with_generator!(model, generator)

            @test length(keys(model.variables)) == nb_nodes + 1
            @test length(model.constraints) == floor(Int64, density * nb_nodes) + nb_nodes
            empty!(model)
        end
    end

end
@testset "coloring.jl" begin
    @testset "fill_with_coloring!" begin
        trailer = CPRL.Trailer()
        model = CPRL.CPModel(trailer)

        nb_nodes = 10
        density = 1.5
        CPRL.fill_with_coloring!(model, nb_nodes, density)

        @test length(keys(model.variables)) == nb_nodes + 1
        @test length(model.constraints) == floor(Int64, density * nb_nodes) + nb_nodes
    end

end
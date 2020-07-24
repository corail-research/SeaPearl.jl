using Random

@testset "coloring.jl" begin
    @testset "fill_with_coloring!" begin
        trailer = CPRL.Trailer()
        model = CPRL.CPModel(trailer)

        nb_nodes = 10
        probability = 0.5

        generator = CPRL.GraphColoringGenerator(nb_nodes, probability)

        
        CPRL.fill_with_generator!(model, generator;rng=MersenneTwister(12))

        @test length(keys(model.variables)) == nb_nodes + 1
        @test length(model.constraints) == 55
            
        
    end

end
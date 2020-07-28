using Random

@testset "coloring.jl" begin
    @testset "fill_with_generator!(::LegacyGraphColoringGenerator)" begin
        trailer = CPRL.Trailer()
        model = CPRL.CPModel(trailer)

        nb_nodes = 10
        probability = 1.4

        generator = CPRL.LegacyGraphColoringGenerator(nb_nodes, probability)

        
        CPRL.fill_with_generator!(model, generator)

        @test length(keys(model.variables)) == nb_nodes + 1
        @test length(model.constraints) == 24
            
        
    end

    
    @testset "fill_with_generator!(::HomogenousGraphColoringGenerator)" begin
        trailer = CPRL.Trailer()
        model = CPRL.CPModel(trailer)

        nb_nodes = 10
        probability = 0.5

        generator = CPRL.HomogenousGraphColoringGenerator(nb_nodes, probability)

        
        CPRL.fill_with_generator!(model, generator; rng=MersenneTwister(12))

        @test length(keys(model.variables)) == nb_nodes + 1
        @test length(model.constraints) == 55
            
        
    end

    

    
    @testset "fill_with_generator!(::ClusterizedGraphColoringGenerator)" begin
        trailer = CPRL.Trailer()
        model = CPRL.CPModel(trailer)

        nb_nodes = 10
        k = 3
        probability = 0.5

        generator = CPRL.ClusterizedGraphColoringGenerator(nb_nodes, k, probability)

        
        CPRL.fill_with_generator!(model, generator; rng=MersenneTwister(12))

        @test length(keys(model.variables)) == nb_nodes + 1
        @test length(model.constraints) == 37
            
        
    end

end
@testset "coloring.jl" begin
    @testset "fill_with_generator!(::LegacyGraphColoringGenerator)" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        nb_nodes = 10
        probability = 1.4

        generator = SeaPearl.LegacyGraphColoringGenerator(nb_nodes, probability)

        rng = MersenneTwister()
        Random.seed!(rng, 12)
        SeaPearl.fill_with_generator!(model, generator; rng = rng)

        @test length(keys(model.variables)) == nb_nodes + 1
        @test length(model.constraints) == 23 || length(model.constraints) == 22
        

        model1 = SeaPearl.CPModel(trailer)
        model2 = SeaPearl.CPModel(trailer)
        model3 = SeaPearl.CPModel(trailer)

        rng = MersenneTwister(11)
        SeaPearl.fill_with_generator!(model1, generator; rng = rng)

        rng = MersenneTwister(11)
        SeaPearl.fill_with_generator!(model2, generator; rng = rng)
        
        rng = MersenneTwister(14)
        SeaPearl.fill_with_generator!(model3, generator; rng = rng)

        for i in 1:22
            @test model1.constraints[i].y.id == model2.constraints[i].y.id
            @test model1.constraints[i].x.id == model2.constraints[i].x.id
        end
        @test model1.constraints[1].y.id != model3.constraints[1].y.id


    end

    
    @testset "fill_with_generator!(::HomogenousGraphColoringGenerator)" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        nb_nodes = 10
        probability = 0.5

        generator = SeaPearl.HomogenousGraphColoringGenerator(nb_nodes, probability)

        rng = MersenneTwister()
        Random.seed!(rng, 42)
        SeaPearl.fill_with_generator!(model, generator; rng = rng)

        @test length(keys(model.variables)) == nb_nodes + 1

        if VERSION == v"1.6.0"
            @test length(model.constraints) == 55
        elseif VERSION >= v"1.7.0"
            @test length(model.constraints) == 35
        end
        
        model1 = SeaPearl.CPModel(trailer)
        model2 = SeaPearl.CPModel(trailer)
        model3 = SeaPearl.CPModel(trailer)

        rng = MersenneTwister(11)
        SeaPearl.fill_with_generator!(model1, generator; rng = rng)

        rng = MersenneTwister(11)
        SeaPearl.fill_with_generator!(model2, generator; rng = rng)
        
        rng = MersenneTwister(14)
        SeaPearl.fill_with_generator!(model3, generator; rng = rng)

        @test length(model1.constraints) == length(model2.constraints)   
        @test length(model1.constraints) != length(model3.constraints)   

    end
    
    @testset "fill_with_generator!(::ClusterizedGraphColoringGenerator)" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        nb_nodes = 10
        k = 3
        probability = 0.5

        generator = SeaPearl.ClusterizedGraphColoringGenerator(nb_nodes, k, probability)

        rng = MersenneTwister()
        Random.seed!(rng, 12)
        SeaPearl.fill_with_generator!(model, generator; rng = rng)

        @test length(keys(model.variables)) == nb_nodes + 1

        # This condition is there because of the way random are generated can change from one version to another
        if VERSION >= v"1.6.0"
            @test length(model.constraints) == 24
        end
            
        model1 = SeaPearl.CPModel(trailer)
        model2 = SeaPearl.CPModel(trailer)
        model3 = SeaPearl.CPModel(trailer)

        rng = MersenneTwister(11)
        SeaPearl.fill_with_generator!(model1, generator; rng = rng)

        rng = MersenneTwister(11)
        SeaPearl.fill_with_generator!(model2, generator; rng = rng)
        
        rng = MersenneTwister(14)
        SeaPearl.fill_with_generator!(model3, generator; rng = rng)

        @test  model1.constraints[2].y.id ==  model2.constraints[2].y.id
        @test  model1.constraints[2].y.id !=  model3.constraints[2].y.id

    end

end
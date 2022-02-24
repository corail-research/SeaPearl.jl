@testset "knapsack.jl" begin
    @testset "fill_with_knapsack!" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        nb_items = 10
        max_weight = 40
        correlation = 2.3

        generator = SeaPearl.KnapsackGenerator(nb_items, max_weight, correlation)

        for _ in 1:3
            SeaPearl.fill_with_generator!(model, generator)

            @test length(keys(model.variables)) == nb_items + 3
            @test length(model.constraints) == 3
            empty!(model)
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

        @test model1.constraints[2].v == model2.constraints[2].v  
        @test model1.constraints[2].v != model3.constraints[2].v

    end

end
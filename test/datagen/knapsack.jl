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
    end

end
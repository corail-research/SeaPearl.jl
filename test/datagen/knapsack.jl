@testset "knapsack.jl" begin
    @testset "fill_with_knapsack!" begin
        trailer = CPRL.Trailer()
        model = CPRL.CPModel(trailer)

        nb_items = 10
        max_weight = 40
        correlation = 2

        for _ in 1:20
            CPRL.fill_with_knapsack!(model, nb_items, max_weight, correlation)

            @test length(keys(model.variables)) == nb_items + 3
            @test length(model.constraints) == 3
            empty!(model)
        end
    end
    @testset "fill_with_knapsack! with array" begin
        trailer = CPRL.Trailer()
        model = CPRL.CPModel(trailer)
        trailer2 = CPRL.Trailer()
        model2 = CPRL.CPModel(trailer2)

        models = CPRL.CPModel[model, model2]

        nb_items = 10
        max_weight = 45
        correlation = 2

        for _ in 1:3
            CPRL.fill_with_knapsack!(models, nb_items, max_weight, correlation)

            @test length(keys(model.variables)) == nb_items + 3
            @test length(model.constraints) == 3
            empty!(model)
            @test length(keys(model2.variables)) == nb_items + 3
            @test length(model2.constraints) == 3
            empty!(model2)
        end
    end

end
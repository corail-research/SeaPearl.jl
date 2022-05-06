@testset "eternity2.jl" begin
    @testset "fill_with_generator!" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        n=6

        generator = SeaPearl.Eternity2Generator(6,6,6)

        for _ in 1:3
            SeaPearl.fill_with_generator!(model, generator)
            @test length(model.variables) == 120
            @test length(model.constraints) == 61
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

        @test model1.constraints[1].table == model2.constraints[1].table   
        @test model1.constraints[1].table != model3.constraints[1].table  

    end
end

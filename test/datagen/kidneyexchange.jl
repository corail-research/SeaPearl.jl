@testset "kidneyexchange.jl" begin
    @testset "fill_with_generator!(::KepGenerator)" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        num_nodes = 4
        density = 0.5
        generator = SeaPearl.KepGenerator(num_nodes, density)

        SeaPearl.fill_with_generator!(model, generator)
        @test length(model.variables) == 17
        @test length(model.constraints) == 13

        model1 = SeaPearl.CPModel(trailer)
        model2 = SeaPearl.CPModel(trailer)
        model3 = SeaPearl.CPModel(trailer)

        rng = MersenneTwister(11)
        SeaPearl.fill_with_generator!(model1, generator; rng=rng)

        rng = MersenneTwister(11)
        SeaPearl.fill_with_generator!(model2, generator; rng=rng)

        rng = MersenneTwister(14)
        SeaPearl.fill_with_generator!(model3, generator; rng=rng)

        @test model1.constraints[1].upper == model2.constraints[1].upper
        @test model1.constraints[1].x[1].id == model2.constraints[1].x[1].id
        @test model1.constraints[1].x[1].id == model3.constraints[1].x[1].id
    end
end
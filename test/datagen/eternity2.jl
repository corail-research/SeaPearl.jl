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
    end
end

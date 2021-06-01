@testset "nqueens.jl" begin
    @testset "fill_with_generator!" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        n=8

        generator = SeaPearl.NQueensGenerator(n)

        for _ in 1:3
            SeaPearl.fill_with_generator!(model, generator)

            @test length(keys(model.variables)) == n
            @test length(model.constraints) == 3
            empty!(model)
        end
    end
end

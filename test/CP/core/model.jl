@testset "model.jl" begin
    @testset "addVariable!()" begin
        trailer = CPRL.Trailer()
        x = CPRL.IntVar(2, 6, "x", trailer)
        y = CPRL.IntVar(2, 6, "y", trailer)

        model = CPRL.CPModel()

        CPRL.addVariable!(model, x)
        CPRL.addVariable!(model, y)

        @test length(model.variables) == 2

        z = CPRL.IntVar(2, 6, "y", trailer)

        @test_throws AssertionError CPRL.addVariable!(model, z)
    end
end
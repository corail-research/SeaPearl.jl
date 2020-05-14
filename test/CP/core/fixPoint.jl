using CPRL

@testset "fixPoint.jl" begin
    @testset "fixPoint!()" begin
        trailer = CPRL.Trailer()
        x = CPRL.IntVar(2, 6, trailer)
        y = CPRL.IntVar(5, 8, trailer)
        z = CPRL.IntVar(6, 15, trailer)

        constraint = CPRL.Equal(x, y)
        constraint2 = CPRL.Equal(y, z)

        model = CPRL.CPModel()

        push!(model.variables, x)
        push!(model.variables, y)
        push!(model.variables, z)

        push!(model.constraints, constraint)
        push!(model.constraints, constraint2)

        CPRL.fixPoint!(model)

        @test CPRL.isbound(x)
        @test CPRL.isbound(y)
        @test CPRL.isbound(z)
    end
end
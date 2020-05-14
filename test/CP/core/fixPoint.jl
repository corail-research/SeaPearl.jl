using CPRL

@testset "fixPoint.jl" begin
    @testset "fixPoint!()" begin
        trailer = CPRL.Trailer()
        x = CPRL.IntVar(2, 6, trailer)
        y = CPRL.IntVar(5, 8, trailer)
        z = CPRL.IntVar(6, 15, trailer)
        t = CPRL.IntVar(6, 10, trailer)

        constraint = CPRL.Equal(x, y)
        
        constraint3 = CPRL.Equal(z, t)

        model = CPRL.CPModel()

        push!(model.variables, x)
        push!(model.variables, y)
        push!(model.variables, z)
        push!(model.variables, t)

        push!(model.constraints, constraint)
        push!(model.constraints, constraint3)
        CPRL.fixPoint!(model)

        @test length(x.domain) == 2
        @test length(y.domain) == 2
        @test length(z.domain) == 5
        @test length(t.domain) == 5

        constraint2 = CPRL.Equal(y, z)
        push!(model.constraints, constraint2)

        CPRL.fixPoint!(model, [constraint2])

        @test CPRL.isbound(x)
        @test CPRL.isbound(y)
        @test CPRL.isbound(z)
        @test CPRL.isbound(t)
    end
end
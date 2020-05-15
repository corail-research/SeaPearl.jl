using CPRL

@testset "fixPoint.jl" begin
    @testset "fixPoint!()" begin
        trailer = CPRL.Trailer()
        x = CPRL.IntVar(2, 6, "x", trailer)
        y = CPRL.IntVar(5, 8, "y", trailer)
        z = CPRL.IntVar(6, 15, "z", trailer)
        t = CPRL.IntVar(6, 10, "t", trailer)
        u = CPRL.IntVar(10, 25, "u", trailer)

        constraint = CPRL.Equal(x, y, trailer)
        
        constraint3 = CPRL.Equal(z, t, trailer)

        model = CPRL.CPModel(trailer)

        CPRL.addVariable!(model, x)
        CPRL.addVariable!(model, y)
        CPRL.addVariable!(model, z)
        CPRL.addVariable!(model, t)
        CPRL.addVariable!(model, u)

        push!(model.constraints, constraint)
        push!(model.constraints, constraint3)
        feasability, prunedDomains = CPRL.fixPoint!(model)
        
        rightPruning = CPRL.CPModification("x" => [2, 3, 4],"z" => [11, 12, 13, 14, 15],"y" => [7, 8])

        @test prunedDomains == rightPruning
        @test feasability

        @test length(x.domain) == 2
        @test length(y.domain) == 2
        @test length(z.domain) == 5
        @test length(t.domain) == 5

        constraint2 = CPRL.Equal(y, z, trailer)
        push!(model.constraints, constraint2)

        CPRL.fixPoint!(model, [constraint2])


        @test CPRL.isbound(x)
        @test CPRL.isbound(y)
        @test CPRL.isbound(z)
        @test CPRL.isbound(t)

        constraint4 = CPRL.Equal(u, z, trailer)
        push!(model.constraints, constraint4)

        feasability2, pruned = CPRL.fixPoint!(model, [constraint4])
        @test !feasability2
    end
end
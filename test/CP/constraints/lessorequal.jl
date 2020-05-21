using CPRL

@testset "lessorqual.jl" begin
    @testset "LessOrEqualConstant()" begin
        trailer = CPRL.Trailer()
        x = CPRL.IntVar(2, 6, "x", trailer)

        constraint = CPRL.LessOrEqualConstant(x, 3, trailer)

        @test constraint in x.onDomainChange
        @test constraint.active.value
    end
    @testset "propagate!(::LessOrEqualConstant)" begin
        trailer = CPRL.Trailer()
        x = CPRL.IntVar(2, 6, "x", trailer)

        constraint = CPRL.LessOrEqualConstant(x, 3, trailer)

        toPropagate = Set{CPRL.Constraint}()
        prunedDomains = CPRL.CPModification()

        @test CPRL.propagate!(constraint, toPropagate, prunedDomains)

        @test length(x.domain) == 2
        @test 2 in x.domain
        @test !(4 in x.domain)
        @test prunedDomains == CPRL.CPModification("x" => [4, 5, 6])

        y = CPRL.IntVar(2, 2, "y", trailer)

        cons2 = CPRL.LessOrEqualConstant(y, 1, trailer)

        @test !CPRL.propagate!(cons2, toPropagate, prunedDomains)

        @test isempty(y.domain)

    end
    @testset "LessOrEqual()" begin
        trailer = CPRL.Trailer()
        x = CPRL.IntVar(2, 6, "x", trailer)
        y = CPRL.IntVar(2, 6, "y", trailer)

        constraint = CPRL.LessOrEqual(x, y, trailer)

        @test constraint in x.onDomainChange
        @test constraint in y.onDomainChange
        @test constraint.active.value
    end
    @testset "propagate!(::LessOrEqual)" begin
        trailer = CPRL.Trailer()
        x = CPRL.IntVar(2, 6, "x", trailer)
        y = CPRL.IntVar(2, 3, "y", trailer)

        constraint = CPRL.LessOrEqual(x, y, trailer)

        toPropagate = Set{CPRL.Constraint}()
        prunedDomains = CPRL.CPModification()

        @test CPRL.propagate!(constraint, toPropagate, prunedDomains)

        @test length(x.domain) == 2
        @test !(5 in x.domain)
        @test 3 in x.domain
        @test prunedDomains == CPRL.CPModification("x" => [4, 5, 6])

        z = CPRL.IntVar(1, 1, "z", trailer)
        constraint2 = CPRL.LessOrEqual(x, z, trailer)


        @test !CPRL.propagate!(constraint2, toPropagate, prunedDomains)

    end
end

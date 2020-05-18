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
end

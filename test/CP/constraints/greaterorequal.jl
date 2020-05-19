using CPRL

@testset "greaterorqual.jl" begin
    @testset "GreaterOrEqualConstant()" begin
        trailer = CPRL.Trailer()
        x = CPRL.IntVar(2, 6, "x", trailer)

        constraint = CPRL.GreaterOrEqualConstant(x, 3, trailer)

        @test constraint in x.onDomainChange
        @test constraint.active.value
    end
    @testset "propagate!(::GreaterOrEqualConstant)" begin
        trailer = CPRL.Trailer()
        x = CPRL.IntVar(2, 6, "x", trailer)

        constraint = CPRL.GreaterOrEqualConstant(x, 5, trailer)

        toPropagate = Set{CPRL.Constraint}()
        prunedDomains = CPRL.CPModification()

        @test CPRL.propagate!(constraint, toPropagate, prunedDomains)

        @test length(x.domain) == 2
        @test 5 in x.domain
        @test !(4 in x.domain)
        @test prunedDomains == CPRL.CPModification("x" => [2, 3, 4])

        y = CPRL.IntVar(2, 2, "y", trailer)

        cons2 = CPRL.GreaterOrEqualConstant(y, 3, trailer)

        @test !CPRL.propagate!(cons2, toPropagate, prunedDomains)

        @test isempty(y.domain)

    end
end

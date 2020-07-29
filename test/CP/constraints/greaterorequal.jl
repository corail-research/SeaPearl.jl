using SeaPearl

@testset "greaterorqual.jl" begin
    @testset "GreaterOrEqualConstant()" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(2, 6, "x", trailer)

        constraint = SeaPearl.GreaterOrEqualConstant(x, 3, trailer)

        @test constraint in x.onDomainChange
        @test constraint.active.value
    end
    @testset "propagate!(::GreaterOrEqualConstant)" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(2, 6, "x", trailer)

        constraint = SeaPearl.GreaterOrEqualConstant(x, 5, trailer)

        toPropagate = Set{SeaPearl.Constraint}()
        prunedDomains = SeaPearl.CPModification()

        @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)

        @test length(x.domain) == 2
        @test 5 in x.domain
        @test !(4 in x.domain)
        @test prunedDomains == SeaPearl.CPModification("x" => [2, 3, 4])

        y = SeaPearl.IntVar(2, 2, "y", trailer)

        cons2 = SeaPearl.GreaterOrEqualConstant(y, 3, trailer)

        @test !SeaPearl.propagate!(cons2, toPropagate, prunedDomains)

        @test isempty(y.domain)

    end
end

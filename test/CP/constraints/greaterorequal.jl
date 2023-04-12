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
    @testset "GreaterOrEqual()" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(2, 6, "x", trailer)
        y = SeaPearl.IntVar(2, 6, "y", trailer)

        constraint = SeaPearl.GreaterOrEqual(x, y, trailer)

        @test constraint in x.onDomainChange
        @test constraint in y.onDomainChange
        @test constraint.active.value
    end
    @testset "propagate!(::GreaterOrEqual)" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(2, 4, "x", trailer)
        y = SeaPearl.IntVar(3, 6, "y", trailer)

        constraint = SeaPearl.GreaterOrEqual(x, y, trailer)

        toPropagate = Set{SeaPearl.Constraint}()
        prunedDomains = SeaPearl.CPModification()

        @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)

        @test length(y.domain) == 2
        @test !(2 in y.domain)
        @test 3 in y.domain
        @test prunedDomains == SeaPearl.CPModification("y" => [5, 6], "x" => [2])

        z = SeaPearl.IntVar(1, 1, "z", trailer)
        constraint2 = SeaPearl.GreaterOrEqual(z, y, trailer)
        @test !SeaPearl.propagate!(constraint2, toPropagate, prunedDomains)
    end
    @testset "Greater()" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(2, 6, "x", trailer)
        y = SeaPearl.IntVar(2, 6, "y", trailer)

        constraint = SeaPearl.Greater(x, y, trailer)

        @test constraint in x.onDomainChange
        @test constraint in y.onDomainChange
        @test constraint.active.value
    end
    @testset "propagate!(::Greater)" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(2, 5, "x", trailer)
        y = SeaPearl.IntVar(2, 6, "y", trailer)

        constraint = SeaPearl.Greater(x, y, trailer)

        toPropagate = Set{SeaPearl.Constraint}()
        prunedDomains = SeaPearl.CPModification()

        @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)

        @test length(y.domain) == 3
        @test !(2 in x.domain)
        @test 3 in y.domain
        @test prunedDomains == SeaPearl.CPModification("y" => [5, 6], "x" => [2])

        z = SeaPearl.IntVar(2, 2, "z", trailer)
        constraint2 = SeaPearl.Greater(z, y, trailer)
        @test !SeaPearl.propagate!(constraint2, toPropagate, prunedDomains)
    end
end


@testset "lessorqual.jl" begin
    @testset "LessOrEqualConstant()" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(2, 6, "x", trailer)

        constraint = SeaPearl.LessOrEqualConstant(x, 3, trailer)

        @test constraint in x.onDomainChange
        @test constraint.active.value
    end
    @testset "propagate!(::LessOrEqualConstant)" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(2, 6, "x", trailer)

        constraint = SeaPearl.LessOrEqualConstant(x, 3, trailer)

        toPropagate = Set{SeaPearl.Constraint}()
        prunedDomains = SeaPearl.CPModification()

        @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)

        @test length(x.domain) == 2
        @test 2 in x.domain
        @test !(4 in x.domain)
        @test prunedDomains == SeaPearl.CPModification("x" => [4, 5, 6])

        y = SeaPearl.IntVar(2, 2, "y", trailer)

        cons2 = SeaPearl.LessOrEqualConstant(y, 1, trailer)

        @test !SeaPearl.propagate!(cons2, toPropagate, prunedDomains)

        @test isempty(y.domain)

    end
    @testset "LessOrEqual()" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(2, 6, "x", trailer)
        y = SeaPearl.IntVar(2, 6, "y", trailer)

        constraint = SeaPearl.LessOrEqual(x, y, trailer)

        @test constraint in x.onDomainChange
        @test constraint in y.onDomainChange
        @test constraint.active.value
    end
    @testset "propagate!(::LessOrEqual)" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(2, 6, "x", trailer)
        y = SeaPearl.IntVar(2, 3, "y", trailer)

        constraint = SeaPearl.LessOrEqual(x, y, trailer)

        toPropagate = Set{SeaPearl.Constraint}()
        prunedDomains = SeaPearl.CPModification()

        @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)

        @test length(x.domain) == 2
        @test !(5 in x.domain)
        @test 3 in x.domain
        @test prunedDomains == SeaPearl.CPModification("x" => [4, 5, 6])

        z = SeaPearl.IntVar(1, 1, "z", trailer)
        constraint2 = SeaPearl.LessOrEqual(x, z, trailer)

        @test !SeaPearl.propagate!(constraint2, toPropagate, prunedDomains)

    end
    @testset "Less()" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(2, 6, "x", trailer)
        y = SeaPearl.IntVar(2, 6, "y", trailer)

        constraint = SeaPearl.Less(x, y, trailer)

        @test constraint in x.onDomainChange
        @test constraint in y.onDomainChange
        @test constraint.active.value
    end
    @testset "propagate!(::Less)" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(2, 6, "x", trailer)
        y = SeaPearl.IntVar(2, 5, "y", trailer)

        constraint = SeaPearl.Less(x, y, trailer)

        toPropagate = Set{SeaPearl.Constraint}()
        prunedDomains = SeaPearl.CPModification()

        @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)

        @test length(x.domain) == 3
        @test !(5 in x.domain)
        @test 3 in x.domain
        @test prunedDomains == SeaPearl.CPModification("x" => [5, 6], "y" => [2])

        z = SeaPearl.IntVar(2, 2, "z", trailer)
        constraint2 = SeaPearl.Less(x, z, trailer)

        @test !SeaPearl.propagate!(constraint2, toPropagate, prunedDomains)

    end

    @testset "LessConstant()" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(2, 6, "x", trailer)

        constraint = SeaPearl.LessConstant(x, 4, trailer)

        @test constraint in x.onDomainChange
        @test constraint.active.value
    end
    @testset "propagate!(::LessOrEqualConstant)" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(2, 6, "x", trailer)

        constraint = SeaPearl.LessConstant(x, 4, trailer)

        toPropagate = Set{SeaPearl.Constraint}()
        prunedDomains = SeaPearl.CPModification()

        @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)

        @test length(x.domain) == 2
        @test 2 in x.domain
        @test !(4 in x.domain)
        @test prunedDomains == SeaPearl.CPModification("x" => [4, 5, 6])

        y = SeaPearl.IntVar(2, 2, "y", trailer)

        cons2 = SeaPearl.LessOrEqualConstant(y, 1, trailer)

        @test !SeaPearl.propagate!(cons2, toPropagate, prunedDomains)

        @test isempty(y.domain)

    end
end

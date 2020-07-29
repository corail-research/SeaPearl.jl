
@testset "lessorqual.jl" begin
    
    @testset "isLessOrEqual()" begin
        trailer = SeaPearl.Trailer()
        b = SeaPearl.BoolVar("b", trailer)
        x = SeaPearl.IntVar(2, 6, "x", trailer)
        y = SeaPearl.IntVar(2, 6, "y", trailer)

        constraint = SeaPearl.isLessOrEqual(b, x, y, trailer)

        @test constraint in b.onDomainChange
        @test constraint in x.onDomainChange
        @test constraint in y.onDomainChange
        @test constraint.active.value
    end
    @testset "propagate!(::isLessOrEqual)" begin
        trailer = SeaPearl.Trailer()
        b = SeaPearl.BoolVar("b", trailer)
        x = SeaPearl.IntVar(2, 6, "x", trailer)
        y = SeaPearl.IntVar(2, 3, "y", trailer)

        constraint = SeaPearl.isLessOrEqual(b, x, y, trailer)

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
end

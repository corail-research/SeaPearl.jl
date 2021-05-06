@testset "absolute.jl" begin
    @testset "Absolute()-Suite1" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(-5, 5, "x", trailer)
        y = SeaPearl.IntVar(-10, 10, "y", trailer)

        constraint = SeaPearl.Absolute(x, y, trailer)

        @test constraint in x.onDomainChange
        @test constraint in y.onDomainChange
        @test y.domain.min.value == 0
        @test y.domain.max.value == 10
        @test x.domain.min.value == -5
        @test x.domain.max.value == 5
        @test constraint.active.value

        toPropagate = Set{SeaPearl.Constraint}()
        prunedDomains = SeaPearl.CPModification()

        @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)

        @test y.domain.max.value == 5
        @test length(x.domain) == 11

        SeaPearl.removeAbove!(x.domain, -2)

        @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
        @test y.domain.min.value == 2

        SeaPearl.removeBelow!(x.domain, -4)

        @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
        @test y.domain.max.value == 4

    end

    @testset "Absolute()-Suite2" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(-5, 0, "x", trailer)
        y = SeaPearl.IntVar(4, 4, "y", trailer)

        constraint = SeaPearl.Absolute(x, y, trailer)

        toPropagate = Set{SeaPearl.Constraint}()
        prunedDomains = SeaPearl.CPModification()

        @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)

        @test SeaPearl.isbound(y)
        @test SeaPearl.isbound(x)
        @test SeaPearl.assignedValue(x) == -4
    end

    @testset "Absolute()-Suite3" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(7, 7, "x", trailer)
        y = SeaPearl.IntVar(-1000, 13, "y", trailer)

        constraint = SeaPearl.Absolute(x, y, trailer)

        toPropagate = Set{SeaPearl.Constraint}()
        prunedDomains = SeaPearl.CPModification()

        @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)

        @test SeaPearl.isbound(x)
        @test SeaPearl.isbound(y)
        @test SeaPearl.assignedValue(x) == 7
    end

    @testset "Absolute()-Suite4" begin
        trailer = SeaPearl.Trailer()
        a = SeaPearl.IntVar(7, 7, "a", trailer)
        b = SeaPearl.IntVar(-7, -7, "b", trailer)
        c = SeaPearl.IntVar(6, 13, "c", trailer)

        toPropagate = Set{SeaPearl.Constraint}()
        prunedDomains = SeaPearl.CPModification()

        x = SeaPearl.IntVar(-5, 5, "x", trailer)
        constraint1 = SeaPearl.Absolute(x, a, trailer)
        @test !SeaPearl.propagate!(constraint1, toPropagate, prunedDomains)

        x = SeaPearl.IntVar(-5, 5, "x", trailer)
        constraint2 = SeaPearl.Absolute(b, x, trailer)
        @test !SeaPearl.propagate!(constraint2, toPropagate, prunedDomains)

        x = SeaPearl.IntVar(-5, 5, "x", trailer)
        constraint3 = SeaPearl.Absolute(x, c, trailer)
        @test !SeaPearl.propagate!(constraint3, toPropagate, prunedDomains)
    end

end

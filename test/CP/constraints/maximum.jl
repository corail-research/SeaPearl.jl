@testset "maximum.jl" begin

    @testset "MaximumConstraint()" begin
        trailer = SeaPearl.Trailer()

        x = SeaPearl.IntVar(2, 6, "x", trailer)
        y = SeaPearl.IntVar(2, 3, "y", trailer)
        z = SeaPearl.IntVar(2, 8, "z", trailer)
        
        m = SeaPearl.IntVar(0, 5, "m", trailer)
        vars = [x, y, z]
        constraint = SeaPearl.MaximumConstraint(vars, m, trailer)

        @test constraint in x.onDomainChange
        @test constraint in y.onDomainChange
        @test constraint in z.onDomainChange
        @test constraint in m.onDomainChange

        @test constraint.active.value
    end

    @testset "propagate!(::MaximumConstraint)" begin
        trailer = SeaPearl.Trailer()

        x = SeaPearl.IntVar(2, 6, "x", trailer)
        y = SeaPearl.IntVar(1, 3, "y", trailer)
        z = SeaPearl.IntVar(2, 8, "z", trailer)
        
        m = SeaPearl.IntVar(0, 5, "m", trailer)
        vars = [x, y, z]
        constraint = SeaPearl.MaximumConstraint(vars, m, trailer)

        toPropagate = Set{SeaPearl.Constraint}()
        prunedDomains = SeaPearl.CPModification()

        @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)

        @test length(y.domain) == 3
        @test 2 in x.domain
        @test !(6 in x.domain)
        @test prunedDomains == SeaPearl.CPModification(
            "x" => [6],
            "z" => [6, 7, 8],
            "m"  => [0, 1]
        )

    end
end
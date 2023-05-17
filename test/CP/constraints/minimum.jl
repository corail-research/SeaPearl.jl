@testset "minimum.jl" begin

    @testset "MinimumConstraint()" begin
        trailer = SeaPearl.Trailer()

        x = SeaPearl.IntVar(2, 6, "x", trailer)
        y = SeaPearl.IntVar(2, 3, "y", trailer)
        z = SeaPearl.IntVar(2, 8, "z", trailer)
        
        m = SeaPearl.IntVar(0, 5, "m", trailer)
        vars = [x, y, z]
        constraint = SeaPearl.MinimumConstraint(vars, m, trailer)

        @test constraint in x.onDomainChange
        @test constraint in y.onDomainChange
        @test constraint in z.onDomainChange
        @test constraint in m.onDomainChange

        @test constraint.active.value
    end

    @testset "propagate!(::MinimumConstraint)" begin
        trailer = SeaPearl.Trailer()

        x = SeaPearl.IntVar(6, 8, "x", trailer)
        y = SeaPearl.IntVar(1, 6, "y", trailer)
        z = SeaPearl.IntVar(7, 9, "z", trailer)
        
        m = SeaPearl.IntVar(3, 5, "m", trailer)
        vars = [x, y, z]
        constraint = SeaPearl.MinimumConstraint(vars, m, trailer)

        toPropagate = Set{SeaPearl.Constraint}()
        prunedDomains = SeaPearl.CPModification()

        @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)

        @test length(y.domain) == 3
        @test 6 in x.domain
        @test !(1 in y.domain)
        @test prunedDomains == SeaPearl.CPModification(
            "y" => [1,2,6],
        )   


        trailer = SeaPearl.Trailer()

        x = SeaPearl.IntVar(6, 8, "x", trailer)
        y = SeaPearl.IntVar(1, 4, "y", trailer)
        z = SeaPearl.IntVar(2, 9, "z", trailer)
        
        m = SeaPearl.IntVar(3, 5, "m", trailer)
        vars = [x, y, z]
        constraint = SeaPearl.MinimumConstraint(vars, m, trailer)

        toPropagate = Set{SeaPearl.Constraint}()
        prunedDomains = SeaPearl.CPModification()

        @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)

        @test prunedDomains == SeaPearl.CPModification(
            "m" => [5],
            "z" => [2],
            "y" => [1, 2]
        )

    end
end
@testset "nvalues.jl" begin
    @testset "init_nValues_variable()" begin
        trailer = SeaPearl.Trailer()

        x = SeaPearl.IntVar(5, 6, "x", trailer)
        y = SeaPearl.IntVar(2, 3, "y", trailer)
        z = SeaPearl.IntVar(2, 3, "z", trailer)
        vars = [x, y, z]

        nValues = SeaPearl.init_nValues_variable(vars, "nValues", trailer)

        @test nValues.domain.max.value == 5
        @test nValues.domain.min.value == 1
        
    end

    @testset "NValues()" begin
        trailer = SeaPearl.Trailer()

        x = SeaPearl.IntVar(5, 6, "x", trailer)
        y = SeaPearl.IntVar(2, 3, "y", trailer)
        z = SeaPearl.IntVar(2, 3, "z", trailer)
        vars = [x, y, z]

        nValues = SeaPearl.init_nValues_variable(vars, "nValues", trailer)

        constraint = SeaPearl.NValuesConstraint(vars, y, trailer)

        @test constraint in x.onDomainChange
        @test constraint in y.onDomainChange
        @test constraint in z.onDomainChange
        @test constraint.active.value
    end

    @testset "propagate!(::NValues)" begin
        trailer = SeaPearl.Trailer()

        x = SeaPearl.IntVar(5, 6, "x", trailer)
        y = SeaPearl.IntVar(2, 3, "y", trailer)
        z = SeaPearl.IntVar(2, 3, "z", trailer)
        vars = [x, y, z]

        nValues = SeaPearl.init_nValues_variable(vars, "nValues", trailer)

        constraint = SeaPearl.NValuesConstraint(vars, nValues, trailer)

        toPropagate = Set{SeaPearl.Constraint}()
        prunedDomains = SeaPearl.CPModification()

        @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)

        @test length(nValues.domain) == 4
        @test 5 in x.domain
        @test !(6 in nValues.domain)
        @test prunedDomains == SeaPearl.CPModification(
            "nValues" => [5],
        )

        SeaPearl.remove!(x.domain, 6)

        @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)

        @test prunedDomains == SeaPearl.CPModification(
            "nValues" => [5,4],
        )

    end
end

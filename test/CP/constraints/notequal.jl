@testset "notequal.jl" begin
    @testset "NotEqualConstant()" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(2, 6, "x", trailer)

        constraint = SeaPearl.NotEqualConstant(x, 3, trailer)

        @test constraint in x.onDomainChange
        @test constraint.active.value
    end
    @testset "propagate!(::NotEqualConstant)" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(2, 6, "x", trailer)

        constraint = SeaPearl.NotEqualConstant(x, 3, trailer)

        toPropagate = Set{SeaPearl.Constraint}()
        prunedDomains = SeaPearl.CPModification()

        @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)

        @test length(x.domain) == 4
        @test 2 in x.domain
        @test !(3 in x.domain)
        @test prunedDomains == SeaPearl.CPModification("x" => [3])

        y = SeaPearl.IntVar(2, 2, "y", trailer)

        cons2 = SeaPearl.NotEqualConstant(y, 2, trailer)

        @test !SeaPearl.propagate!(cons2, toPropagate, prunedDomains)

        @test isempty(y.domain)

        z = SeaPearl.IntVar(2, 6, "z", trailer)
        constraint1 = SeaPearl.NotEqualConstant(z, 3, trailer)
        constraint2 = SeaPearl.NotEqualConstant(z, 4, trailer)

        toPropagate2 = Set{SeaPearl.Constraint}()
        SeaPearl.propagate!(constraint1, toPropagate2, prunedDomains)
        
        @test constraint2 in toPropagate2

    end

    @testset "propagate!(::NotEqual)" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(2, 6, "x", trailer)
        y = SeaPearl.IntVar(5, 8, "y", trailer)

        constraint = SeaPearl.NotEqual(x, y, trailer)
        toPropagate = Set{SeaPearl.Constraint}()
        prunedDomains = SeaPearl.CPModification()

        @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)


        @test length(x.domain) == 5
        @test length(y.domain) == 4
        @test prunedDomains == SeaPearl.CPModification()

        # Propagation test
        z = SeaPearl.IntVar(5, 6, "z", trailer)
        constraint2 = SeaPearl.NotEqual(y, z, trailer)
        @test SeaPearl.propagate!(constraint2, toPropagate, prunedDomains)

        # Domain not reduced => not propagation
        @test !(constraint in toPropagate)
        @test !(constraint2 in toPropagate)

        # Domain reduced => propagation
        SeaPearl.remove!(z.domain, 6)
        @test SeaPearl.propagate!(constraint2, toPropagate, prunedDomains)
        @test constraint in toPropagate
        @test !(constraint2 in toPropagate)
        @test prunedDomains == SeaPearl.CPModification("y" => [5])
        @test length(y.domain) == 3

        #Unfeasible test
        t = SeaPearl.IntVar(5, 5, "t", trailer)
        constraint3 = SeaPearl.NotEqual(z, t, trailer)
        @test !SeaPearl.propagate!(constraint3, toPropagate, prunedDomains)


        # Same with IntVarViewOpposite
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(2, 6, "x", trailer)
        y = SeaPearl.IntVar(-8, -5, "y", trailer)
        minusY = SeaPearl.IntVarViewOpposite(y, "-y")

        constraint = SeaPearl.NotEqual(x, minusY, trailer)
        toPropagate = Set{SeaPearl.Constraint}()
        prunedDomains = SeaPearl.CPModification()

        @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)


        @test length(x.domain) == 5
        @test length(y.domain) == 4
        @test prunedDomains == SeaPearl.CPModification()

        # Propagation test
        z = SeaPearl.IntVar(5, 6, "z", trailer)
        constraint2 = SeaPearl.NotEqual(minusY, z, trailer)
        @test SeaPearl.propagate!(constraint2, toPropagate, prunedDomains)

        # Domain not reduced => not propagation
        @test !(constraint in toPropagate)
        @test !(constraint2 in toPropagate)

        # Domain reduced => propagation
        SeaPearl.remove!(z.domain, 6)
        @test SeaPearl.propagate!(constraint2, toPropagate, prunedDomains)
        @test constraint in toPropagate
        @test !(constraint2 in toPropagate)
        @test prunedDomains == SeaPearl.CPModification("-y" => [5])
        @test length(y.domain) == 3

        #Unfeasible test
        t = SeaPearl.IntVar(5, 5, "t", trailer)
        constraint3 = SeaPearl.NotEqual(z, t, trailer)
        @test !SeaPearl.propagate!(constraint3, toPropagate, prunedDomains)
    end
end

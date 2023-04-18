@testset "distance.jl" begin
    @testset "Distance()" begin
        trailer = SeaPearl.Trailer()

        x = SeaPearl.IntVar(2, 6, "x", trailer)
        y = SeaPearl.IntVar(2, 3, "y", trailer)
        
        z = SeaPearl.IntVar(2, 3, "z", trailer)
        
        constraint = SeaPearl.Distance(x, y, z, trailer)

        @test constraint in z.onDomainChange

        @test constraint.active.value
    end
    @testset "propagate!(::Distance)" begin
        trailer = SeaPearl.Trailer()
        
        x = SeaPearl.IntVar(4, 7, "x", trailer)
        y = SeaPearl.IntVar(0, 3, "y", trailer)
        
        z = SeaPearl.IntVar(0, 2, "z", trailer)
        
        constraint = SeaPearl.Distance(x, y, z, trailer)

        toPropagate = Set{SeaPearl.Constraint}()
        prunedDomains = SeaPearl.CPModification()

        @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)

        println(x)
        println(y)
        println(z)

        @test length(y.domain) == 2
        @test 4 in x.domain
        @test !(0 in z.domain)
        @test !(7 in x.domain)
        @test prunedDomains == SeaPearl.CPModification(
            "x"  => [6,7],
            "y"  => [0,1],
            "z" => [0]
        )
    end
end

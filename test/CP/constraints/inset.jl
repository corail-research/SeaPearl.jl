@testset "inset.jl" begin
    @testset "InSet()" begin
        trailer = SeaPearl.Trailer()
        a = SeaPearl.IntSetVar(2, 5, "a", trailer)
        x = SeaPearl.IntVar(0, 3, "x", trailer)

        constraint = SeaPearl.InSet(x, a, trailer)

        @test constraint in a.onDomainChange
        @test constraint in x.onDomainChange
        @test constraint.active.value
    end

    @testset "propagate!(::InSet)" begin
        trailer = SeaPearl.Trailer()
        a = SeaPearl.IntSetVar(2, 5, "a", trailer)
        x = SeaPearl.IntVar(0, 3, "x", trailer)
        constraint = SeaPearl.InSet(x, a, trailer)

        toPropagate = Set{SeaPearl.Constraint}()
        prunedDomains = SeaPearl.CPModification()

        @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)

        @test length(x.domain) == 2
        @test !(0 in x.domain)
        @test !(1 in x.domain)
        @test 2 in x.domain
        @test constraint.active.value

        SeaPearl.assign!(x, 3)

        @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
        
        @test SeaPearl.required_values(a.domain) == Set{Int}([3])
        @test SeaPearl.possible_not_required_values(a.domain) == Set{Int}([2, 4, 5])
        @test !constraint.active.value

        # Infeasibility
        trailer = SeaPearl.Trailer()
        a = SeaPearl.IntSetVar(2, 5, "a", trailer)
        x = SeaPearl.IntVar(0, 1, "x", trailer)
        constraint = SeaPearl.InSet(x, a, trailer)

        toPropagate = Set{SeaPearl.Constraint}()
        prunedDomains = SeaPearl.CPModification()

        @test !SeaPearl.propagate!(constraint, toPropagate, prunedDomains)

        #Infeasibility with excluding
        trailer = SeaPearl.Trailer()
        a = SeaPearl.IntSetVar(2, 5, "a", trailer)
        x = SeaPearl.IntVar(2, 3, "x", trailer)
        constraint = SeaPearl.InSet(x, a, trailer)

        toPropagate = Set{SeaPearl.Constraint}()
        prunedDomains = SeaPearl.CPModification()

        SeaPearl.exclude!(a.domain, 2)
        SeaPearl.exclude!(a.domain, 3)

        @test !SeaPearl.propagate!(constraint, toPropagate, prunedDomains)

        # Deactivation
        trailer = SeaPearl.Trailer()
        a = SeaPearl.IntSetVar(2, 5, "a", trailer)
        x = SeaPearl.IntVar(2, 3, "x", trailer)
        constraint = SeaPearl.InSet(x, a, trailer)

        toPropagate = Set{SeaPearl.Constraint}()
        prunedDomains = SeaPearl.CPModification()

        SeaPearl.require!(a.domain, 3)
        SeaPearl.require!(a.domain, 4)

        @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
        @test !constraint.active.value
    end
end
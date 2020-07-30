@testset "reifiedinset.jl" begin
    @testset "ReifiedInSet()" begin
        trailer = SeaPearl.Trailer()
        a = SeaPearl.IntSetVar(2, 5, "a", trailer)
        x = SeaPearl.IntVar(0, 3, "x", trailer)
        b = SeaPearl.BoolVar("b", trailer)

        constraint = SeaPearl.ReifiedInSet(x, a, b, trailer)

        @test constraint in a.onDomainChange
        @test constraint in x.onDomainChange
        @test constraint in b.onDomainChange
        @test constraint.active.value
    end

    @testset "propagate!(::ReifiedInSet)" begin
        trailer = SeaPearl.Trailer()
        a = SeaPearl.IntSetVar(2, 5, "a", trailer)
        x = SeaPearl.IntVar(0, 3, "x", trailer)
        b = SeaPearl.BoolVar("b", trailer)
        constraint = SeaPearl.ReifiedInSet(x, a, b, trailer)

        toPropagate = Set{SeaPearl.Constraint}()
        prunedDomains = SeaPearl.CPModification()

        @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)

        @test length(x.domain) == 4
        @test 0 in x.domain
        @test constraint.active.value
        @test prunedDomains == SeaPearl.CPModification()
        @test constraint.active.value

        ### Filtering b
        # b -> true
        SeaPearl.assign!(x, 3)
        SeaPearl.require!(a.domain, 3)

        @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
        
        @test SeaPearl.isbound(b)
        @test SeaPearl.assignedValue(b)
        @test !constraint.active.value

        # b -> false
        trailer = SeaPearl.Trailer()
        a = SeaPearl.IntSetVar(2, 5, "a", trailer)
        x = SeaPearl.IntVar(0, 1, "x", trailer)
        b = SeaPearl.BoolVar("b", trailer)
        constraint = SeaPearl.ReifiedInSet(x, a, b, trailer)

        toPropagate = Set{SeaPearl.Constraint}()
        prunedDomains = SeaPearl.CPModification()
        @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
        
        @test SeaPearl.isbound(b)
        @test !SeaPearl.assignedValue(b)
        @test !constraint.active.value


        ### Filtering a or x
        # b == true
        trailer = SeaPearl.Trailer()
        a = SeaPearl.IntSetVar(2, 5, "a", trailer)
        x = SeaPearl.IntVar(0, 3, "x", trailer)
        b = SeaPearl.BoolVar("b", trailer)
        constraint = SeaPearl.ReifiedInSet(x, a, b, trailer)

        SeaPearl.assign!(b, true)

        toPropagate = Set{SeaPearl.Constraint}()
        prunedDomains = SeaPearl.CPModification()

        @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)

        @test length(x.domain) == 2
        @test !(0 in x.domain)
        @test !(1 in x.domain)
        @test 2 in x.domain
        @test constraint.active.value
        @test prunedDomains == SeaPearl.CPModification("x" => [0, 1])

        SeaPearl.assign!(x, 3)

        @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
        
        @test SeaPearl.required_values(a.domain) == Set{Int}([3])
        @test SeaPearl.possible_not_required_values(a.domain) == Set{Int}([2, 4, 5])
        @test !constraint.active.value

        # b == false
        trailer = SeaPearl.Trailer()
        a = SeaPearl.IntSetVar(2, 5, "a", trailer)
        x = SeaPearl.IntVar(0, 4, "x", trailer)
        b = SeaPearl.BoolVar("b", trailer)
        constraint = SeaPearl.ReifiedInSet(x, a, b, trailer)

        SeaPearl.assign!(b, false)
        SeaPearl.require!(a.domain, 2)
        SeaPearl.require!(a.domain, 3)

        @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
        @test length(x.domain) == 3
        @test 0 in x.domain
        @test 1 in x.domain
        @test 4 in x.domain
        @test !(2 in x.domain)
        @test constraint.active.value

        SeaPearl.require!(a.domain, 4)
        @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
        @test !constraint.active.value


        trailer = SeaPearl.Trailer()
        a = SeaPearl.IntSetVar(2, 5, "a", trailer)
        x = SeaPearl.IntVar(2, 3, "x", trailer)
        b = SeaPearl.BoolVar("b", trailer)
        constraint = SeaPearl.ReifiedInSet(x, a, b, trailer)

        SeaPearl.assign!(b, false)
        SeaPearl.require!(a.domain, 2)
        SeaPearl.require!(a.domain, 3)

        @test !SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
    end
end
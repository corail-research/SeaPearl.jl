@testset "setdiffsingleton.jl" begin
    @testset "SetDiffSingleton()" begin
        trailer = SeaPearl.Trailer()
        a = SeaPearl.IntSetVar(2, 5, "a", trailer)
        b = SeaPearl.IntSetVar(2, 5, "a", trailer)
        x = SeaPearl.IntVar(0, 3, "x", trailer)

        constraint = SeaPearl.SetDiffSingleton(a, b, x, trailer)

        @test constraint in a.onDomainChange
        @test constraint in b.onDomainChange
        @test constraint in x.onDomainChange
        @test constraint.active.value
    end

    @testset "propagate!(::SetDiffSingleton)" begin
        trailer = SeaPearl.Trailer()
        a = SeaPearl.IntSetVar(1, 3, "a", trailer)
        b = SeaPearl.IntSetVar(2, 5, "b", trailer)
        x = SeaPearl.IntVar(0, 3, "x", trailer)

        constraint = SeaPearl.SetDiffSingleton(a, b, x, trailer)

        SeaPearl.require!(a.domain, 2)
        
        @test SeaPearl.possible_not_required_values(b.domain) == Set{Int}([2, 3, 4, 5])
        @test SeaPearl.possible_not_required_values(a.domain) == Set{Int}([1, 3])
        @test SeaPearl.required_values(a.domain) == Set{Int}([2])
        @test length(x.domain) == 4

        toPropagate = Set{SeaPearl.Constraint}()
        prunedDomains = SeaPearl.CPModification()

        SeaPearl.saveState!(trailer)

        @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)

        @test SeaPearl.possible_not_required_values(b.domain) == Set{Int}([3])
        @test SeaPearl.required_values(b.domain) == Set{Int}([2])
        @test SeaPearl.possible_not_required_values(a.domain) == Set{Int}([3])
        @test 0 in x.domain
        @test 1 in x.domain
        @test 3 in x.domain
        @test !(2 in x.domain)
        @test constraint.active.value
        @test prunedDomains == SeaPearl.CPModification("x" => [2])


        SeaPearl.assign!(x, 3)

        @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
        
        @test SeaPearl.required_values(b.domain) == Set{Int}([2])
        @test SeaPearl.possible_not_required_values(b.domain) == Set{Int}([3])
        @test SeaPearl.required_values(a.domain) == Set{Int}([2])
        @test SeaPearl.possible_not_required_values(a.domain) == Set{Int}()
        @test !constraint.active.value

        SeaPearl.restoreState!(trailer)
        @test SeaPearl.possible_not_required_values(b.domain) == Set{Int}([2, 3, 4, 5])
        @test SeaPearl.possible_not_required_values(a.domain) == Set{Int}([1, 3])
        @test SeaPearl.required_values(a.domain) == Set{Int}([2])
        @test length(x.domain) == 4


        # Bug in tsptw:
        trailer = SeaPearl.Trailer()
        a = SeaPearl.IntSetVar(1, 1, "a", trailer)
        b = SeaPearl.IntSetVar(1, 2, "b", trailer)
        x = SeaPearl.IntVar(2, 2, "x", trailer)
        constraint = SeaPearl.SetDiffSingleton(a, b, x, trailer)

        @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)

        @test SeaPearl.possible_not_required_values(b.domain) == Set{Int}([1, 2])
        @test SeaPearl.required_values(b.domain) == Set{Int}()
        @test SeaPearl.possible_not_required_values(a.domain) == Set{Int}([1])
        @test SeaPearl.required_values(a.domain) == Set{Int}()
        @test SeaPearl.isbound(x)
        @test SeaPearl.assignedValue(x) == 2

        # more complex
        trailer = SeaPearl.Trailer()
        a = SeaPearl.IntSetVar(1, 5, "a", trailer)
        b = SeaPearl.IntSetVar(1, 8, "b", trailer)
        SeaPearl.exclude!(b.domain, 6)
        SeaPearl.exclude!(b.domain, 2)
        SeaPearl.exclude!(b.domain, 3)
        SeaPearl.require!(b.domain, 1)
        SeaPearl.require!(b.domain, 4)
        x = SeaPearl.IntVar(4, 4, "x", trailer)
        constraint = SeaPearl.SetDiffSingleton(a, b, x, trailer)

        @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)

        @test SeaPearl.possible_not_required_values(b.domain) == Set{Int}([5])
        @test SeaPearl.required_values(b.domain) == Set{Int}([1, 4])
        @test SeaPearl.possible_not_required_values(a.domain) == Set{Int}([5])
        @test SeaPearl.required_values(a.domain) == Set{Int}([1])


        # if x is assigned
        trailer = SeaPearl.Trailer()
        a = SeaPearl.IntSetVar(1, 2, "a", trailer)
        b = SeaPearl.IntSetVar(1, 1, "b", trailer)
        x = SeaPearl.IntVar(2, 2, "x", trailer)
        constraint = SeaPearl.SetDiffSingleton(a, b, x, trailer)

        @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)

        @test SeaPearl.possible_not_required_values(b.domain) == Set{Int}([1])
        @test SeaPearl.required_values(b.domain) == Set{Int}()
        @test SeaPearl.possible_not_required_values(a.domain) == Set{Int}([1])
        @test SeaPearl.required_values(a.domain) == Set{Int}()
        @test SeaPearl.isbound(x)
        @test SeaPearl.assignedValue(x) == 2

        # Infeasibility
        trailer = SeaPearl.Trailer()
        a = SeaPearl.IntSetVar(1, 3, "a", trailer)
        b = SeaPearl.IntSetVar(2, 5, "b", trailer)
        x = SeaPearl.IntVar(3, 3, "x", trailer)

        constraint = SeaPearl.SetDiffSingleton(a, b, x, trailer)

        SeaPearl.require!(a.domain, 3)

        toPropagate = Set{SeaPearl.Constraint}()
        prunedDomains = SeaPearl.CPModification()

        @test !SeaPearl.propagate!(constraint, toPropagate, prunedDomains)

    end
end
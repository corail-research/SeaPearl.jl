@testset "setequalconstant.jl" begin
    @testset "SetEqualConstant()" begin
        trailer = SeaPearl.Trailer()
        a = SeaPearl.IntSetVar(2, 5, "a", trailer)
        s = Set{Int}([5, 6, 7])

        constraint = SeaPearl.SetEqualConstant(a, s, trailer)

        @test constraint in a.onDomainChange
        @test constraint.active.value
    end

    @testset "propagate!(::SetEqualConstant)" begin
        trailer = SeaPearl.Trailer()
        a = SeaPearl.IntSetVar(2, 5, "a", trailer)
        s = Set{Int}([4, 5])
        constraint = SeaPearl.SetEqualConstant(a, s, trailer)

        toPropagate = Set{SeaPearl.Constraint}()
        prunedDomains = SeaPearl.CPModification()

        @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)

        @test SeaPearl.required_values(a.domain) == Set{Int}([4, 5])
        @test SeaPearl.possible_not_required_values(a.domain) == Set{Int}()
        @test !constraint.active.value

        # Infeasibility
        trailer = SeaPearl.Trailer()
        a = SeaPearl.IntSetVar(2, 5, "a", trailer)
        s = Set{Int}([4, 7])
        constraint = SeaPearl.SetEqualConstant(a, s, trailer)

        toPropagate = Set{SeaPearl.Constraint}()
        prunedDomains = SeaPearl.CPModification()

        @test !SeaPearl.propagate!(constraint, toPropagate, prunedDomains)
    end
end
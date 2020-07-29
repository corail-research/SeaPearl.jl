using SeaPearl

@testset "sumlessthan.jl" begin
    @testset "SumLessThan()" begin
        trailer = SeaPearl.Trailer()
        vars = SeaPearl.AbstractIntVar[]

        x = SeaPearl.IntVar(2, 6, "x", trailer)
        push!(vars, x)
        y = SeaPearl.IntVar(2, 3, "y", trailer)
        push!(vars, y)
        ax = SeaPearl.IntVarViewMul(x, 3, "3x")
        push!(vars, ax)
        minusY = SeaPearl.IntVarViewOpposite(y, "-y")
        push!(vars, minusY)
        constraint = SeaPearl.SumLessThan(vars, 10, trailer)

        @test constraint in x.onDomainChange
        @test constraint in y.onDomainChange
        @test constraint.active.value
        @test constraint.numberOfFreeVars.value == 4
        @test constraint.sumOfFixedVars.value == 0
        @test constraint.freeIds == [1, 2, 3, 4]
    end
    @testset "propagate!(::SumLessThan)" begin
        trailer = SeaPearl.Trailer()
        vars = SeaPearl.AbstractIntVar[]

        x = SeaPearl.IntVar(2, 3, "x", trailer)
        push!(vars, x)
        y = SeaPearl.IntVar(5, 15, "y", trailer)
        ax = SeaPearl.IntVarViewMul(x, 3, "3x")
        push!(vars, ax)
        minusY = SeaPearl.IntVarViewOpposite(y, "-y")
        push!(vars, minusY)
        constraint = SeaPearl.SumLessThan(vars, -5, trailer)

        toPropagate = Set{SeaPearl.Constraint}()
        prunedDomains = SeaPearl.CPModification()

        @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)

        @test length(y.domain) == 3
        @test 13 in y.domain
        @test !(12 in y.domain)
        @test !(3 in ax.domain)

    end
end

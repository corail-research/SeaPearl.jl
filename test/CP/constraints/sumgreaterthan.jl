using SeaPearl

@testset "sumgreaterthan.jl" begin
    @testset "SumGreaterThan()" begin
        trailer = SeaPearl.Trailer()

        x = SeaPearl.IntVar(2, 6, "x", trailer)
        y = SeaPearl.IntVar(2, 3, "y", trailer)
        ax = SeaPearl.IntVarViewMul(x, 3, "3x")
        minusY = SeaPearl.IntVarViewOpposite(y, "-y")
        vars = [x, y, ax, minusY]
        constraint = SeaPearl.SumGreaterThan(vars, 10, trailer)

        @test constraint in x.onDomainChange
        @test constraint in y.onDomainChange
        @test constraint.active.value
        @test constraint.numberOfFreeVars.value == 4
        @test constraint.sumOfFixedVars.value == 0
        @test constraint.freeIds == [1, 2, 3, 4]
    end
    @testset "propagate!(::SumGreaterThan)" begin
        trailer = SeaPearl.Trailer()
        vars = SeaPearl.AbstractIntVar[]

        x = SeaPearl.IntVar(2, 3, "x", trailer)
        push!(vars, x)
        y = SeaPearl.IntVar(5, 15, "y", trailer)
        ax = SeaPearl.IntVarViewMul(x, 3, "3x")
        push!(vars, ax)
        minusY = SeaPearl.IntVarViewOpposite(y, "-y")
        push!(vars, minusY)
        constraint = SeaPearl.SumGreaterThan(vars, 5, trailer)

        toPropagate = Set{SeaPearl.Constraint}()
        prunedDomains = SeaPearl.CPModification()

        @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)

        @test length(y.domain) == 3
        @test 7 in y.domain
        @test !(8 in y.domain)
        @test !(10 in ax.domain)

    end
end

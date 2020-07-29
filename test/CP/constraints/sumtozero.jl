using SeaPearl

@testset "sumtozero.jl" begin
    @testset "SumToZero()" begin
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
        constraint = SeaPearl.SumToZero(vars, trailer)

        @test constraint in x.onDomainChange
        @test constraint in y.onDomainChange
        @test constraint.active.value
        @test constraint.numberOfFreeVars.value == 4
        @test constraint.sumOfFixedVars.value == 0
        @test constraint.freeIds == [1, 2, 3, 4]
    end
    @testset "propagate!(::SumToZero)" begin
        trailer = SeaPearl.Trailer()
        vars = SeaPearl.AbstractIntVar[]

        x = SeaPearl.IntVar(2, 3, "x", trailer)
        push!(vars, x)
        y = SeaPearl.IntVar(5, 15, "y", trailer)
        ax = SeaPearl.IntVarViewMul(x, 3, "3x")
        push!(vars, ax)
        minusY = SeaPearl.IntVarViewOpposite(y, "-y")
        push!(vars, minusY)
        constraint = SeaPearl.SumToZero(vars, trailer)

        toPropagate = Set{SeaPearl.Constraint}()
        prunedDomains = SeaPearl.CPModification()

        @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)

        @test length(y.domain) == 5
        @test 8 in y.domain
        @test !(7 in y.domain)
        @test !(13 in ax.domain)
        @test prunedDomains == SeaPearl.CPModification("-y" => [-5, -6, -7, -13, -14, -15])


        cons2 = SeaPearl.EqualConstant(y, 15, trailer)

        @test !SeaPearl.propagate!(cons2, toPropagate, prunedDomains)


    end
end

@testset "sumtozero.jl" begin
    @testset "SumToZero()" begin
        trailer = SeaPearl.Trailer()

        x = SeaPearl.IntVar(2, 6, "x", trailer)
        y = SeaPearl.IntVar(2, 3, "y", trailer)
        ax = SeaPearl.IntVarViewMul(x, 3, "3x")
        minusY = SeaPearl.IntVarViewOpposite(y, "-y")
        vars = [x, y, ax, minusY]
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
        @test prunedDomains == SeaPearl.CPModification(
            "-y" => [-5, -6, -7, -13, -14, -15],
            "y"  => [5, 6, 7, 13, 14, 15]
        )


        cons2 = SeaPearl.EqualConstant(y, 15, trailer)

        @test !SeaPearl.propagate!(cons2, toPropagate, prunedDomains)


    end
    @testset "SumToVariable()" begin
        trailer = SeaPearl.Trailer()

        x1 = SeaPearl.IntVar(2, 6, "x1", trailer)
        x2 = SeaPearl.IntVar(2, 6, "x2", trailer)
        x3 = SeaPearl.IntVar(2, 6, "x3", trailer)
        x = Vector{SeaPearl.AbstractIntVar}([x1, x2, x3])

        y = SeaPearl.IntVar(2, 3, "y", trailer)

        
        constraint = SeaPearl.SumToVariable(x, y, trailer)

        @test constraint in x2.onDomainChange
        @test constraint in y.onDomainChange
        @test constraint.active.value
        @test constraint.numberOfFreeVars.value == 4
        @test constraint.sumOfFixedVars.value == 0
        @test constraint.freeIds == [1, 2, 3, 4]
    end
    @testset "propagate!(::SumToVariable)" begin
        trailer = SeaPearl.Trailer()

        x1 = SeaPearl.IntVar(0, 3, "x1", trailer)
        x2 = SeaPearl.IntVar(1, 5, "x2", trailer)
        x3 = SeaPearl.IntVar(0, 2, "x3", trailer)
        x = Vector{SeaPearl.AbstractIntVar}([x1, x2, x3])

        y = SeaPearl.IntVar(0, 1, "y", trailer)
        
        constraint = SeaPearl.SumToVariable(x, y, trailer)

        toPropagate = Set{SeaPearl.Constraint}()
        prunedDomains = SeaPearl.CPModification()

        @test SeaPearl.propagate!(constraint, toPropagate, prunedDomains)

        @test length(y.domain) == 1
        @test 1 in y.domain
        @test !(3 in x1.domain)
        @test !(1 in x3.domain)
        @test prunedDomains == SeaPearl.CPModification(
            "x1"  => [1,2,3],
            "x2"  => [2,3,4,5],
            "x3"  => [1,2],
            "-y" => [0],
            "y" => [0]
        )

    end
end


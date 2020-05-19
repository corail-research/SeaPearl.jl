using CPRL

@testset "sumtozero.jl" begin
    @testset "SumToZero()" begin
        trailer = CPRL.Trailer()
        vars = CPRL.AbstractIntVar[]

        x = CPRL.IntVar(2, 6, "x", trailer)
        push!(vars, x)
        y = CPRL.IntVar(2, 3, "y", trailer)
        push!(vars, y)
        ax = CPRL.IntVarViewMul(x, 3, "3x")
        push!(vars, ax)
        minusY = CPRL.IntVarViewOpposite(y, "-y")
        push!(vars, minusY)
        constraint = CPRL.SumToZero(vars, trailer)

        @test constraint in x.onDomainChange
        @test constraint in y.onDomainChange
        @test constraint.active.value
        @test constraint.numberOfFreeVars.value == 4
        @test constraint.sumOfFixedVars.value == 0
        @test constraint.freeIds == [1, 2, 3, 4]
    end
    @testset "propagate!(::SumToZero)" begin
        trailer = CPRL.Trailer()
        vars = CPRL.AbstractIntVar[]

        x = CPRL.IntVar(2, 3, "x", trailer)
        push!(vars, x)
        y = CPRL.IntVar(5, 15, "y", trailer)
        ax = CPRL.IntVarViewMul(x, 3, "3x")
        push!(vars, ax)
        minusY = CPRL.IntVarViewOpposite(y, "-y")
        push!(vars, minusY)
        constraint = CPRL.SumToZero(vars, trailer)

        toPropagate = Set{CPRL.Constraint}()
        prunedDomains = CPRL.CPModification()

        @test CPRL.propagate!(constraint, toPropagate, prunedDomains)

        @test length(y.domain) == 5
        @test 8 in y.domain
        @test !(7 in y.domain)
        @test !(13 in ax.domain)
        @test prunedDomains == CPRL.CPModification("-y" => [-5, -6, -7, -13, -14, -15])


        cons2 = CPRL.EqualConstant(y, 15, trailer)

        @test !CPRL.propagate!(cons2, toPropagate, prunedDomains)


    end
end

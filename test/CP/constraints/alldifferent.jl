using SeaPearl

@testset "alldifferent.jl" begin
    @testset "AllDifferent()" begin
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
        constraint = SeaPearl.AllDifferent(vars, trailer)

        @test constraint in x.onDomainChange
        @test constraint in y.onDomainChange
        @test constraint.active.value
        @test constraint.numberOfFreeVars.value == 4
        @test constraint.freeIds == [1, 2, 3, 4]
        
    end
    @testset "propagate!(::AllDifferent)" begin
        # Should be detected as inconsistent by a non-naive filtering algorithm
        trailer = SeaPearl.Trailer()
        vars = SeaPearl.AbstractIntVar[]
        x = SeaPearl.IntVar(2, 3, "x", trailer)
        push!(vars, x)
        y = SeaPearl.IntVar(2, 3, "y", trailer)
        push!(vars, y)
        z = SeaPearl.IntVar(2, 3, "z", trailer)
        push!(vars, z)
        w = SeaPearl.IntVar(5, 6, "w", trailer)
        push!(vars, w)
        
        constraint = SeaPearl.AllDifferent(vars, trailer)
        @test !SeaPearl.propagate!(constraint, Set{SeaPearl.Constraint}(), SeaPearl.CPModification())

        # Cascading filtering
        vars = SeaPearl.AbstractIntVar[]
        x1 = SeaPearl.IntVar(1, 4, "x1", trailer)
        push!(vars, x1)
        x2 = SeaPearl.IntVar(2, 4, "x2", trailer)
        push!(vars, x2)
        x3 = SeaPearl.IntVar(3, 4, "x3", trailer)
        push!(vars, x3)
        x4 = SeaPearl.IntVar(4, 4, "x4", trailer)
        push!(vars, x4)
        constraint = SeaPearl.AllDifferent(vars, trailer)
        @test SeaPearl.propagate!(constraint, Set{SeaPearl.Constraint}(), SeaPearl.CPModification())

        @test length(x1.domain) == 1
        @test length(x2.domain) == 1
        @test length(x3.domain) == 1
        @test length(x4.domain) == 1

        @test 1 in x1.domain
        @test 2 in x2.domain
        @test 3 in x3.domain
        @test 4 in x4.domain

    end
end

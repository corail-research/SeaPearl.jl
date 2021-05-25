@testset "CPModification" begin
    
    @testset "Integer variables" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        x = SeaPearl.IntVar(-10, 10, "x", trailer)
        y = SeaPearl.IntVar(-10, 10, "y", trailer)
        z = SeaPearl.IntVar(-10, 10, "z", trailer)
        a = SeaPearl.IntVar(-10, 10, "a", trailer)
        b = SeaPearl.IntVar(1, 10, "b", trailer)
        c = SeaPearl.IntVar(1, 10, "c", trailer)
        SeaPearl.addVariable!.([model], [x, y, z, a, b, c])

        c1 = SeaPearl.Absolute(a, x, trailer)
        c2 = SeaPearl.AllDifferent([x, y, z], trailer)
        c3 = SeaPearl.BinaryMaximumBC(y, a, z, trailer)
        mat = fill(-8, (10, 10))
        c4 = SeaPearl.Element2D(mat, b, c, a, trailer)
        c5 = SeaPearl.Equal(b, c, trailer)
        c6 = SeaPearl.GreaterOrEqualConstant(b, 5, trailer)
        c7 = SeaPearl.NotEqual(z, a, trailer)
        c8 = SeaPearl.SumGreaterThan([b, c], 18, trailer)
        c9 = SeaPearl.SumLessThan([y, z], -18, trailer)
        c10 = SeaPearl.SumToZero([z, b], trailer)
        append!(model.constraints, [c1, c2, c3, c4, c5, c6, c7])

        status, prunedDomains = SeaPearl.fixPoint!(model)

        @test Set(prunedDomains["x"]) == setdiff(Set(-10:10), 8)
        @test Set(prunedDomains["y"]) == setdiff(Set(-10:10), -8)
        @test Set(prunedDomains["z"]) == setdiff(Set(-10:10), -10)
        @test Set(prunedDomains["a"]) == setdiff(Set(-10:10), -8)
        @test Set(prunedDomains["b"]) == setdiff(Set(1:10), 10)
        @test Set(prunedDomains["c"]) == setdiff(Set(1:10), 10)
    end

    @testset "Boolean variables" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        x = SeaPearl.IntVar(5, 10, "x", trailer)
        y = SeaPearl.IntVar(8, 8, "y", trailer)
        z = SeaPearl.IntSetVar(5, 10, "z", trailer)
        a = SeaPearl.BoolVar("a", trailer)
        b = SeaPearl.BoolVar("b", trailer)
        c = SeaPearl.BoolVar("c", trailer)
        SeaPearl.addVariable!.([model], [x, y, z, a, b, c]; branchable=false)

        c1 = SeaPearl.BinaryOr(a, b, trailer)
        c2 = SeaPearl.isBinaryOr(a, b, c, trailer)
        c3 = SeaPearl.isLessOrEqual(c, x, y, trailer)
        c4 = SeaPearl.ReifiedInSet(x, z, c, trailer)
        c5 = SeaPearl.SetEqualConstant(z, Set(5:10), trailer)
        append!(model.constraints, [c1, c2, c3, c4, c5])

        status, prunedDomains = SeaPearl.fixPoint!(model)

        @test prunedDomains["a"] == [false]
        @test !("b" in keys(prunedDomains))
        @test prunedDomains["c"] == [false]

    end

    @testset "Set variables" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        x = SeaPearl.IntVar(6, 10, "x", trailer)
        y = SeaPearl.IntSetVar(0, 10, "y", trailer)
        z = SeaPearl.IntSetVar(5, 10, "z", trailer)
        a = SeaPearl.BoolVar("a", trailer)
        SeaPearl.addVariable!.([model], [x, y, z, a]; branchable=false)

        c1 = SeaPearl.InSet(x, z, trailer)
        c2 = SeaPearl.ReifiedInSet(x, z, a, trailer)
        c3 = SeaPearl.SetDiffSingleton(y, z, x, trailer)
        c4 = SeaPearl.SetEqualConstant(y, Set(7:10), trailer)
        append!(model.constraints, [c1, c2, c3, c4])

        status, prunedDomains = SeaPearl.fixPoint!(model)

        @test Set(prunedDomains["y"].excluded) == Set(0:6)
        @test Set(prunedDomains["y"].required) == Set(7:10)
        @test Set(prunedDomains["z"].excluded) == Set(5)
        @test Set(prunedDomains["z"].required) == Set(6:10)
    end
    
end
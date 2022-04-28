@testset "IntVar.jl" begin
    @testset "isbound()" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(2, 6, "x", trailer)

        @test !SeaPearl.isbound(x)

        SeaPearl.assign!(x, 3)

        @test SeaPearl.isbound(x)
    end

    @testset "assignedValue()" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(5, 5, "x", trailer)

        @test SeaPearl.assignedValue(x) == 5

        y = SeaPearl.IntVar(5, 8, "y", trailer)
        @test_throws AssertionError SeaPearl.assignedValue(y)
    end


    @testset "IntVar()" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(5, 8, "x", trailer)

        @test length(x.domain) == 4
        @test 5 in x.domain && 8 in x.domain && !(4 in x.domain) && !(9 in x.domain)
    end

    @testset "assign!()" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(5, 6, "x", trailer)

        @test_throws AssertionError SeaPearl.assignedValue(x)

        SeaPearl.assign!(x, 5)

        @test SeaPearl.assignedValue(x) == 5
    end

    @testset "* overloading" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(5, 6, "x", trailer)
        y = 3 * x

        @test isa(y, SeaPearl.IntVarViewMul)
        @test SeaPearl.minimum(y.domain) == 15
        @test SeaPearl.maximum(y.domain) == 18
        @test SeaPearl.length(y.domain) == 2

        SeaPearl.assign!(x, 5)
        @test SeaPearl.assignedValue(y) == 15

    end
end

    @testset "-()" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(5, 8, "x", trailer)
        y = -x
        
        @test isa(y, SeaPearl.IntVarViewOpposite)
        @test SeaPearl.minimum(y.domain) == -8
        @test SeaPearl.maximum(y.domain) == -5
        @test !SeaPearl.isbound(y)

        SeaPearl.assign!(x, 5)

        @test SeaPearl.length(y.domain) == 1
        @test SeaPearl.isbound(y)
        @test SeaPearl.assignedValue(y) == -SeaPearl.assignedValue(x)
    end
end

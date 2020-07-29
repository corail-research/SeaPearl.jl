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
end
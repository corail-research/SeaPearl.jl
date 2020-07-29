@testset "BoolVar.jl" begin
    @testset "isbound()" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.BoolVar("x", trailer)

        @test !SeaPearl.isbound(x)

        SeaPearl.assign!(x, false)

        @test SeaPearl.isbound(x)
    end

    @testset "assignedValue()" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.BoolVar("x", trailer)

        @test_throws AssertionError SeaPearl.assignedValue(y)

        SeaPearl.assign!(x, false)

        @test !SeaPearl.assignedValue(x)
    end


    @testset "BoolVar()" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar("x", trailer)

        @test length(x.domain) == 2
        @test true in x.domain && false in x.domain
    end
end
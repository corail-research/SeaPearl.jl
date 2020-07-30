@testset "IntSetVar.jl" begin
    @testset "isbound()" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntSetVar(2, 6, "x", trailer)

        @test !SeaPearl.isbound(x)

        y = SeaPearl.IntSetVar(2, 3, "x", trailer)

        SeaPearl.exclude!(y.domain, 3)
        SeaPearl.require!(y.domain, 2)

        @test SeaPearl.isbound(y)
    end

    @testset "assignedValue()" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntSetVar(5, 6, "x", trailer)

        SeaPearl.require!(x.domain, 5)
        SeaPearl.require!(x.domain, 6)

        @test SeaPearl.assignedValue(x) == Set{Int}([5, 6])

        y = SeaPearl.IntSetVar(5, 8, "y", trailer)
        @test_throws AssertionError SeaPearl.assignedValue(y)
    end


    @testset "IntSetVar()" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntSetVar(5, 8, "x", trailer)

        @test SeaPearl.possible_not_required_values(x.domain) == Set{Int}([5, 6, 7, 8])
    end
end
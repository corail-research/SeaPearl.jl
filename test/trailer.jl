@testset "trailer.jl" begin

    @testset "StateObject{Int}()" begin
        trailer = SeaPearl.Trailer()
        reversibleInt = SeaPearl.StateObject{Int}(3, trailer)

        @test reversibleInt.value == 3
        @test reversibleInt.trailer == trailer
    end

    @testset "StateObject{Bool}()" begin
        trailer = SeaPearl.Trailer()
        reversibleInt = SeaPearl.StateObject{Bool}(true, trailer)

        @test reversibleInt.value == true
        @test reversibleInt.trailer == trailer
    end

    @testset "trail!()" begin
        trailer = SeaPearl.Trailer()
        reversibleInt = SeaPearl.StateObject{Int}(3, trailer)

        SeaPearl.trail!(reversibleInt)

        @test length(trailer.current) == 1

        se = first(trailer.current)

        @test se.object == reversibleInt
        @test se.value == 3
    end

    @testset "setValue!()" begin
        trailer = SeaPearl.Trailer()
        reversibleInt = SeaPearl.StateObject{Int}(3, trailer)

        # Check when same value
        SeaPearl.setValue!(reversibleInt, 3)
        @test length(trailer.current) == 0
        @test reversibleInt.value == 3

        # With a different value
        SeaPearl.setValue!(reversibleInt, 5)
        @test length(trailer.current) == 1
        @test reversibleInt.value == 5

        se = first(trailer.current)
        @test se.value == 3

    end

    @testset "saveState!()" begin
        trailer = SeaPearl.Trailer()
        reversibleInt = SeaPearl.StateObject{Int}(3, trailer)

        current = trailer.current

        SeaPearl.setValue!(reversibleInt, 5)
        SeaPearl.saveState!(trailer)

        @test first(trailer.prior) == current
        @test isempty(trailer.current)
    end

    @testset "restoreState!()" begin
        trailer = SeaPearl.Trailer()
        reversibleInt = SeaPearl.StateObject{Int}(3, trailer)

        current = trailer.current

        SeaPearl.setValue!(reversibleInt, 5)
        SeaPearl.saveState!(trailer)
        SeaPearl.setValue!(reversibleInt, 8)

        @test reversibleInt.value == 8

        SeaPearl.restoreState!(trailer)

        @test reversibleInt.value == 5

        SeaPearl.restoreState!(trailer)

        @test reversibleInt.value == 3
    end

    @testset "withNewState!()" begin

        trailer = SeaPearl.Trailer()
        reversibleInt = SeaPearl.StateObject{Int}(3, trailer)

        SeaPearl.withNewState!(trailer) do
            SeaPearl.setValue!(reversibleInt, 5)

            @test reversibleInt.value == 5
        end

        @test reversibleInt.value == 3

    end

    @testset "restoreInitialState!()" begin
        trailer = SeaPearl.Trailer()
        reversibleInt = SeaPearl.StateObject{Int}(3, trailer)

        SeaPearl.saveState!(trailer)
        SeaPearl.setValue!(reversibleInt, 4)
        SeaPearl.saveState!(trailer)
        SeaPearl.setValue!(reversibleInt, 5)
        SeaPearl.saveState!(trailer)
        SeaPearl.setValue!(reversibleInt, 6)
        SeaPearl.saveState!(trailer)
        SeaPearl.setValue!(reversibleInt, 7)

        SeaPearl.restoreInitialState!(trailer)

        @test reversibleInt.value == 3
    end

end
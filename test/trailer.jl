using CPRL

@testset "trailer.jl" begin

    @testset "StateObject{Int}()" begin
        trailer = CPRL.Trailer()
        reversibleInt = CPRL.StateObject{Int}(3, trailer)

        @test reversibleInt.value == 3
        @test reversibleInt.trailer == trailer
    end

    @testset "StateObject{Bool}()" begin
        trailer = CPRL.Trailer()
        reversibleInt = CPRL.StateObject{Bool}(true, trailer)

        @test reversibleInt.value == true
        @test reversibleInt.trailer == trailer
    end

    @testset "trail!()" begin
        trailer = CPRL.Trailer()
        reversibleInt = CPRL.StateObject{Int}(3, trailer)

        CPRL.trail!(reversibleInt)

        @test length(trailer.current) == 1

        se = first(trailer.current)

        @test se.object == reversibleInt
        @test se.value == 3
    end

    @testset "setValue!()" begin
        trailer = CPRL.Trailer()
        reversibleInt = CPRL.StateObject{Int}(3, trailer)

        # Check when same value
        CPRL.setValue!(reversibleInt, 3)
        @test length(trailer.current) == 0
        @test reversibleInt.value == 3

        # With a different value
        CPRL.setValue!(reversibleInt, 5)
        @test length(trailer.current) == 1
        @test reversibleInt.value == 5

        se = first(trailer.current)
        @test se.value == 3

    end

    @testset "saveState!()" begin
        trailer = CPRL.Trailer()
        reversibleInt = CPRL.StateObject{Int}(3, trailer)

        current = trailer.current

        CPRL.setValue!(reversibleInt, 5)
        CPRL.saveState!(trailer)

        @test first(trailer.prior) == current
        @test isempty(trailer.current)
    end

    @testset "restoreState!()" begin
        trailer = CPRL.Trailer()
        reversibleInt = CPRL.StateObject{Int}(3, trailer)

        current = trailer.current

        CPRL.setValue!(reversibleInt, 5)
        CPRL.saveState!(trailer)
        CPRL.setValue!(reversibleInt, 8)

        @test reversibleInt.value == 8

        CPRL.restoreState!(trailer)

        @test reversibleInt.value == 5

        CPRL.restoreState!(trailer)

        @test reversibleInt.value == 3
    end

    @testset "withNewState!()" begin

        trailer = CPRL.Trailer()
        reversibleInt = CPRL.StateObject{Int}(3, trailer)

        CPRL.withNewState!(trailer) do
            CPRL.setValue!(reversibleInt, 5)

            @test reversibleInt.value == 5
        end

        @test reversibleInt.value == 3

    end

end
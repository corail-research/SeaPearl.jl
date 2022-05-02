@testset "random.jl" begin

    @testset "RandomHeuristic draw in the domain" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        heuristic = SeaPearl.RandomHeuristic()

        x = SeaPearl.IntVar(2, 4, "x", trailer)
        for i in 1:10
            selected_value = heuristic.selectValue(x)
            @test selected_value >= 2
            @test selected_value <= 4
        end

        SeaPearl.remove!(x.domain, 3)
        for i in 1:10
            selected_value = heuristic.selectValue(x)
            @test selected_value >= 2
            @test selected_value <= 4
            @test selected_value != 3
        end
    end

    @testset "BasicHeuristic reproducibility" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        rng = Random.MersenneTwister(42)
        heuristic = SeaPearl.RandomHeuristic(rng)

        x = SeaPearl.IntVar(2, 6, "x", trailer)

        @test heuristic.selectValue(x) == 5
        @test heuristic.selectValue(x) == 3
        @test heuristic.selectValue(x) == 5
        @test heuristic.selectValue(x) == 3
        @test heuristic.selectValue(x) == 3
        @test heuristic.selectValue(x) == 6
        @test heuristic.selectValue(x) == 2
        @test heuristic.selectValue(x) == 6
        @test heuristic.selectValue(x) == 6
        @test heuristic.selectValue(x) == 3
    end
end
struct TsptwVariableSelection{TakeObjective} <: SeaPearl.AbstractVariableSelection{TakeObjective} end

TsptwVariableSelection(;take_objective=false) = TsptwVariableSelection{take_objective}()

function (::TsptwVariableSelection{false})(cpmodel::SeaPearl.CPModel; rng=nothing)
    for i in 1:length(keys(cpmodel.variables))
        if haskey(cpmodel.variables, "a_"*string(i)) && !SeaPearl.isbound(cpmodel.variables["a_"*string(i)])
            return cpmodel.variables["a_"*string(i)]
        end
    end
    println(cpmodel.variables)
end

@testset "tsptw.jl" begin
    @testset "fill_with_generator!" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        n_city = 10
        grid_size = 5
        max_tw_gap = 1
        max_tw = 1

        generator = SeaPearl.TsptwGenerator(n_city, grid_size, max_tw_gap, max_tw)

        SeaPearl.fill_with_generator!(model, generator; seed=52)

        # @test length(keys(model.variables)) == 2 * n_city^2 + 10 * n_city + 1
        # @test length(model.constraints) == 4 + 4*(n_city-1) + 4*n_city + 3*n_city^2
        empty!(model)
    end
    @testset "Search instance" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        n_city = 20
        grid_size = 150
        max_tw_gap = 3
        max_tw = 3

        generator = SeaPearl.TsptwGenerator(n_city, grid_size, max_tw_gap, max_tw)

        dist, time_windows, x_pos, y_pos = SeaPearl.fill_with_generator!(model, generator; seed=55)

        variableheuristic = TsptwVariableSelection{false}()
        my_heuristic(x::SeaPearl.IntVar) = minimum(x.domain)
        valueheuristic = SeaPearl.BasicHeuristic(my_heuristic)

        SeaPearl.search!(model, SeaPearl.DFSearch, variableheuristic, valueheuristic)

        println("dist", dist)
        println("time_windows", time_windows)

        @test dist == [0 65 43 90 16 90 134 51 58 37 116 138 54 115 122 75 95 11 89 97; 65 0 99 61 80 61 104 53 122 29 110 167 12 126 105 49 116 57 86 142; 43 99 0 100 38 100 135 60 44 76 104 102 87 92 116 87 69 54 81 55; 90 61 100 0 104 0 45 42 139 75 53 125 58 77 45 16 76 90 37 121; 16 80 38 104 0 104 147 64 43 51 125 139 69 121 133 89 100 24 99 93; 90 61 100 0 104 0 45 41 139 75 53 125 58 77 45 16 76 90 37 120; 134 104 135 45 147 45 0 83 178 120 46 126 103 77 27 61 89 135 55 141; 51 53 60 42 64 41 83 0 98 48 68 113 44 76 72 28 63 53 41 92; 58 122 44 139 43 139 178 98 0 94 148 137 112 135 160 125 112 66 125 83; 37 29 76 75 51 75 120 48 94 0 115 158 21 124 115 60 109 28 88 125; 116 110 104 53 125 53 46 68 148 115 0 81 104 31 19 61 45 120 27 98; 138 167 102 125 139 125 126 113 137 158 81 0 157 50 100 125 51 148 88 55; 54 12 87 58 69 58 103 44 112 21 104 157 0 118 102 45 106 47 79 131; 115 126 92 77 121 77 77 76 135 124 31 50 118 0 51 80 23 122 41 71; 122 105 116 45 133 45 27 72 160 115 19 100 102 51 0 57 63 125 35 116; 75 49 87 16 89 16 61 28 125 60 61 125 45 80 57 0 74 75 39 114; 95 116 69 76 100 76 89 63 112 109 45 51 106 23 63 74 0 103 39 53; 11 57 54 90 24 90 135 53 66 28 120 148 47 122 125 75 103 0 93 108; 89 86 81 37 99 37 55 41 125 88 27 88 79 41 35 39 39 93 0 88; 97 142 55 121 93 120 141 92 83 125 98 55 131 71 116 114 53 108 88 0]
        @test time_windows == [0 10; 1019 1020; 1333 1336; 1436 1438; 938 938; 833 833; 181 182; 265 268; 366 366; 1710 1712; 134 137; 1186 1189; 1494 1494; 1239 1242; 528 530; 588 591; 1601 1604; 11 11; 794 795; 703 703]

        # @test model.solutions[end]["a_1"] == 3
        # @test model.solutions[end]["a_2"] == 5
        # @test model.solutions[end]["a_3"] == 4
        # @test model.solutions[end]["a_4"] == 2
        # @test model.solutions[end]["c_5"] == 325

        @test length(model.solutions) >= 1

        println("nodes: ", model.statistics.numberOfNodes)

        # # println("model.solutions", model.solutions)
        # for i in 1:(n_city-1)
        #     println("a_"*string(i)*": ", model.solutions[end]["a_"*string(i)])
        # end
        # println("c_"*string(n_city)*": ", model.solutions[end]["c_"*string(n_city)])
    end
end
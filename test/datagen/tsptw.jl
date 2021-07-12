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

        foundDist, foundTW, foundPos, foundgrid_size = model.adhocInfo

        # This condition is there because of the way random are generated can change from one version to another
        if VERSION >= v"1.6.0"
            @test foundDist == [0 4 2 3 3 3 3 3 2 4; 
                                4 0 2 1 3 3 1 3 4 2; 
                                2 2 0 0 3 3 1 3 3 3; 
                                3 1 0 0 3 3 1 3 3 3; 
                                3 3 3 3 0 1 3 0 1 3; 
                                3 3 3 3 1 0 3 1 2 2; 
                                3 1 1 1 3 3 0 3 3 2; 
                                3 3 3 3 0 1 3 0 1 3; 
                                2 4 3 3 1 2 3 1 0 4; 
                                4 2 3 3 3 2 2 3 4 0]
            @test foundTW == [0 10; 23 23; 25 26; 17 18; 12 13; 20 21; 15 15; 28 29; 10 11; 5 6]
        end
        @test foundgrid_size == grid_size

        @test length(keys(model.variables)) == 2 * n_city^2 + 11 * n_city - 2
        @test length(model.constraints) == 3*n_city^2 + 10 * n_city - 4
        @test model.objective == model.variables["total_cost"]
        empty!(model)
    end
    @testset "Search known instance" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        n_city = 21
        grid_size = 150
        max_tw_gap = 3
        max_tw = 8

        generator = SeaPearl.TsptwGenerator(n_city, grid_size, max_tw_gap, max_tw)

        dist = [0 19 17 34 7 20 10 17 28 15 23 29 23 29 21 20 9 16 21 13 12;
        19 0 10 41 26 3 27 25 15 17 17 14 18 48 17 6 21 14 17 13 31;
        17 10 0 47 23 13 26 15 25 22 26 24 27 44 7 5 23 21 25 18 29;
        34 41 47 0 36 39 25 51 36 24 27 38 25 44 54 45 25 28 26 28 27;
        7 26 23 36 0 27 11 17 35 22 30 36 30 22 25 26 14 23 28 20 10;
        20 3 13 39 27 0 26 27 12 15 14 11 15 49 20 9 20 11 14 11 30;
        10 27 26 25 11 26 0 26 31 14 23 32 22 25 31 28 6 17 21 15 4;
        17 25 15 51 17 27 26 0 39 31 38 38 38 34 13 20 26 31 36 28 27;
        28 15 25 36 35 12 31 39 0 17 9 2 11 56 32 21 24 13 11 15 35;
        15 17 22 24 22 15 14 31 17 0 9 18 8 39 29 21 8 4 7 4 18;
        23 17 26 27 30 14 23 38 9 9 0 11 2 48 33 23 17 7 2 10 27;
        29 14 24 38 36 11 32 38 2 18 11 0 13 57 31 20 25 14 13 17 36;
        23 18 27 25 30 15 22 38 11 8 2 13 0 47 34 24 16 7 2 10 26;
        29 48 44 44 22 49 25 34 56 39 48 57 47 0 46 48 31 42 46 40 21;
        21 17 7 54 25 20 31 13 32 29 33 31 34 46 0 11 29 28 32 25 33;
        20 6 5 45 26 9 28 20 21 21 23 20 24 48 11 0 23 19 22 17 32;
        9 21 23 25 14 20 6 26 24 8 17 25 16 31 29 23 0 11 15 9 10;
        16 14 21 28 23 11 17 31 13 4 7 14 7 42 28 19 11 0 5 3 21;
        21 17 25 26 28 14 21 36 11 7 2 13 2 46 32 22 15 5 0 8 25;
        13 13 18 28 20 11 15 28 15 4 10 17 10 40 25 17 9 3 8 0 19;
        12 31 29 27 10 30 4 27 35 18 27 36 26 21 33 32 10 21 25 19 0]

        timeWindows = [0         408;
        62        68;
        181       205;
        306       324;
        214       217;
        51        61;
        102       129;
        175       186;
        250       263;
        3         23;
        21        49;
        79        90;
        78        96;
        140       154;
        354       386;
        42        63;
        2         13;
        24        42;
        20        33;
        9         21;
        275       300]

        dist, timeWindows = SeaPearl.fill_with_generator!(model, generator; dist=dist, timeWindows=timeWindows)

        foundDist, foundTW, foundPos, foundgrid_size = model.adhocInfo

        @test foundDist == dist
        @test foundTW == timeWindows
        @test foundgrid_size == grid_size

        variableheuristic = TsptwVariableSelection{false}()
        my_heuristic(x::SeaPearl.IntVar; cpmodel=nothing) = minimum(x.domain)
        valueheuristic = SeaPearl.BasicHeuristic(my_heuristic)

        SeaPearl.search!(model, SeaPearl.DFSearch(), variableheuristic, valueheuristic)

        # println("dist", dist)
        # println("timeWindows", timeWindows)

        @test model.statistics.numberOfSolutions >= 1

        # println("nodes: ", model.statistics.numberOfNodes)

        solution_found = Int[]
        for i in 1:(n_city-1)
            push!(solution_found, unique!(model.statistics.solutions)[end]["a_"*string(i)])
        end

        # From: http://www.hakank.org/minizinc/tsptw.mzn
        @test solution_found == [17,10,20,18,19,11,6,16,2,12,13,7,14,8,3,5,9,21,4,15]
        @test model.statistics.solutions[end]["total_cost"] == 378

        # for i in 1:(n_city-1)
        #     println("a_"*string(i)*": ", model.statistics.solution[end]["a_"*string(i)])
        #     println("c_"*string(i)*": ", model.statistics.solutions[end]["c_"*string(i)])
        #     println("d_"*string(i)*": ", model.statistics.solutions[end]["d_"*string(i)])
        #     println("v_"*string(i)*": ", model.statistics.solutions[end]["v_"*string(i)])
        #     println("dist[v[i], a[i]]: ", dist[model.statistics.solution[end]["v_"*string(i)], model.statistics.solution[end]["a_"*string(i)]])
        # end
        # println("total_cost: ", model.statistics.solution[end]["total_cost"])
        # println("c_21: ", model.statistics.solution[end]["c_21"])
    end
    @testset "Search known instance" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        n_city = 21
        grid_size = 150
        max_tw_gap = 3
        max_tw = 8

        generator = SeaPearl.TsptwGenerator(n_city, grid_size, max_tw_gap, max_tw)

        dist, timeWindows = SeaPearl.fill_with_generator!(model, generator; seed=42)

        variableheuristic = TsptwVariableSelection{false}()
        my_heuristic(x::SeaPearl.IntVar; cpmodel=nothing) = minimum(x.domain)
        valueheuristic = SeaPearl.BasicHeuristic(my_heuristic)

        SeaPearl.search!(model, SeaPearl.DFSearch(), variableheuristic, valueheuristic)

        #TODO findout why sometimes no solution are found in the randomly generated problem  
        @test length(model.statistics.solutions) >= 1
    end
    @testset "find_tsptw_dist_matrix()" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        n_city = 21
        grid_size = 150
        max_tw_gap = 3
        max_tw = 8

        generator = SeaPearl.TsptwGenerator(n_city, grid_size, max_tw_gap, max_tw)

        dist, timeWindows = SeaPearl.fill_with_generator!(model, generator; seed=42)

        @test SeaPearl.find_tsptw_dist_matrix(model) == dist

        model2 = SeaPearl.CPModel(trailer)
        @test_throws ErrorException SeaPearl.find_tsptw_dist_matrix(model2)
    end

end
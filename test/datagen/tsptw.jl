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

        n_city = 5
        grid_size = 150
        max_tw_gap = 3
        max_tw = 3

        generator = SeaPearl.TsptwGenerator(n_city, grid_size, max_tw_gap, max_tw)

        dist, time_windows, x_pos, y_pos = SeaPearl.fill_with_generator!(model, generator; seed=55)

        variableheuristic = TsptwVariableSelection{false}()
        my_heuristic(x::SeaPearl.IntVar) = minimum(x.domain)
        valueheuristic = SeaPearl.BasicHeuristic(my_heuristic)

        SeaPearl.search!(model, SeaPearl.DFSearch, variableheuristic, valueheuristic)

        # println("dist", dist)
        # println("time_windows", time_windows)

        @test dist == [0 47 37 119 74; 47 0 73 148 120; 37 73 0 82 55; 119 148 82 0 85; 74 120 55 85 0]
        @test time_windows == [0 10; 330 333; 37 37; 181 182; 95 98]

        @test model.solutions[end]["a_1"] == 3
        @test model.solutions[end]["a_2"] == 5
        @test model.solutions[end]["a_3"] == 4
        @test model.solutions[end]["a_4"] == 2
        @test model.solutions[end]["c_5"] == 325

        @test length(model.solutions) == 1

        println("nodes: ", model.statistics.numberOfNodes)

        # # println("model.solutions", model.solutions)
        # for i in 1:(n_city-1)
        #     println("a_"*string(i)*": ", model.solutions[end]["a_"*string(i)])
        # end
        # println("c_"*string(n_city)*": ", model.solutions[end]["c_"*string(n_city)])
    end
end
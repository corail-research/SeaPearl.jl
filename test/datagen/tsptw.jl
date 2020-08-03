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

        n_city = 3
        grid_size = 10
        max_tw_gap = 5
        max_tw = 10

        generator = SeaPearl.TsptwGenerator(n_city, grid_size, max_tw_gap, max_tw)

        SeaPearl.fill_with_generator!(model, generator; seed=52)

        # @test length(keys(model.variables)) == 2 * n_city^2 + 10 * n_city + 1
        # @test length(model.constraints) == 4 + 4*(n_city-1) + 4*n_city + 3*n_city^2
        empty!(model)
    end
    @testset "Search instance" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        n_city = 4
        grid_size = 10
        max_tw_gap = 5
        max_tw = 10

        generator = SeaPearl.TsptwGenerator(n_city, grid_size, max_tw_gap, max_tw)

        dist, time_windows, x_pos, y_pos = SeaPearl.fill_with_generator!(model, generator; seed=52)

        variableheuristic = TsptwVariableSelection{false}()
        my_heuristic(x::SeaPearl.IntVar) = minimum(x.domain)
        valueheuristic = SeaPearl.BasicHeuristic(my_heuristic)

        # println("model", model)
        println()
        println()
        println()
        println()
        SeaPearl.search!(model, SeaPearl.DFSearch, variableheuristic, valueheuristic)
        # println("model", model)

        println("dist", dist)
        println("time_windows", time_windows)
        println("x_pos", x_pos)
        println("y_pos", y_pos)

        

        @test length(model.solutions) == 1

        println("model.solutions", model.solutions)
        for i in 1:(n_city-1)
            println("a_"*string(i)*": ", model.solutions[1]["a_"*string(i)])
        end
    end
end
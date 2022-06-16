@testset "maxcut.jl" begin
    @testset "fill_with_generator!(::MaxCutGenerator)" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        n = 4
        k = 3

        generator = SeaPearl.MaxCutGenerator(n, k)

        rng = MersenneTwister(42)
        SeaPearl.fill_with_generator!(model, generator; rng=rng)

        # The generated graph should be 
        #            2   
        #            |
        #       1 -- 4 -- 3
        # Therefore, the best solution is {4} and {1, 2, 3}

        @test length(keys(model.variables)) == n + 3 + 1 # 1 var per node + 1 var per edge + the contraint var
        @test length(model.constraints) == 2 * 3 + 1 # 2 constraint per edge + the objective constraint
        @test minimum(model.objective.domain) == -3 
        @test maximum(model.objective.domain) == 0

        variableheuristic = SeaPearl.RandomVariableSelection(; take_objective=false)
        valueheuristic = SeaPearl.RandomHeuristic()

        SeaPearl.search!(model, SeaPearl.DFSearch(), variableheuristic, valueheuristic)

        @test model.statistics.numberOfSolutions >= 1
        
        solutions = model.statistics.solutions[model.statistics.solutions.!=nothing]
        solution_found = Int[]
        for i in 1:4
            push!(solution_found, solutions[end]["node_"*string(i)])
        end

        @test solution_found == [1, 1, 1, 0] || solution_found == [0, 0, 0, 1]
        @test solutions[end]["objective"] == -3
    end
end
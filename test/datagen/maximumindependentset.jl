@testset "maximumindependentset.jl" begin
    @testset "fill_with_generator!(::MaximumIndependentSetGenerator)" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        n = 4
        k = 3

        generator = SeaPearl.MaximumIndependentSetGenerator(n, k)

        rng = MersenneTwister(42)
        SeaPearl.fill_with_generator!(model, generator; rng=rng)

        # The generated graph should be 
        #            2   
        #            |
        #       1 -- 4 -- 3
        # Therefore, the best solution is unique and consists in choosing {1, 2, 3}

        @test length(keys(model.variables)) == n + 1 # the number of nodes + the objective
        @test length(model.constraints) == 3 + 1 # the number of edges + the objective constraint

        variableheuristic = SeaPearl.RandomVariableSelection()
        valueheuristic = SeaPearl.RandomHeuristic()

        SeaPearl.search!(model, SeaPearl.DFSearch(), variableheuristic, valueheuristic)

        @test model.statistics.numberOfSolutions >= 1
        
        solutions = model.statistics.solutions[model.statistics.solutions.!=nothing]
        solution_found = Int[]
        for i in 1:4
            push!(solution_found, solutions[end]["node_"*string(i)])
        end
        
        @test solution_found == [1, 1, 1, 0]
        @test solutions[end]["objective"] == -3
    end
end
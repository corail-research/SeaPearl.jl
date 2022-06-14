@testset "latin.jl" begin
    @testset "fill_with_generator!" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        N = 50
        p = 0.3
        generator = SeaPearl.LatinGenerator(N, p)

        rng = MersenneTwister(42)
        SeaPearl.fill_with_generator!(model, generator; rng=rng)

        @test length(keys(model.variables)) == N^2 
        @test length(model.constraints) == 2*N + 49 #row/col constraints + initially fixed variables 


        variableheuristic = SeaPearl.RandomVariableSelection()
        valueheuristic = SeaPearl.RandomHeuristic()

        SeaPearl.search!(model, SeaPearl.DFSearch(), variableheuristic, valueheuristic)

        @test model.statistics.numberOfSolutions >= 1
        
        solutions = model.statistics.solutions[model.statistics.solutions.!=nothing]
        @test solution_found == [1, 1, 1, 0]

    end 
end 
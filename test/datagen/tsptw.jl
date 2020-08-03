@testset "tsptw.jl" begin
    @testset "fill_with_generator!" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        n_city = 3
        grid_size = 40
        max_tw_gap = 5
        max_tw = 10

        generator = SeaPearl.TsptwGenerator(n_city, grid_size, max_tw_gap, max_tw)

        SeaPearl.fill_with_generator!(model, generator; seed=52)

        @test length(keys(model.variables)) == 2 * n_city^2 + 10 * n_city + 1
        @test length(model.constraints) == 4 + 6*(n_city-1) + 2*n_city + 3*n_city^2
        empty!(model)
    end
    @testset "Search instance" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        n_city = 3
        grid_size = 40
        max_tw_gap = 5
        max_tw = 10

        generator = SeaPearl.TsptwGenerator(n_city, grid_size, max_tw_gap, max_tw)

        SeaPearl.fill_with_generator!(model, generator; seed=52)

        variableheuristic = SeaPearl.MinDomainVariableSelection{false}()
        my_heuristic(x::SeaPearl.IntVar) = minimum(x.domain)
        valueheuristic = SeaPearl.BasicHeuristic(my_heuristic)

        SeaPearl.search!(model, SeaPearl.DFSearch, variableheuristic, valueheuristic)

        @test model.solutions == []
    end
end
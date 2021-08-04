@testset "environment.jl" begin
    
    @testset "CPEnv{TS}" begin
        graph = Matrix(adjacency_matrix(random_regular_graph(6, 3)))
        ts = SeaPearl.DefaultTrajectoryState(SeaPearl.FeaturedGraph(graph; nf=rand(3, 6)), 1)
        env = SeaPearl.CPEnv{SeaPearl.DefaultTrajectoryState}(
            .0, 
            false, 
            ts, 
            collect(1:4), 
            [1, 4], 
            [true, false, false, true]
        )

        Random.seed!(0)
        actions = Set([agent(env) for I = 1:10])

        @test actions == Set([1,4])
    end
end
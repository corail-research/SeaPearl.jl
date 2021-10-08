@testset "tsptwtrajectorystate.jl" begin
    
    @testset "TsptwTrajectoryState" begin
        graph = Matrix(adjacency_matrix(random_regular_graph(6,3)))
        ts1 = SeaPearl.TsptwTrajectoryState(
            SeaPearl.FeaturedGraph(graph; nf=rand(3,6)),
            2,
            collect(3:6)
        )

        @test isa(ts1, SeaPearl.GraphTrajectoryState)
    end
end
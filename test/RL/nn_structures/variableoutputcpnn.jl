@testset "variableoutputcpnn.jl" begin
    
    @testset "VariableOutputCPNN" begin
        modelNN = SeaPearl.VariableOutputCPNN(
            graphChain = Flux.Chain(
                SeaPearl.GraphConv(3 => 3),
                SeaPearl.GraphConv(3 => 3),
            ),
            nodeChain = Flux.Chain(
                Flux.Dense(3, 3),
                Flux.Dense(3, 3),
            ),
            outputChain = Flux.Chain(
                Flux.Dense(6, 1)
            )
        )

        graphs = Matrix.(LightGraphs.adjacency_matrix.([LightGraphs.random_regular_graph(10, 4) for i = 1:4]))
        nodeFeatures = [rand(3, 10) for i = 1:4]
        featuredGraphs = [SeaPearl.FeaturedGraph(g; nf=nf) for (g, nf) in zip(graphs, nodeFeatures)]

        trajectoryVector = SeaPearl.TsptwTrajectoryState.(featuredGraphs, rand(1:10, 4), [rand(1:10, rand(1:5)) for i = 1:4])
        actionSize = map(ts -> length(ts.possibleValuesIdx), trajectoryVector)
        nnInput = trajectoryVector |> cpu

        output = modelNN.(nnInput)

        @test all(length.(output) .== actionSize)
    end
end
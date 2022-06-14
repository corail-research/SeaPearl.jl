@testset "variableoutputcpnn.jl" begin
    
    @testset "VariableOutputCPNN on DefaultStateRepresentation" begin
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
        variableIndices = [1,3,4,7]
        allValuesIndices = [Vector(1:5) for i = 1:4]
        possibleValuesIndices = [[1,2,4],[4,2,3,1,5],[2],[5,3]]
        trajectoryVector = SeaPearl.DefaultTrajectoryState.(featuredGraphs, variableIndices, allValuesIndices, possibleValuesIndices)
        
        nnInput = trajectoryVector |> cpu
        
        output = modelNN(nnInput)

        @test size(output) == (length(allValuesIndices[1]), length(allValuesIndices))
        
        inf_indices = [
            CartesianIndex(3,1), CartesianIndex(5,1), 
            CartesianIndex(1,3), CartesianIndex(3,3), CartesianIndex(4,3), CartesianIndex(5,3),
            CartesianIndex(1,4), CartesianIndex(2,4), CartesianIndex(4,4)
            ]
        @test all(output[inf_indices] .== -Inf)

        float_indices = [
            CartesianIndex(1,1), CartesianIndex(2,1), CartesianIndex(4,1),
            CartesianIndex(1,2), CartesianIndex(2,2), CartesianIndex(3,2), CartesianIndex(4,2), CartesianIndex(5,2),
            CartesianIndex(2,3),
            CartesianIndex(3,4), CartesianIndex(5,4)
            ]
        @test all(output[float_indices] .!= -Inf)
    end
end
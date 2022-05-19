@testset "cpnn.jl" begin

    @testset "CPNN w/o global features" begin 
        modelNN = SeaPearl.CPNN(
            graphChain = Flux.Chain(
                SeaPearl.GraphConv(3 => 3),
                SeaPearl.GraphConv(3 => 3),
            ),
            nodeChain = Flux.Chain(
                Flux.Dense(3, 3),
                Flux.Dense(3, 3),
            ),
            outputChain = Flux.Chain(
                Flux.Dense(3, 2)
            )
        )

        graphs = Matrix.(adjacency_matrix.([random_regular_graph(10, 4) for i = 1:4]))
        nodeFeatures = [rand(3, 10) for i = 1:4]
        featuredGraphs = [SeaPearl.FeaturedGraph(g; nf=nf) for (g, nf) in zip(graphs, nodeFeatures)]

        actionSpace = [rand(1:10, 3) for i = 1:4]
        possibleactionSpace = [rand(1:3, 3) for i = 1:4]

        trajectoryVector = SeaPearl.DefaultTrajectoryState.(featuredGraphs, rand(1:10, 4), actionSpace, possibleactionSpace)
        nnInput = trajectoryVector |> cpu

        output = modelNN(nnInput)

        @test size(output) == (2, 4)

        grad = gradient(nnInput) do inp
            modelNN(inp)[2,2]
        end
        grad = grad[1]

        @test isnothing(grad.allValuesIdx)
        @test isnothing(grad.variableIdx)
        @test isnothing(grad.fg.ef)
        @test isnothing(grad.fg.gf)
        @test all(grad.fg.nf[:, :, [1, 3, 4]] .== 0)
        @test !all(grad.fg.nf[:, :, 2] .== 0)
        @test all(grad.fg.graph[:, :, [1, 3, 4]] .== 0)
        @test !all(grad.fg.graph[:, :, 2] .== 0)
    end

    @testset "CPNN w/ global features" begin
        modelNN = SeaPearl.CPNN(
            graphChain = Flux.Chain(
                SeaPearl.GraphConv(3 => 3),
                SeaPearl.GraphConv(3 => 3),
            ),
            nodeChain = Flux.Chain(
                Flux.Dense(3, 3),
                Flux.Dense(3, 3),
            ),
            globalChain = Flux.Chain(
                Flux.Dense(2, 3)
            ),
            outputChain = Flux.Chain(
                Flux.Dense(6, 2)
            ),
        )

        graphs = Matrix.(adjacency_matrix.([random_regular_graph(10, 4) for i = 1:4]))
        nodeFeatures = [rand(3, 10) for i = 1:4]
        globalFeatures = [rand(2) for i = 1:4]
        featuredGraphs = [SeaPearl.FeaturedGraph(g; nf=nf, gf=gf) for (g, nf, gf) in zip(graphs, nodeFeatures, globalFeatures)]

        actionSpace = [rand(1:10, 3) for i = 1:4]
        possibleactionSpace = [rand(1:3, 3) for i = 1:4]

        trajectoryVector = SeaPearl.DefaultTrajectoryState.(featuredGraphs, rand(1:10, 4), actionSpace, possibleactionSpace)
        nnInput = trajectoryVector |> cpu

        output = modelNN(nnInput)

        @test size(output) == (2, 4)

        grad = gradient(nnInput) do inp
            modelNN(inp)[2,2]
        end
        grad = grad[1]

        @test isnothing(grad.allValuesIdx)
        @test isnothing(grad.variableIdx)
        @test isnothing(grad.fg.ef)
        @test all(grad.fg.gf[:, [1, 3, 4]] .== 0)
        @test !all(grad.fg.gf[:, 2] .== 0)        
        @test all(grad.fg.nf[:, :, [1, 3, 4]] .== 0)
        @test !all(grad.fg.nf[:, :, 2] .== 0)
        @test all(grad.fg.graph[:, :, [1, 3, 4]] .== 0)
        @test !all(grad.fg.graph[:, :, 2] .== 0)
    end
end
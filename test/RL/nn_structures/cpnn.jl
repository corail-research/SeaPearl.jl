@testset "cpnn.jl" begin

    @testset "CPNN" begin 
        modelNN = SeaPearl.CPNN(
            graphChain = Flux.Chain(
                GeometricFlux.GraphConv(3 => 3),
                GeometricFlux.GraphConv(3 => 3),
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
        featuredGraphs = [FeaturedGraph(g; nf=nf) for (g, nf) in zip(graphs, nodeFeatures)]

        trajectoryVector = SeaPearl.DefaultTrajectoryState.(featuredGraphs, rand(1:10, 4))
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

    @testset "CPNN w/ nodeInputChain" begin 
        modelNN = SeaPearl.CPNN(
            nodeInputChain = Flux.Chain(
                Flux.Dense(2, 3)
            ),
            graphChain = Flux.Chain(
                GeometricFlux.GraphConv(3 => 3),
                GeometricFlux.GraphConv(3 => 3),
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
        nodeFeatures = [rand(2, 10) for i = 1:4]
        featuredGraphs = [FeaturedGraph(g; nf=nf) for (g, nf) in zip(graphs, nodeFeatures)]

        trajectoryVector = SeaPearl.DefaultTrajectoryState.(featuredGraphs, rand(1:10, 4))
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
                GeometricFlux.GraphConv(3 => 3),
                GeometricFlux.GraphConv(3 => 3),
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
        featuredGraphs = [FeaturedGraph(g; nf=nf, gf=gf) for (g, nf, gf) in zip(graphs, nodeFeatures, globalFeatures)]

        trajectoryVector = SeaPearl.DefaultTrajectoryState.(featuredGraphs, rand(1:10, 4))
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
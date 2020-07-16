@testset "flexGNN.jl" begin

    @testset "constructor" begin 

        model = CPRL.FlexGNN(
            graphChain = Flux.Chain(
                GeometricFlux.GCNConv(3 => 3),
                GeometricFlux.GCNConv(3 => 3),
            ),
            nodeChain = Flux.Chain(
                Flux.Dense(3, 3),
                Flux.Dense(3, 3),
            ),
            outputLayer = Flux.Dense(3, 2)
        )

        @test isa(model.graphChain, Flux.Chain)
        @test isa(model.nodeChain, Flux.Chain)

        @test isa(model.graphChain[1], GeometricFlux.GCNConv)
        @test isa(model.nodeChain[1], Flux.Dense)

        fg_array = [1 0 1 1 0 1.5 2.3 1.1 0 0
                    1 1 0 1 0 0.3 1.1 2.5 1 0
                    1 1 0 0 1 4.2 0.6 0.3 0 1
                    1 0 0 0 1 0.1 0.8 1.6 0 1]
        fg_array = convert(Array{Float32, 2}, fg_array)

        @test size(model(fg_array)) == (2,)

        

    end

end
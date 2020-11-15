@testset "fixed_output_gcn.jl" begin 

    @testset "ArgsFixedOutputGCN constructor" begin

        args_foGCN = SeaPearl.ArgsFixedOutputGCN(
            maxDomainSize = 10,
            numInFeatures = 5,
            firstHiddenGCN = 20,
            secondHiddenGCN = 20,
            hiddenDense = 20
        )

        @test args_foGCN.maxDomainSize == 10
        @test args_foGCN.numInFeatures == 5
        @test args_foGCN.firstHiddenGCN == 20
        @test args_foGCN.secondHiddenGCN == 20
        @test args_foGCN.hiddenDense == 20

    end

    @testset "FixedOutputGCN constructor" begin

        args_foGCN = SeaPearl.ArgsFixedOutputGCN(
            maxDomainSize = 10,
            numInFeatures = 5,
            firstHiddenGCN = 20,
            secondHiddenGCN = 20,
            hiddenDense = 20
        )

        foGCN = SeaPearl.FixedOutputGCN(
            firstGCNHiddenLayer = GeometricFlux.GCNConv(10 => 10, Flux.relu),
            secondGCNHiddenLayer = GeometricFlux.GCNConv(10 => 10, Flux.relu),
            denseLayer = Flux.Dense(10, 10, Flux.relu),
            outputLayer = Flux.Dense(10, 10, Flux.relu)
        )

        # @test typeof(foGCN.firstGCNHiddenLayer) == GeometricFlux.GCNConv{Float32,typeof(relu), GeometricFlux.FeaturedGraph{Nothing,Nothing}}
        # @test typeof(foGCN.secondGCNHiddenLayer) == GeometricFlux.GCNConv{Float32,typeof(relu), GeometricFlux.FeaturedGraph{Nothing,Nothing}}
        @test typeof(foGCN.denseLayer) == Flux.Dense{typeof(relu),Array{Float32,2},Array{Float32,1}}
        @test typeof(foGCN.outputLayer) == Flux.Dense{typeof(relu),Array{Float32,2},Array{Float32,1}}

    end

    @testset "build_model()" begin

        args_foGCN = SeaPearl.ArgsFixedOutputGCN(
            maxDomainSize = 10,
            numInFeatures = 5,
            firstHiddenGCN = 20,
            secondHiddenGCN = 20,
            hiddenDense = 20
        )

        foGCN = SeaPearl.build_model(SeaPearl.FixedOutputGCN, args_foGCN)

        # @test typeof(foGCN.firstGCNHiddenLayer) == GeometricFlux.GCNConv{Float32,typeof(relu), GeometricFlux.FeaturedGraph{Nothing,Nothing}}
        # @test typeof(foGCN.secondGCNHiddenLayer) == GeometricFlux.GCNConv{Float32,typeof(relu), GeometricFlux.FeaturedGraph{Nothing,Nothing}}
        @test typeof(foGCN.denseLayer) == Flux.Dense{typeof(relu),Array{Float32,2},Array{Float32,1}}
        @test typeof(foGCN.outputLayer) == Flux.Dense{typeof(identity),Array{Float32,2},Array{Float32,1}}

    end

    @testset "FixedOutputGCN as function" begin

        args_foGCN = SeaPearl.ArgsFixedOutputGCN(
            maxDomainSize = 2,
            numInFeatures = 3,
            firstHiddenGCN = 20,
            secondHiddenGCN = 6,
            hiddenDense = 6
        )

        foGCN = SeaPearl.build_model(SeaPearl.FixedOutputGCN, args_foGCN)

        # constructing a CPGraph
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        x = SeaPearl.IntVar(2, 3, "x", trailer)
        y = SeaPearl.IntVar(2, 3, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        push!(model.constraints, SeaPearl.Equal(x, y, trailer))
        push!(model.constraints, SeaPearl.NotEqual(x, y, trailer))

        dsr = SeaPearl.DefaultStateRepresentation(model)
        SeaPearl.update_representation!(dsr, model, x)

        X = SeaPearl.to_arraybuffer(dsr)

        q_values = foGCN(X)
        println("Q values vector :  ", q_values)

        @test size(q_values) == (2,)


    end

end
@testset "fixed_output_gcn.jl" begin 

    @testset "ArgsFixedOutputGCN constructor" begin

        args_foGCN = CPRL.ArgsFixedOutputGCN(
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

        args_foGCN = CPRL.ArgsFixedOutputGCN(
            maxDomainSize = 10,
            numInFeatures = 5,
            firstHiddenGCN = 20,
            secondHiddenGCN = 20,
            hiddenDense = 20
        )

        foGCN = CPRL.FixedOutputGCN(
            firstGCNHiddenLayer = GeometricFlux.GCNConv(10 => 10, Flux.relu),
            secondGCNHiddenLayer = GeometricFlux.GCNConv(10 => 10, Flux.relu),
            denseLayer = Flux.Dense(10, 10, Flux.relu),
            outputLayer = Flux.Dense(10, 10, Flux.relu)
        )

        @test typeof(foGCN.firstGCNHiddenLayer) == GeometricFlux.GCNConv{Float32,typeof(relu), GeometricFlux.FeaturedGraph{Nothing,Nothing}}
        @test typeof(foGCN.secondGCNHiddenLayer) == GeometricFlux.GCNConv{Float32,typeof(relu), GeometricFlux.FeaturedGraph{Nothing,Nothing}}
        @test typeof(foGCN.denseLayer) == Flux.Dense{typeof(relu),Array{Float32,2},Array{Float32,1}}
        @test typeof(foGCN.outputLayer) == Flux.Dense{typeof(relu),Array{Float32,2},Array{Float32,1}}

    end

    @testset "build_model()" begin

        args_foGCN = CPRL.ArgsFixedOutputGCN(
            maxDomainSize = 10,
            numInFeatures = 5,
            firstHiddenGCN = 20,
            secondHiddenGCN = 20,
            hiddenDense = 20
        )

        foGCN = CPRL.build_model(CPRL.FixedOutputGCN, args_foGCN)

        @test typeof(foGCN.firstGCNHiddenLayer) == GeometricFlux.GCNConv{Float32,typeof(relu), GeometricFlux.FeaturedGraph{Nothing,Nothing}}
        @test typeof(foGCN.secondGCNHiddenLayer) == GeometricFlux.GCNConv{Float32,typeof(relu), GeometricFlux.FeaturedGraph{Nothing,Nothing}}
        @test typeof(foGCN.denseLayer) == Flux.Dense{typeof(relu),Array{Float32,2},Array{Float32,1}}
        @test typeof(foGCN.outputLayer) == Flux.Dense{typeof(identity),Array{Float32,2},Array{Float32,1}}

    end

    @testset "FixedOutputGCN as function" begin

        args_foGCN = CPRL.ArgsFixedOutputGCN(
            maxDomainSize = 2,
            numInFeatures = 6,
            firstHiddenGCN = 20,
            secondHiddenGCN = 6,
            hiddenDense = 6
        )

        foGCN = CPRL.build_model(CPRL.FixedOutputGCN, args_foGCN)

        # constructing a CPGraph
        trailer = CPRL.Trailer()
        model = CPRL.CPModel(trailer)

        x = CPRL.IntVar(2, 3, "x", trailer)
        y = CPRL.IntVar(2, 3, "y", trailer)
        CPRL.addVariable!(model, x)
        CPRL.addVariable!(model, y)
        push!(model.constraints, CPRL.Equal(x, y, trailer))
        push!(model.constraints, CPRL.NotEqual(x, y, trailer))

        cpg = CPRL.CPGraph(model, x)

        X = CPRL.to_array(cpg)

        X = reshape(X, size(X)..., 1)

        q_values = foGCN(X)
        println("Q values vector :  ", q_values)

        @test size(q_values) == (1, 2, 1)


    end

end
@testset "fixed_output_gcn_lstm.jl" begin 

    @testset "ArgsFixedOutputGCNLSTM constructor" begin

        args_foGCNLSTM = CPRL.ArgsFixedOutputGCNLSTM(
            maxDomainSize = 10,
            numInFeatures = 5,
            firstHiddenGCN = 20,
            secondHiddenGCN = 20,
            hiddenDense = 20,
            lstmSize = 19
        )

        @test args_foGCNLSTM.maxDomainSize == 10
        @test args_foGCNLSTM.numInFeatures == 5
        @test args_foGCNLSTM.firstHiddenGCN == 20
        @test args_foGCNLSTM.secondHiddenGCN == 20
        @test args_foGCNLSTM.hiddenDense == 20
        @test args_foGCNLSTM.lstmSize == 19

    end

    @testset "FixedOutputGCNLSTM constructor" begin

        args_foGCNLSTM = CPRL.ArgsFixedOutputGCNLSTM(
            maxDomainSize = 10,
            numInFeatures = 5,
            firstHiddenGCN = 20,
            secondHiddenGCN = 20,
            hiddenDense = 20,
            lstmSize = 19
        )

        foGCNLSTM = CPRL.FixedOutputGCNLSTM(
            firstGCNHiddenLayer = GeometricFlux.GCNConv(10 => 10, Flux.relu),
            secondGCNHiddenLayer = GeometricFlux.GCNConv(10 => 10, Flux.relu),
            denseLayer = Flux.Dense(10, 10, Flux.relu),
            LSTMLayer = Flux.LSTM(10, 10),
            outputLayer = Flux.Dense(10, 10, Flux.relu)
        )

        @test typeof(foGCNLSTM.firstGCNHiddenLayer) == GeometricFlux.GCNConv{Float32,typeof(relu), GeometricFlux.FeaturedGraph{Nothing,Nothing}}
        @test typeof(foGCNLSTM.secondGCNHiddenLayer) == GeometricFlux.GCNConv{Float32,typeof(relu), GeometricFlux.FeaturedGraph{Nothing,Nothing}}
        @test typeof(foGCNLSTM.denseLayer) == Flux.Dense{typeof(relu),Array{Float32,2},Array{Float32,1}}
        @test typeof(foGCNLSTM.LSTMLayer) == Flux.Recur{Flux.LSTMCell{Array{Float32,2},Array{Float32,1}}}
        @test typeof(foGCNLSTM.outputLayer) == Flux.Dense{typeof(relu),Array{Float32,2},Array{Float32,1}}

    end

    @testset "build_model()" begin

        args_foGCNLSTM = CPRL.ArgsFixedOutputGCNLSTM(
            maxDomainSize = 10,
            numInFeatures = 5,
            firstHiddenGCN = 20,
            secondHiddenGCN = 20,
            hiddenDense = 20,
            lstmSize = 19
        )

        foGCNLSTM = CPRL.build_model(CPRL.FixedOutputGCNLSTM, args_foGCNLSTM)

        @test typeof(foGCNLSTM.firstGCNHiddenLayer) == GeometricFlux.GCNConv{Float32,typeof(relu), GeometricFlux.FeaturedGraph{Nothing,Nothing}}
        @test typeof(foGCNLSTM.secondGCNHiddenLayer) == GeometricFlux.GCNConv{Float32,typeof(relu), GeometricFlux.FeaturedGraph{Nothing,Nothing}}
        @test typeof(foGCNLSTM.denseLayer) == Flux.Dense{typeof(relu),Array{Float32,2},Array{Float32,1}}
        @test typeof(foGCNLSTM.LSTMLayer) == Flux.Recur{Flux.LSTMCell{Array{Float32,2},Array{Float32,1}}}
        @test typeof(foGCNLSTM.outputLayer) == Flux.Dense{typeof(identity),Array{Float32,2},Array{Float32,1}}

    end

    @testset "FixedOutputGCN as function" begin

        args_foGCNLSTM = CPRL.ArgsFixedOutputGCNLSTM(
            maxDomainSize = 2,
            numInFeatures = 3,
            firstHiddenGCN = 20,
            secondHiddenGCN = 20,
            hiddenDense = 20,
            lstmSize = 19
        )

        foGCNLSTM = CPRL.build_model(CPRL.FixedOutputGCNLSTM, args_foGCNLSTM)

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

        q_values = foGCNLSTM(X)
        println("Q values vector for LSTM :  ", q_values)

        @test size(q_values) == (1, 2, 1)

    end

end
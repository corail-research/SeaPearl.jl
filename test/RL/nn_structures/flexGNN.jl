@testset "flexGNN.jl" begin

    @testset "constructor" begin 

        modelNN = SeaPearl.FlexGNN(
            graphChain = Flux.Chain(
                GeometricFlux.GraphConv(3 => 3),
                GeometricFlux.GraphConv(3 => 3),
            ),
            nodeChain = Flux.Chain(
                Flux.Dense(3, 3),
                Flux.Dense(3, 3),
            ),
            outputLayer = Flux.Dense(3, 4)
        )

        @test isa(modelNN.graphChain, Flux.Chain)
        @test isa(modelNN.nodeChain, Flux.Chain)

        @test isa(modelNN.graphChain[1], GeometricFlux.GraphConv)
        @test isa(modelNN.nodeChain[1], Flux.Dense)

        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        x1 = SeaPearl.IntVar(1, 2, "x1", trailer)
        x2 = SeaPearl.IntVar(1, 2, "x2", trailer)
        x3 = SeaPearl.IntVar(2, 3, "x3", trailer)
        x4 = SeaPearl.IntVar(1, 4, "x4", trailer)
        SeaPearl.addVariable!(model, x1)
        SeaPearl.addVariable!(model, x2)
        SeaPearl.addVariable!(model, x3)
        SeaPearl.addVariable!(model, x4)

        push!(model.constraints, SeaPearl.NotEqual(x1, x2, trailer))
        push!(model.constraints, SeaPearl.NotEqual(x2, x3, trailer))
        push!(model.constraints, SeaPearl.NotEqual(x3, x4, trailer))

        stateRepresentation = SeaPearl.DefaultStateRepresentation(model)
        x = first(SeaPearl.values(SeaPearl.branchable_variables(model)))
        SeaPearl.update_representation!(stateRepresentation, model, x)
        batchedTrajectoryStateSingle =SeaPearl.trajectoryState(stateRepresentation)|> cpu

        @test size(modelNN(batchedTrajectoryStateSingle)) == (4, 1) #the flexGNN output is a matrix 

        trajectoryVector = [SeaPearl.trajectoryState(stateRepresentation),SeaPearl.trajectoryState(stateRepresentation)]
        batchedTrajectoryState =trajectoryVector|> cpu

        @test size(modelNN(batchedTrajectoryState)) == (4, 2) #the flexGNN output is a matrix 

    end

end
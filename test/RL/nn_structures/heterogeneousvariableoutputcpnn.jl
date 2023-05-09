@testset "heterogeneousvariableoutputcpnn.jl" begin
    
    @testset "heterogeneousVariableOutputCPNN on HeterogeneousStateRepresentation" begin
        modelNN = SeaPearl.HeterogeneousVariableOutputCPNN(
            graphChain = Flux.Chain(),
            nodeChain = Flux.Chain(
                Flux.Dense(4, 4),
                Flux.Dense(4, 4),
            ),
            outputChain = Flux.Chain(
                Flux.Dense(8, 1)
            )
        )

        contovar = Matrix([1 1])
        valtovar = Matrix([1 0
                           1 0
                           1 1
                           0 1])
        
        varnf = rand(4,2)
        connf = rand(4,1)
        valnf = rand(4,4)
        gf = rand(3)
        fg = SeaPearl.HeterogeneousFeaturedGraph(contovar, valtovar, varnf, connf, valnf, gf)
        
        var = 1 #out of bound variable
        val = [1,3]
        hts = SeaPearl.HeterogeneousTrajectoryState(fg, var, val)
        bhts = hts |> cpu  |> cpu 
        display(bhts.fg.valnf)
        output = modelNN(bhts)
        display(output)
        @test length(output) == size(valtovar,1)
        
        zero_indices = [2,4]
        @test all(output[zero_indices] .== 0)

        non_zero_indices = [1,3]
        @test all(output[non_zero_indices] .!= 0)
    end

    @testset "heterogeneousVariableOutputCPNN on BatchedHeterogeneousStateRepresentation" begin
        modelNN = SeaPearl.HeterogeneousVariableOutputCPNN(
            graphChain = Flux.Chain(),
            nodeChain = Flux.Chain(
                Flux.Dense(4, 4),
                Flux.Dense(4, 4),
            ),
            outputChain = Flux.Chain(
                Flux.Dense(8, 1)
            )
        )

        contovar = reshape([1,1,1,1], 1,2,2)
        display(contovar)
        valtovar = Array{Int64}(undef, (4,2,2))
        valtovar[:,:,1] = Matrix([1 0
                                  1 0
                                  1 1
                                  0 1])
        valtovar[:,:,2] = Matrix([1 0
                                  1 0
                                  1 1
                                  0 1])
        
        varnf = rand(4,2,2)
        connf = rand(4,1,2)
        valnf = rand(4,4,2)
        gf = rand(3,2)
        fg = SeaPearl.BatchedHeterogeneousFeaturedGraph(contovar, valtovar, varnf, connf, valnf, gf)
        
        var = [1,2] #out of bound variable
        val = [[1,2,3], [3]]
        hts = SeaPearl.BatchedHeterogeneousTrajectoryState(fg, var, val)
        bhts = hts |> cpu  |> cpu 
        display(bhts.fg.valnf)
        output = modelNN(bhts)
        display(output)
        @test size(output) == (size(valtovar,1), size(valtovar, 3))
        
        inf_indices = [
            CartesianIndex(4,1),  
            CartesianIndex(1,2), CartesianIndex(2,2), CartesianIndex(4,2)
            ]
        @test all(output[inf_indices] .== -Inf)

        float_indices = [
            CartesianIndex(1,1), CartesianIndex(2,1), CartesianIndex(3,1),
            CartesianIndex(3,2)
            ]
        @test all(output[float_indices] .!= -Inf)
    end
end
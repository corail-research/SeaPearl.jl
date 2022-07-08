"""
    HeterogeneousFFCPNNv5(;
        graphChain::Flux.Chain
        varChain::Flux.Chain = Flux.Chain()
        valChain::Flux.Chain = Flux.Chain()
        conChain::Flux.Chain = Flux.Chain()
        globalChain::Flux.Chain
        outputChain::Flux.Dense
    )

This structure is here to provide a flexible way to create a nn model which respect this approach:
Making modification on the graph, then extract one node feature and modify it. This CPNN is designed to process HeterogeneousFeaturedGraphs.

This pipeline works in the following way : 

1) We apply a GNN on the input featured graph.
2) We extract the contextualized-feature of the branching variable and pass it trought varChain
3) We extract the contextualized-feature of each value that is part of the variable's domain of definition and pass it trought valChain.
4) We concat the two reshaped previous results (*optionnaly* with a global feature) and pass it trought outputChain to generate the output Q-vector.
"""
Base.@kwdef struct HeterogeneousFFCPNNv5 <: NNStructure
    graphChain
    varChain::Flux.Chain = Flux.Chain()
    valChain::Flux.Chain = Flux.Chain()
    conChain::Flux.Chain = Flux.Chain()
    globalChain::Flux.Chain = Flux.Chain()
    outputChain::Union{Flux.Dense, Flux.Chain} = Flux.Chain()
    pooling::String = "sum"

    function HeterogeneousFFCPNNv5(graphChain, nodeChain::Flux.Chain = Flux.Chain(), globalChain::Flux.Chain = Flux.Chain(), outputChain::Union{Flux.Dense, Flux.Chain} = Flux.Chain(); pooling::String = "sum")
        @assert pooling in ["sum", "max", "mean"] "Argument 'pooling' must be in {'sum', 'max', 'mean'}."
        return new(graphChain, nodeChain, deepcopy(nodeChain), deepcopy(nodeChain), globalChain, outputChain, pooling)
    end
end

# Enable the `|> gpu` syntax from Flux
Flux.@functor HeterogeneousFFCPNNv5

function (nn::HeterogeneousFFCPNNv5)(states::BatchedHeterogeneousTrajectoryState)
    variableIdx = states.variableIdx
    batchSize = length(variableIdx)
    actionSpaceSize = size(states.fg.valnf, 2)
    
    # chain working on the graph(s) with the GNNs
    featuredGraph = nn.graphChain(states.fg)
    allVariableFeatures = featuredGraph.varnf # FxNxB
    constraintFeatures = featuredGraph.connf 
    valueFeatures = featuredGraph.valnf
    globalFeatures = featuredGraph.gf # GxB
    
    # Extract the features corresponding to the variables
    variableIndices = nothing
    Zygote.ignore() do
        variableIndices = Flux.unsqueeze(CartesianIndex.(variableIdx, 1:batchSize), 1)
    end

    variableFeatures = allVariableFeatures[:, variableIndices] # Fx1xB
    variableFeatures = reshape(nn.varChain(RL.flatten_batch(variableFeatures)), :, 1, batchSize) # F'x1xB
    valueFeatures = reshape(nn.valChain(RL.flatten_batch(valueFeatures)), :, actionSpaceSize, batchSize) # F'xAxB
    constraintFeatures = reshape(nn.conChain(RL.flatten_batch(constraintFeatures)), :, size(constraintFeatures, 2), batchSize) # F'x1xB
    #println("variableFeatures: ", size(variableFeatures))
    #println("valueFeatures: ", size(valueFeatures))
    #println("constraintFeatures: ", size(constraintFeatures))

    pooledVariableFeatures, pooledValueFeatures, pooledConstraintFeatures = nothing, nothing, nothing
    Zygote.ignore() do
        if nn.pooling == "sum"
            pooledVariableFeatures = reshape(mapslices(x -> sum(eachcol(x)), allVariableFeatures, dims=[1,2]), :, 1, batchSize)
            pooledConstraintFeatures = reshape(mapslices(x -> sum(eachcol(x)), constraintFeatures, dims=[1,2]), :, 1, batchSize)
            pooledValueFeatures = reshape(mapslices(x -> sum(eachcol(x)), valueFeatures, dims=[1,2]), :, 1, batchSize)
        elseif nn.pooling == "mean"
            pooledVariableFeatures = reshape(mapslices(x -> sum(eachcol(x)), allVariableFeatures, dims=[1,2]), :, 1, batchSize) / size(variableFeatures, 2)
            pooledConstraintFeatures = reshape(mapslices(x -> sum(eachcol(x)), constraintFeatures, dims=[1,2]), :, 1, batchSize) / size(constraintFeatures, 2)
            pooledValueFeatures = reshape(mapslices(x -> sum(eachcol(x)), valueFeatures, dims=[1,2]), :, 1, batchSize) / size(valueFeatures, 2)
        elseif nn.pooling == "max"
            pooledVariableFeatures = reshape(mapslices(x -> maximum(x), allVariableFeatures, dims=2), :, 1, batchSize) 
            pooledConstraintFeatures = reshape(mapslices(x -> maximum(x), constraintFeatures, dims=2), :, 1, batchSize) 
            pooledValueFeatures = reshape(mapslices(x -> maximum(x), valueFeatures, dims=2), :, 1, batchSize) 
        end
    end
    # println("pooledVariableFeatures: ", size(pooledVariableFeatures))
    # println("pooledConstraintFeatures: ", size(pooledConstraintFeatures))
    # println("pooledValueFeatures: ", size(pooledValueFeatures))
    
    finalFeatures = nothing
    if sizeof(globalFeatures) != 0
        mask = device(states) == Val(:gpu) ? CUDA.zeros(Float32, 1, actionSpaceSize, batchSize) : zeros(Float32, 1, actionSpaceSize, batchSize) # this mask will replace `reapeat` using broadcasted `+`
        # Extract the global features
        globalFeatures = reshape(nn.globalChain(globalFeatures), :, 1, batchSize) # G'x1xB
        #println("globalFeatures: ", size(globalFeatures))
        # Prepare the input of the outputChain
        finalFeatures = vcat(
            variableFeatures .+ mask, # F'xAxB
            globalFeatures .+ mask, # G'xAxB
            pooledVariableFeatures .+ mask, 
            pooledConstraintFeatures .+ mask,
            pooledValueFeatures .+ mask,
            valueFeatures,
        )
        println(size(finalFeatures))
        #=finalFeatures = hcat(
            variableFeatures, # F'x1xB
            valueFeatures, # F'xAxB
            globalFeatures, # G'x1xB
            pooledVariableFeatures, 
            pooledConstraintFeatures,
            pooledValueFeatures
        ) # F'x(A+6)xB=#
        finalFeatures = RL.flatten_batch(finalFeatures) # (F'+G'+F')x(A*B)
    else
        # Prepare the input of the outputChain
        mask = device(states) == Val(:gpu) ? CUDA.zeros(Float32, 1, actionSpaceSize, batchSize) : zeros(Float32, 1, actionSpaceSize, batchSize) # this mask will replace `reapeat` using broadcasted `+`
        #println("globalFeatures: ", size(globalFeatures))
        # Prepare the input of the outputChain
        finalFeatures = vcat(
            variableFeatures .+ mask, # F'xAxB
            pooledVariableFeatures .+ mask, 
            pooledConstraintFeatures .+ mask,
            pooledValueFeatures .+ mask,
            valueFeatures,
        )
        #finalFeatures = RL.flatten_batch(finalFeatures) # (F'+F')x(A*B)
    end
    #println("finalFeatures: ", size(finalFeatures))
    # output layer
    predictions = nn.outputChain(finalFeatures) # Ox(AxB)
    #println("predictions: ", size(predictions))
    #println("predictions: ", size(predictions[:, 1:actionSpaceSize, :]))
    #output = reshape(predictions[:, 1:actionSpaceSize, :], actionSpaceSize, batchSize) # OxAxB
    #println("output: ", size(output))
    output = reshape(predictions, actionSpaceSize, batchSize)
    return output
end

function (nn::HeterogeneousFFCPNNv5)(states::HeterogeneousTrajectoryState)
    variableIdx = states.variableIdx
    actionSpaceSize = size(states.fg.valnf, 2)
    mask = device(states) == Val(:gpu) ? CUDA.zeros(Float32, 1, actionSpaceSize) : zeros(Float32, 1, actionSpaceSize) # this mask will replace `reapeat` using broadcasted `+`

    # chain working on the graph(s) with the GNNs
    featuredGraph = nn.graphChain(states.fg)
    allVariableFeatures = featuredGraph.varnf # FxNxB
    constraintFeatures = featuredGraph.connf # FxN'xB
    valueFeatures = featuredGraph.valnf #FxN''xB
    globalFeatures = featuredGraph.gf # GxB
    #println("variableFeatures: ", size(variableFeatures))
    #println("constraintFeatures: ", size(constraintFeatures))
    #println("valueFeatures: ", size(valueFeatures))
    #println("globalFeatures: ", size(globalFeatures))
    
    # Extract the features corresponding to the varibales
    variableFeatures = allVariableFeatures[:, variableIdx] # Fx1
    variableFeatures = nn.varChain(variableFeatures) # F'x1
    constraintFeatures = nn.conChain(constraintFeatures) # F'x1
    valueFeatures = nn.valChain(valueFeatures) # F'xA
    

    pooledVariableFeatures, pooledValueFeatures, pooledConstraintFeatures = nothing, nothing, nothing
    Zygote.ignore() do
        if nn.pooling == "sum"
            pooledVariableFeatures = sum(eachcol(variableFeatures))
            pooledConstraintFeatures = sum(eachcol(constraintFeatures))
            pooledValueFeatures = sum(eachcol(valueFeatures))
        elseif nn.pooling == "mean"
            pooledVariableFeatures = sum(eachcol(variableFeatures)) / size(variableFeatures, 2)
            pooledConstraintFeatures = sum(eachcol(constraintFeatures)) / size(variableFeatures, 2)
            pooledValueFeatures = sum(eachcol(valueFeatures)) / size(variableFeatures, 2)
        elseif nn.pooling == "max"
            pooledVariableFeatures = reshape(mapslices(x -> maximum(x), variableFeatures, dims=2), :, 1, batchSize) 
            pooledConstraintFeatures = reshape(mapslices(x -> maximum(x), constraintFeatures, dims=2), :, 1, batchSize) 
            pooledValueFeatures = reshape(mapslices(x -> maximum(x), valueFeatures, dims=2), :, 1, batchSize) 
        end
    end
    #println("pooledVariableFeatures: ", size(pooledVariableFeatures))
    #println("pooledConstraintFeatures: ", size(pooledConstraintFeatures))
    #println("pooledValueFeatures: ", size(pooledValueFeatures))

    finalFeatures = nothing
    if sizeof(globalFeatures) != 0
        mask = device(states) == Val(:gpu) ? CUDA.zeros(Float32, 1, actionSpaceSize) : zeros(Float32, 1, actionSpaceSize) # this mask will replace `reapeat` using broadcasted `+`
        # Extract the global features
        globalFeatures = nn.globalChain(globalFeatures)
        #println("globalFeatures: ", size(globalFeatures))
        # Prepare the input of the outputChain
        finalFeatures = vcat(
            variableFeatures .+ mask, # F'xAxB
            globalFeatures .+ mask, # G'xAxB
            pooledVariableFeatures .+ mask, 
            pooledConstraintFeatures .+ mask,
            pooledValueFeatures .+ mask,
            valueFeatures,
        )
    else
        # Prepare the input of the outputChain
        mask = device(states) == Val(:gpu) ? CUDA.zeros(Float32, 1, actionSpaceSize) : zeros(Float32, 1, actionSpaceSize) # this mask will replace `reapeat` using broadcasted `+`
        finalFeatures = vcat(
            variableFeatures .+ mask, # F'xAxB
            pooledVariableFeatures .+ mask, 
            pooledConstraintFeatures .+ mask,
            pooledValueFeatures .+ mask,
            valueFeatures,
        )
    end
    #println("finalFeatures: ", size(finalFeatures))
    
    # output layer
    predictions = nn.outputChain(finalFeatures)# OxA
    #println("predictions: ")
    #display(predictions)
    return predictions
end



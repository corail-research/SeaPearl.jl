"""
    HeterogeneousFFCPNNv2(;
        graphChain::Flux.Chain
        globalChain::Flux.Chain
        outputChain::Flux.Dense
    )

This structure is here to provide a flexible way to create a nn model which respect this approach:
Making modification on the graph, then extract one node feature and modify it. This CPNN is designed to process HeterogeneousFeaturedGraphs.
It is a modified version of `HeterogeneousFullFeaturedCPNN``.
This pipeline works in the following way : 

1) We apply a GNN (`graphChain`) on the input featured graph.
2) We extract the features of the branching variable and the possible values (i.e. the values that are in the domain of the variable).
3) Optional: We extract the global features of the graph and pass it through `globalChain``.
4) We extract the respective poolings of the features of all the variables, all the values and all the constraints.
5) We concatenate horizontally the previous results and pass it trought `outputChain`` to generate the output Q-vector that we truncate to the first `actionSpaceSize` values.
"""
Base.@kwdef struct HeterogeneousFFCPNNv3 <: NNStructure
    graphChain
    globalChain::Flux.Chain = Flux.Chain()
    outputChain::Union{Flux.Dense, Flux.Chain} = Flux.Chain()
    pooling::String = "sum"

    function HeterogeneousFFCPNNv3(graphChain, globalChain::Flux.Chain=Flux.Chain(), outputChain::Union{Flux.Dense, Flux.Chain}=Flux.Chain(); pooling="sum")
        @assert pooling in ["sum", "max", "mean"] "Argument 'pooling' must be in {'sum', 'max', 'mean'}."
        return new(graphChain, globalChain, outputChain, pooling)
    end
end

# Enable the `|> gpu` syntax from Flux
Flux.@functor HeterogeneousFFCPNNv3

# TODO make it possible to use global features
function (nn::HeterogeneousFFCPNNv3)(states::BatchedHeterogeneousTrajectoryState)
    variableIdx = states.variableIdx
    batchSize = length(variableIdx)
    actionSpaceSize = size(states.fg.valnf, 2)
    
    # chain working on the graph(s) with the GNNs
    featuredGraph = nn.graphChain(states.fg)
    variableFeatures = featuredGraph.varnf # FxNxB
    constraintFeatures = featuredGraph.connf 
    valueFeatures = featuredGraph.valnf
    globalFeatures = featuredGraph.gf # GxB
    #println("variableFeatures: ", size(variableFeatures))
    #println("constraintFeatures: ", size(constraintFeatures))
    #println("valueFeatures: ", size(valueFeatures))
    #println("globalFeatures: ", size(globalFeatures))

    # Extract the features corresponding to the variables
    variableIndices = nothing
    Zygote.ignore() do
        variableIndices = Flux.unsqueeze(CartesianIndex.(variableIdx, 1:batchSize), 1)
    end
    branchingVariableFeatures = variableFeatures[:, variableIndices] # Fx1xB
    #println("branchingVariableFeatures: ", size(branchingVariableFeatures))
    
    pooledVariableFeatures, pooledValueFeatures, pooledConstraintFeatures = nothing, nothing, nothing
    Zygote.ignore() do
        if nn.pooling == "sum"
            pooledVariableFeatures = reshape(mapslices(x -> sum(eachcol(x)), variableFeatures, dims=[1,2]), :, 1, batchSize)
            pooledConstraintFeatures = reshape(mapslices(x -> sum(eachcol(x)), constraintFeatures, dims=[1,2]), :, 1, batchSize)
            pooledValueFeatures = reshape(mapslices(x -> sum(eachcol(x)), valueFeatures, dims=[1,2]), :, 1, batchSize)
        elseif nn.pooling == "mean"
            pooledVariableFeatures = reshape(mapslices(x -> sum(eachcol(x)), variableFeatures, dims=[1,2]), :, 1, batchSize) / size(variableFeatures, 2)
            pooledConstraintFeatures = reshape(mapslices(x -> sum(eachcol(x)), constraintFeatures, dims=[1,2]), :, 1, batchSize) / size(variableFeatures, 2)
            pooledValueFeatures = reshape(mapslices(x -> sum(eachcol(x)), valueFeatures, dims=[1,2]), :, 1, batchSize) / size(variableFeatures, 2)
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

        # Extract the global features
        globalFeatures = reshape(nn.globalChain(globalFeatures), :, 1, batchSize) # G'x1xB
        #println("globalFeatures: ", size(globalFeatures))
        # Prepare the input of the outputChain
        finalFeatures = hcat(
            valueFeatures, # F'xAxB
            branchingVariableFeatures, # F'x1xB
            globalFeatures, # G'x1xB
            pooledVariableFeatures, 
            pooledConstraintFeatures,
            pooledValueFeatures
        ) # (F'+G'+F')xAxB

        #finalFeatures = RL.flatten_batch(finalFeatures) # (F'+G'+F')x(A*B)
    else
        # Prepare the input of the outputChain
        finalFeatures = hcat(
            branchingVariableFeatures, # F'xAxB
            valueFeatures, # F'xAxB
            pooledVariableFeatures, 
            pooledConstraintFeatures,
            pooledValueFeatures,
        ) # (F'+F')xAxB
        #finalFeatures = RL.flatten_batch(finalFeatures) # (F'+F')x(A*B)
    end
    #println("finalFeatures: ", size(finalFeatures))
    # output layer
    predictions = nn.outputChain(finalFeatures) # Ox(AxB)
    #println("predictions: ", size(predictions))
    #println("predictions: ", size(predictions[:, 1:actionSpaceSize, :]))
    output = reshape(predictions[:, 1:actionSpaceSize, :], actionSpaceSize, batchSize) # OxAxB
    #println("output: ", size(output))

    return output
end

function (nn::HeterogeneousFFCPNNv3)(states::HeterogeneousTrajectoryState)
    variableIdx = states.variableIdx
    actionSpaceSize = size(states.fg.valnf, 2)
    mask = device(states) == Val(:gpu) ? CUDA.zeros(Float32, 1, actionSpaceSize) : zeros(Float32, 1, actionSpaceSize) # this mask will replace `reapeat` using broadcasted `+`

    # chain working on the graph(s) with the GNNs
    featuredGraph = nn.graphChain(states.fg)
    variableFeatures = featuredGraph.varnf # FxNxB
    constraintFeatures = featuredGraph.connf # FxN'xB
    valueFeatures = featuredGraph.valnf #FxN''xB
    globalFeatures = featuredGraph.gf # GxB
    #println("variableFeatures: ", size(variableFeatures))
    #println("constraintFeatures: ", size(constraintFeatures))
    #println("valueFeatures: ", size(valueFeatures))
    #println("globalFeatures: ", size(globalFeatures))
    
    # Extract the features corresponding to the varibales
    branchingVariableFeatures = variableFeatures[:, variableIdx] # Fx1
    #println("branchingVariableFeatures: ", size(branchingVariableFeatures))
    
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
        globalFeatures = nn.globalChain(globalFeatures) 
        # Prepare the input of the outputChain
        finalFeatures = hcat(
            branchingVariableFeatures, # Fx1
            valueFeatures, # FxA
            globalFeatures, # G'xA
            pooledVariableFeatures, #Fx1
            pooledConstraintFeatures, #Fx1
            pooledValueFeatures #Fx1
        ) # Fx(A+5)
    else
        # Prepare the input of the outputChain
        finalFeatures = hcat(
            branchingVariableFeatures, # Fx1 
            valueFeatures, # FxA 
            pooledVariableFeatures,  #Fx1
            pooledConstraintFeatures, #Fx1
            pooledValueFeatures, #Fx1
        ) # Fx(A+4)
    end
    #println("finalFeatures: ", size(finalFeatures))
    
    # output layer
    predictions = nn.outputChain(finalFeatures)[:, 1:actionSpaceSize] # OxA
    #println("predictions: ", size(predictions))

    return predictions
end



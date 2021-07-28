"""
    FullFeaturedCPNN(;
        graphChain::Flux.Chain
        nodeChain::Flux.Chain
        globalChain::Flux.Chain
        outputChain::Flux.Dense
    )

This structure is here to provide a flexible way to create a nn model which respect this approach:
Making modification on the graph, then extract one node feature and modify it.
"""
Base.@kwdef struct FullFeaturedCPNN <: NNStructure
    graphChain::Flux.Chain = Flux.Chain()
    nodeChain::Flux.Chain = Flux.Chain()
    globalChain::Flux.Chain = Flux.Chain()
    outputChain::Union{Flux.Dense, Flux.Chain} = Flux.Chain()
end

# Enable the `|> gpu` syntax from Flux
Flux.@functor FullFeaturedCPNN

# TODO make it possible to use global features
function (nn::FullFeaturedCPNN)(states::BatchedDefaultTrajectoryState)
    @assert !isnothing(states.allValuesIdx)

    variableIdx = states.variableIdx
    batchSize = length(variableIdx)
    allValuesIdx = states.allValuesIdx
    actionSpaceSize = size(allValuesIdx, 1)
    mask = device(states) == Val(:gpu) ? CUDA.zeros(Float32, 1, actionSpaceSize, batchSize) : zeros(Float32, 1, actionSpaceSize, batchSize) # this mask will replace `reapeat` using broadcasted `+`

    # chain working on the graph(s) with the GNNs
    featuredGraph = nn.graphChain(states.fg)
    nodeFeatures = featuredGraph.nf # FxNxB
    globalFeatures = featuredGraph.gf # GxB

    # Extract the features corresponding to the varibales
    variableIndices = nothing
    Zygote.ignore() do
        variableIndices = Flux.unsqueeze(CartesianIndex.(variableIdx, 1:batchSize), 1)
    end
    variableFeatures = nodeFeatures[:, variableIndices] # Fx1xB
    variableFeatures = reshape(nn.nodeChain(RL.flatten_batch(variableFeatures)), :, 1, batchSize) # F'x1xB

    # Extract the features corresponding to the values
    valueIndices = nothing
    Zygote.ignore() do 
        valueIndices = CartesianIndex.(allValuesIdx, repeat(transpose(1:batchSize); outer=(actionSpaceSize, 1)))
    end
    valueFeatures = nodeFeatures[:, valueIndices] # FxAxB
    valueFeatures = reshape(nn.nodeChain(RL.flatten_batch(valueFeatures)), :, actionSpaceSize, batchSize) # F'xAxB

    finalFeatures = nothing
    if sizeof(globalFeatures) != 0

        # Extract the global features
        globalFeatures = reshape(nn.globalChain(globalFeatures), :, 1, batchSize) # G'x1xB

        # Prepare the input of the outputChain
        finalFeatures = vcat(
            variableFeatures .+ mask, # F'xAxB
            globalFeatures .+ mask, # G'xAxB
            valueFeatures,
        ) # (F'+G'+F')xAxB
        finalFeatures = RL.flatten_batch(finalFeatures) # (F'+G'+F')x(A+B)
    else
        # Prepare the input of the outputChain
        finalFeatures = vcat(
            variableFeatures .+ mask, # F'xAxB
            valueFeatures,
        ) # (F'+F')xAxB
        finalFeatures = RL.flatten_batch(finalFeatures) # (F'+F')x(A+B)
    end

    # output layer
    predictions = nn.outputChain(finalFeatures) # Ox(A+B)
    output = reshape(predictions, actionSpaceSize, batchSize) # OxAxB

    return output
end

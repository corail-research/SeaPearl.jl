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
    nodeInputChain::Flux.Chain = Flux.Chain()
    edgeInputChain::Flux.Chain = Flux.Chain()
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

    # node pre-processing
    targetSize = (:, size(states.fg.nf)[2:end]...)
    nodeFeatures = sizeof(states.fg.nf) == 0 ? states.fg.nf : reshape(nn.nodeInputChain(flatten_batch(states.fg.nf)), targetSize)

    # edge pre-processing
    targetSize = (:, size(states.fg.ef)[2:end]...)
    edgeFeatures = sizeof(states.fg.ef) == 0 ? states.fg.ef : reshape(nn.edgeInputChain(flatten_batch(states.fg.ef)), targetSize)

    fg = BatchedFeaturedGraph{Float32}(states.fg.graph, nodeFeatures, edgeFeatures, states.fg.gf)
    

    # chain working on the graph(s) with the GNNs
    featuredGraph = nn.graphChain(fg)
    nodeFeatures = featuredGraph.nf
    globalFeatures = featuredGraph.gf

    # Extract the features corresponding to the varibales
    variableIndices = nothing
    Zygote.ignore() do
        variableIndices = Flux.unsqueeze(CartesianIndex.(variableIdx, 1:batchSize), 1)
    end
    variableFeatures = nodeFeatures[:, variableIndices]
    variableFeatures = reshape(nn.nodeChain(RL.flatten_batch(variableFeatures)), :, 1, batchSize)

    # Extract the features corresponding to the values
    valueIndices = nothing
    Zygote.ignore() do 
        valueIndices = CartesianIndex.(allValuesIdx, repeat(transpose(1:batchSize); outer=(actionSpaceSize, 1)))
    end
    valueFeatures = nodeFeatures[:, valueIndices]
    valueFeatures = reshape(nn.nodeChain(RL.flatten_batch(valueFeatures)), :, actionSpaceSize, batchSize)

    finalFeatures = nothing
    if sizeof(globalFeatures) != 0

        # Extract the global features
        globalFeatures = reshape(nn.globalChain(globalFeatures), :, 1, batchSize)

        # Prepare the input of the outputChain
        finalFeatures = vcat(
            repeat(variableFeatures; outer=(1, actionSpaceSize, 1)),
            repeat(globalFeatures; outer=(1, actionSpaceSize, 1)),
            valueFeatures,
        )
        finalFeatures = RL.flatten_batch(finalFeatures)
    else
        # Prepare the input of the outputChain
        finalFeatures = vcat(
            repeat(variableFeatures; outer=(1, actionSpaceSize, 1)),
            valueFeatures,
        )
        finalFeatures = RL.flatten_batch(finalFeatures)
    end

    # output layer
    predictions = nn.outputChain(finalFeatures)
    output = reshape(predictions, actionSpaceSize, batchSize)

    return output
end

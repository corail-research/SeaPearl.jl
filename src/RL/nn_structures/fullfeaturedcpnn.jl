"""
    FullFeaturedCPNN(;
        graphChain::Flux.Chain
        nodeChain::Flux.Chain
        outputChain::Flux.Dense
    )

This structure is here to provide a flexible way to create a nn model which respect this approach:
Making modification on the graph, then extract one node feature and modify it.
"""
Base.@kwdef struct FullFeaturedCPNN <: NNStructure
    graphChain::Flux.Chain = Flux.Chain()
    nodeChain::Flux.Chain = Flux.Chain()
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

    # chain working on the graph(s)
    nodeFeatures = nn.graphChain(states.fg).nf
    # extract the feature(s) of the variable(s) we're working on
    variableIndices = nothing
    Zygote.ignore() do
        variableIndices = Flux.unsqueeze(CartesianIndex.(variableIdx, 1:batchSize), 1)
    end
    variableFeatures = nodeFeatures[:, variableIndices]
    variableFeatures = reshape(nn.nodeChain(RL.flatten_batch(variableFeatures)), :, 1, batchSize)

    valueIndices = nothing
    Zygote.ignore() do 
        valueIndices = CartesianIndex.(allValuesIdx, repeat(transpose(1:batchSize); outer=(actionSpaceSize, 1)))
    end
    valueFeatures = nodeFeatures[:, valueIndices]
    valueFeatures = reshape(nn.nodeChain(RL.flatten_batch(valueFeatures)), :, actionSpaceSize, batchSize)

    # chain working on the node(s) feature(s)
    finalFeatures = vcat(repeat(variableFeatures; outer=(1, actionSpaceSize, 1)), valueFeatures)
    finalFeatures = reshape(finalFeatures, size(finalFeatures, 1), :)

    # output layer
    predictions = nn.outputChain(finalFeatures)
    output = reshape(predictions, actionSpaceSize, batchSize)

    return output
end

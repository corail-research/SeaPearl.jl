"""
    FlexGNN(;
        graphChain::Flux.Chain
        nodeChain::Flux.Chain
        outputLayer::Flux.Dense
    )

This structure is here to provide a flexible way to create a nn model which respect this approach:
Making modification on the graph, then extract one node feature and modify it.
"""
Base.@kwdef struct FlexGNN <: NNStructure
    graphChain::Flux.Chain = Flux.Chain()
    nodeChain::Flux.Chain = Flux.Chain()
    outputLayer::Flux.Dense
end

# Enable the `|> gpu` syntax from Flux
Flux.@functor FlexGNN

function (nn::FlexGNN)(states::BatchedDefaultTrajectoryState)

    variableIdx = states.variables
    batchSize = length(variableIdx)

    # chain working on the graph(s)
    nodeFeatures = nn.graphChain(states.fg).nf

    # extract the feature(s) of the variable(s) we're working on
    indices = nothing
    Zygote.ignore() do
        indices = CartesianIndex.(zip(variableIdx, 1:batchSize))
    end

    variableFeature = nodeFeatures[:, indices]

    # chain working on the node(s) feature(s)
    chainOutput = nn.nodeChain(variableFeature)

    # output layer
    output = nn.outputLayer(chainOutput)

    return output
end

"""
    CPNN(;
        graphChain::Flux.Chain
        nodeChain::Flux.Chain
        outputLayer::Flux.Dense
    )

This structure is here to provide a flexible way to create a nn model which respect this approach:
Making modification on the graph, then extract one node feature and modify it.
"""
Base.@kwdef struct CPNN <: NNStructure
    graphChain::Flux.Chain = Flux.Chain()
    nodeChain::Flux.Chain = Flux.Chain()
    outputChain::Union{Flux.Dense, Flux.Chain} = Flux.Chain()
end

# Enable the `|> gpu` syntax from Flux
Flux.@functor CPNN

function (nn::CPNN)(states::BatchedDefaultTrajectoryState)

    variableIdx = states.variableIdx
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
    output = nn.outputChain(chainOutput)

    return output
end

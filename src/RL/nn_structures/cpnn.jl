"""
    CPNN(;
        graphChain::Flux.Chain = Flux.Chain()
        nodeChain::Flux.Chain = Flux.Chain()
        globalChain::Flux.Chain = Flux.Chain()
        outputChain::Union{Flux.Dense, Flux.Chain} = Flux.Chain()
    )

This structure is here to provide a flexible way to create a nn model which respect this approach:
Making modification on the graph, then extract one node feature and modify it.
"""
Base.@kwdef struct CPNN <: NNStructure
    nodeInputChain::Flux.Chain = Flux.Chain()
    edgeInputChain::Flux.Chain = Flux.Chain()
    graphChain::Flux.Chain = Flux.Chain()
    nodeChain::Flux.Chain = Flux.Chain()
    globalChain::Flux.Chain = Flux.Chain()
    outputChain::Union{Flux.Dense, Flux.Chain} = Flux.Chain()
end

# Enable the `|> gpu` syntax from Flux
Flux.@functor CPNN

function (nn::CPNN)(states::BatchedDefaultTrajectoryState)

    variableIdx = states.variableIdx
    batchSize = length(variableIdx)

    # node pre-processing
    targetSize = (:, size(states.fg.nf)[2:end]...)
    nodeFeatures = sizeof(states.fg.nf) == 0 ? states.fg.nf : reshape(nn.nodeInputChain(flatten_batch(states.fg.nf)), targetSize)

    # edge pre-processing
    targetSize = (:, size(states.fg.ef)[2:end]...)
    edgeFeatures = sizeof(states.fg.ef) == 0 ? states.fg.ef : reshape(nn.edgeInputChain(flatten_batch(states.fg.ef)), targetSize)

    fg = BatchedFeaturedGraph{Float32}(states.fg.graph, nodeFeatures, edgeFeatures, states.fg.gf)

    # chain working on the graph(s)
    fg = nn.graphChain(fg)
    nodeFeatures = fg.nf
    globalFeatures = fg.gf

    # extract the feature(s) of the variable(s) we're working on
    indices = nothing
    Zygote.ignore() do
        indices = CartesianIndex.(zip(variableIdx, 1:batchSize))
    end
    variableFeature = nodeFeatures[:, indices]

    # chain working on the node(s) feature(s)
    chainNodeOutput = nn.nodeChain(variableFeature)

    if sizeof(globalFeatures) == 0
        # output layers
        output = nn.outputChain(chainNodeOutput)
        return output
    else
        # chain working on the global features
        chainGlobalOutput = nn.globalChain(globalFeatures)

        # output layers
        finalInput = vcat(chainNodeOutput, chainGlobalOutput)
        output = nn.outputChain(finalInput)
        return output
    end
end

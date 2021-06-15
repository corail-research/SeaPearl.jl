"""
    FlexVariableOutputGNN(;
        graphChain::Flux.Chain
        nodeChain::Flux.Chain
        outputLayer::Flux.Dense
    )

This structure is here to provide a flexible way to create a nn model which respect this approach:
Making modification on the graph, then extract one node feature and modify it. 
"""
Base.@kwdef struct FlexVariableOutputGNN <: NNStructure
    graphChain::Flux.Chain = Flux.Chain()
    nodeChain::Flux.Chain = Flux.Chain()
    outputLayer::Flux.Dense
end

# Enable the `|> gpu` syntax from Flux
Flux.@functor FlexVariableOutputGNN

wears_mask(s::FlexVariableOutputGNN) = false

function (nn::FlexVariableOutputGNN)(state::GraphTrajectoryState)

    variableIdx = state.variableIdx
    possibleValuesIdx = state.possibleValuesIdx

    # chain working on the graph(s)
    nodeFeatures = nn.graphChain(state.fg).nf

    # extract the feature(s) of the variable(s) we're working on
    variableFeatures = nodeFeatures[:, variableIdx]
    valueFeatures = nodeFeatures[:, possibleValuesIdx]

    # chain working on the node(s) feature(s)
    chainOutput = nn.nodeChain(hcat(variableFeatures, valueFeatures))

    variableOutput = chainOutput[:, 1]
    valueOutput = chainOutput[:, 2:end]


    finalInput = vcat(repeat(variableOutput, 1, length(possibleValuesIdx)), valueOutput)

    output = dropdims(nn.outputLayer(finalInput); dims = 1)
    return output
end

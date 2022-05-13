"""
    HeterogeneousVariableOutputCPNN(;
        graphChain::Flux.Chain
        nodeChain::Flux.Chain
        outputChain::Flux.Dense
    )

This structure is here to provide a flexible way to create a nn model which respect this approach:
Making modification on the graph, then extract one node feature and modify it. 
"""
Base.@kwdef struct HeterogeneousVariableOutputCPNN <: NNStructure
    graphChain::Flux.Chain = Flux.Chain()
    nodeChain::Flux.Chain = Flux.Chain()
    outputChain::Union{Flux.Dense, Flux.Chain} = Flux.Chain()
end

# Enable the `|> gpu` syntax from Flux
Flux.@functor HeterogeneousVariableOutputCPNN

wears_mask(s::HeterogeneousVariableOutputCPNN) = false

function (nn::HeterogeneousVariableOutputCPNN)(state::GraphTrajectoryState)

    variableIdx = state.variableIdx
    possibleValuesIdx = state.possibleValuesIdx

    # chain working on the graph(s)
    fg = nn.graphChain(state.fg)
    variableFeature = fg.varnf[:, variableIdx]
    valueFeatures = fg.valnf[:, possibleValuesIdx] #TODO change index so that it fit to heterogeneous structure

    # chain working on the node(s) feature(s)
    chainOutput = nn.nodeChain(hcat(variableFeatures, valueFeatures))

    variableOutput = chainOutput[:, 1]
    valueOutput = chainOutput[:, 2:end]


    finalInput = vcat(repeat(variableOutput, 1, length(possibleValuesIdx)), valueOutput)

    output = dropdims(nn.outputChain(finalInput); dims = 1)
    return output
end

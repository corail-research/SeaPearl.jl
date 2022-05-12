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

    # chain working on the graph(s)
    fg = nn.graphChain(states.fg)
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

    if isempty(globalFeatures)
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

# Overloads the Base.string() function for storing parameters of the neural networks associated to experiments.
function Base.string(nn::CPNN)
    final_string = "graphChain:"
    for layer in nn.graphChain.layers
        final_string *= " "*Base.string(typeof(layer))*" "
        if isa(layer,SeaPearl.GraphConv)
            final_string *= Base.string(size(layer.weight1))*" \n"
        else
            final_string *= Base.string(size(layer.weight))*" \n"
        end
    end
    final_string *= "nodeChain:"
    for layer in nn.nodeChain.layers
        final_string *= " "*Base.string(typeof(layer))*" "
        if isa(layer,SeaPearl.GraphConv)
            final_string *= Base.string(size(layer.weight1))*" \n"
        else
            final_string *= Base.string(size(layer.weight))*" \n"
        end
    end
    final_string *= "globalChain:"
    for layer in nn.globalChain.layers
        final_string *= " "*Base.string(typeof(layer))*" "
        if isa(layer,SeaPearl.GraphConv)
            final_string *= Base.string(size(layer.weight1))*" \n"
        else
            final_string *= Base.string(size(layer.weight))*" \n"
        end
    end
    final_string *= "outputChain:"
    for layer in nn.outputChain.layers
        final_string *= " "*Base.string(typeof(layer))*" "
        if isa(layer,SeaPearl.GraphConv)
            final_string *= Base.string(size(layer.weight1))*" \n"
        else
            final_string *= Base.string(size(layer.weight))*" \n"
        end
    end
    return final_string
end
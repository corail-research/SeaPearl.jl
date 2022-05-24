"""
    CPNN(;
        graphChain::Flux.Chain = Flux.Chain()
        nodeChain::Flux.Chain = Flux.Chain()
        globalChain::Flux.Chain = Flux.Chain()
        outputChain::Union{Flux.Dense, Flux.Chain} = Flux.Chain()
    )

This structure is here to provide a flexible way to create a nn model which respect this approach:
Making modification on the graph, then extract one node feature and modify it.
The CPNN pipeline uses the features of the variable branched on (`variableFeatures`) 
and, if specified, the global features of the graph (`globalFeatures`).
Contrary to `FullFeaturedCPNN`, it does not use the features of the possible values to make predictions.
This pipeline is made of 4 networks:
- `graphChain`: a graph convolutional network (GCN). It takes the original featured graph (`states.fg`) as an input,
- `nodeChain`: a fully connected neural network (FCNN). It takes the features of the variable to branch on as an input,
- `globalChain`: FCNN. It takes the global features of the graph as an input,
- `outputChain`: FCNN. It takes the concatenation of the outputs of `nodeChain` and `globalChain` as an input.
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
    println("nodeFeatures: ", size(nodeFeatures,1), ", ", size(nodeFeatures,2), ", ", size(nodeFeatures,3))
    globalFeatures = fg.gf
    println("globalFeatures: ", size(globalFeatures,1), ", ", size(globalFeatures,2), ", ", size(globalFeatures,3))
    display(globalFeatures)

    # extract the feature(s) of the variable(s) we're working on
    indices = nothing
    Zygote.ignore() do
        indices = CartesianIndex.(zip(variableIdx, 1:batchSize))
    end
    variableFeatures = nodeFeatures[:, indices]
    println("variableFeatures: ", size(variableFeatures,1), ", ", size(variableFeatures,2), ", ", size(variableFeatures,3))

    # chain working on the node(s) feature(s)
    chainNodeOutput = nn.nodeChain(variableFeatures)
    println("variableFeatures after nodeChain: ", size(chainNodeOutput,1), ", ", size(chainNodeOutput,2), ", ", size(chainNodeOutput,3))

    if isempty(globalFeatures)
        # output layers
        output = nn.outputChain(chainNodeOutput)    
        println("output: ", size(output,1), ", ", size(output,2), ", ", size(output,3))

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
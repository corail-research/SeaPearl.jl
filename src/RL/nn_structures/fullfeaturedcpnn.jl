"""
    FullFeaturedCPNN(;
        graphChain::Flux.Chain
        nodeChain::Flux.Chain
        globalChain::Flux.Chain
        outputChain::Flux.Dense
    )

This structure is here to provide a flexible way to create a nn model which respect this approach:
Making modification on the graph, then extract one node feature and modify it.

This pipeline is made of 4 networks:
- `graphChain`: a graph convolutional network (GCN). It takes the original featured graph (`states.fg`) as an input,
- `nodeChain`: a fully connected neural network (FCNN). It is used both on variableFeatures and valueFeatures.
- `globalChain`: FCNN. It takes the global features of the graph as an input,
- `outputChain`: FCNN. It takes the concatenation of the outputs of `nodeChain` and `globalChain` as an input.

Like the `CPNN` pipeline, the `FullFeaturedCPNN` pipeline uses the features of the variable branched on (`variableFeatures`) 
and, if specified, the global features of the graph (`globalFeatures`).
Contrary to `CPNN`, it also uses the features (`valueFeatures`) of the possible values that the variable can be assigned to.

`FullFeaturedCPNN` generates a Q-table containing the Q-value of all the values, both the possible and impossible ones. 
A mask then selects the possible values.
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
    possibleValuesIdx = states.possibleValuesIdx
    actionSpaceSize = size(allValuesIdx, 1)
    println("allValuesIdx: ", typeof(allValuesIdx))
    println("possibleValuesIdx: ", typeof(possibleValuesIdx))
    mask = device(states) == Val(:gpu) ? CUDA.zeros(Float32, 1, actionSpaceSize, batchSize) : zeros(Float32, 1, actionSpaceSize, batchSize) # this mask will replace `reapeat` using broadcasted `+`

    # chain working on the graph(s) with the GNNs
    featuredGraph = nn.graphChain(states.fg)
    nodeFeatures = featuredGraph.nf # FxNxB
    #println("nodeFeatures: ", size(nodeFeatures,1), ", ", size(nodeFeatures,2), ", ", size(nodeFeatures,3))
    globalFeatures = featuredGraph.gf # 0xGxB
    #println("globalFeatures: ", size(globalFeatures,1), ", ", size(globalFeatures,2), ", ", size(globalFeatures,3))

    # Extract the features corresponding to the variables
    variableIndices = nothing
    Zygote.ignore() do
        variableIndices = Flux.unsqueeze(CartesianIndex.(variableIdx, 1:batchSize), 1)
    end
    variableFeatures = nodeFeatures[:, variableIndices] # Fx1xB
    #println("variableFeatures: ", size(variableFeatures,1), ", ", size(variableFeatures,2), ", ", size(variableFeatures,3))
    variableFeatures = reshape(nn.nodeChain(RL.flatten_batch(variableFeatures)), :, 1, batchSize) # F'x1xB
    #println("variableFeatures after nodeChain and reshape: ", size(variableFeatures,1), ", ", size(variableFeatures,2), ", ", size(variableFeatures,3))

    # Extract the features corresponding to the values
    valueIndices = nothing
    Zygote.ignore() do 
        valueIndices = CartesianIndex.(allValuesIdx, repeat(transpose(1:batchSize); outer=(actionSpaceSize, 1)))
    end
    valueFeatures = nodeFeatures[:, valueIndices] # FxAxB
    #println("valueFeatures: ", size(valueFeatures,1), ", ", size(valueFeatures,2), ", ", size(valueFeatures,3))
    valueFeatures = reshape(nn.nodeChain(RL.flatten_batch(valueFeatures)), :, actionSpaceSize, batchSize) # F'xAxB
    #println("valueFeatures after nodeChain and reshape: ", size(valueFeatures,1), ", ", size(valueFeatures,2), ", ", size(valueFeatures,3))


    finalFeatures = nothing
    if sizeof(globalFeatures) != 0

        # Extract the global features
        globalFeatures = reshape(nn.globalChain(globalFeatures), :, 1, batchSize) # G'x1xB
        #println("globalFeatures: ", size(globalFeatures,1), ", ", size(globalFeatures,2), ", ", size(globalFeatures,3))

        # Prepare the input of the outputChain
        finalFeatures = vcat(
            variableFeatures .+ mask, # F'xAxB
            globalFeatures .+ mask, # G'xAxB
            valueFeatures,
        ) # (F'+G'+F')xAxB
        #println("finalFeatures (with globalFeatures): ", size(finalFeatures,1), ", ", size(finalFeatures,2), ", ", size(finalFeatures,3))
        finalFeatures = RL.flatten_batch(finalFeatures) # (F'+G'+F')x(A*B)
        #println("finalFeatures after flatten_batch: ", size(finalFeatures,1), ", ", size(finalFeatures,2), ", ", size(finalFeatures,3))
        #println(finalFeatures)
        
    else
        # Prepare the input of the outputChain
        finalFeatures = vcat(
            variableFeatures .+ mask, # F'xAxB
            valueFeatures,
        ) # (F'+F')xAxB
        #println("finalFeatures (without globalFeatures): ", size(finalFeatures,1), ", ", size(finalFeatures,2), ", ", size(finalFeatures,3))
        finalFeatures = RL.flatten_batch(finalFeatures) # (F'+F')x(A*B)
        #println("finalFeatures after flatten_batch: ", size(finalFeatures,1), ", ", size(finalFeatures,2), ", ", size(finalFeatures,3))

    end

    # output layer
    predictions = nn.outputChain(finalFeatures) # Ox(A*B)
    #println("predictions: ", size(predictions,1), ", ", size(predictions,2), ", ", size(predictions,3))
   
    output = reshape(predictions, actionSpaceSize, batchSize) # OxAxB
    #println("output: ", size(output,1), ", ", size(output,2), ", ", size(output,3))
output

    return output
end

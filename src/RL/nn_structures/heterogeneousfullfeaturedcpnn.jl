"""
    HeterogeneousFullFeaturedCPNN(;
        graphChain::Flux.Chain
        varChain::Flux.Chain = Flux.Chain()
        valChain::Flux.Chain = Flux.Chain()
        globalChain::Flux.Chain
        outputChain::Flux.Dense
    )

This structure is here to provide a flexible way to create a nn model which respect this approach:
Making modification on the graph, then extract one node feature and modify it. This CPNN is designed to process HeterogeneousFeaturedGraphs.

This pipeline works in the following way : 

1) We apply a GNN on the input featured graph.
2) We extract the contextualized-feature of the branching variable and pass it trought varChain
3) We extract the contextualized-feature of each value that is part of the variable's domain of definition and pass it trought valChain.
4) We concat the two reshaped previous results (*optionnaly* with a global feature) and pass it trought outputChain to generate the output Q-vector.
"""
Base.@kwdef struct HeterogeneousFullFeaturedCPNN <: NNStructure
    graphChain
    varChain::Flux.Chain = Flux.Chain()
    valChain::Flux.Chain = Flux.Chain()
    globalChain::Flux.Chain = Flux.Chain()
    outputChain::Union{Flux.Dense, Flux.Chain} = Flux.Chain()

    function HeterogeneousFullFeaturedCPNN(graphChain, nodeChain::Flux.Chain = Flux.Chain(), globalChain::Flux.Chain = Flux.Chain(), outputChain::Union{Flux.Dense, Flux.Chain} = Flux.Chain())
        return new(graphChain, nodeChain, deepcopy(nodeChain),globalChain, outputChain)
    end
end

# Enable the `|> gpu` syntax from Flux
Flux.@functor HeterogeneousFullFeaturedCPNN

# TODO make it possible to use global features
function (nn::HeterogeneousFullFeaturedCPNN)(states::BatchedHeterogeneousTrajectoryState)
    variableIdx = states.variableIdx
    batchSize = length(variableIdx)
    actionSpaceSize = size(states.fg.valnf, 2)
    mask = device(states) == Val(:gpu) ? CUDA.zeros(Float32, 1, actionSpaceSize, batchSize) : zeros(Float32, 1, actionSpaceSize, batchSize) # this mask will replace `reapeat` using broadcasted `+`

    # chain working on the graph(s) with the GNNs
    featuredGraph = nn.graphChain(states.fg)
    variableFeatures = featuredGraph.varnf # FxNxB
    valueFeatures = featuredGraph.valnf
    globalFeatures = featuredGraph.gf # GxB

    # Extract the features corresponding to the varibales
    variableIndices = nothing
    Zygote.ignore() do
        variableIndices = Flux.unsqueeze(CartesianIndex.(variableIdx, 1:batchSize), 1)
    end
    branchingVariableFeatures = variableFeatures[:, variableIndices] # Fx1xB
    relevantVariableFeatures = reshape(nn.varChain(RL.flatten_batch(branchingVariableFeatures)), :, 1, batchSize) # F'x1xB

    # Extract the features corresponding to the values
    relevantValueFeatures = reshape(nn.valChain(RL.flatten_batch(valueFeatures)), :, actionSpaceSize, batchSize) # F'xAxB

    finalFeatures = nothing
    if sizeof(globalFeatures) != 0

        # Extract the global features
        globalFeatures = reshape(nn.globalChain(globalFeatures), :, 1, batchSize) # G'x1xB

        # Prepare the input of the outputChain
        finalFeatures = vcat(
            relevantVariableFeatures .+ mask, # F'xAxB
            globalFeatures .+ mask, # G'xAxB
            relevantValueFeatures,
        ) # (F'+G'+F')xAxB
        finalFeatures = RL.flatten_batch(finalFeatures) # (F'+G'+F')x(AxB)
    else
        # Prepare the input of the outputChain
        finalFeatures = vcat(
            relevantVariableFeatures .+ mask, # F'xAxB
            relevantValueFeatures,
        ) # (F'+F')xAxB
        finalFeatures = RL.flatten_batch(finalFeatures) # (F'+F')x(AxB)
    end

    # output layer
    predictions = nn.outputChain(finalFeatures) # Ox(AxB)
    output = reshape(predictions, actionSpaceSize, batchSize) # OxAxB

    return output
end

function (nn::HeterogeneousFullFeaturedCPNN)(states::HeterogeneousTrajectoryState)
    variableIdx = states.variableIdx
    actionSpaceSize = size(states.fg.valnf,2)
    mask = device(states) == Val(:gpu) ? CUDA.zeros(Float32, 1, actionSpaceSize) : zeros(Float32, 1, actionSpaceSize) # this mask will replace `reapeat` using broadcasted `+`

    # chain working on the graph(s) with the GNNs
    featuredGraph = nn.graphChain(states.fg)
    variableFeatures = featuredGraph.varnf # FxNxB
    valueFeatures = featuredGraph.valnf
    globalFeatures = featuredGraph.gf # GxB

    # Extract the features corresponding to the varibales
    branchingVariableFeatures = variableFeatures[:, variableIdx] # Fx1
    relevantVariableFeatures = nn.varChain(branchingVariableFeatures) # F'x1

    # Extract the features corresponding to the values
    relevantValueFeatures = nn.valChain(valueFeatures) # F'xA

    finalFeatures = nothing
    if sizeof(globalFeatures) != 0

        # Prepare the input of the outputChain
        finalFeatures = vcat(
            relevantVariableFeatures .+ mask, # F'xA
            globalFeatures .+ mask, # G'xA
            relevantValueFeatures, # F'xA
        ) # (F'+G'+F')xA
    else
        # Prepare the input of the outputChain
        finalFeatures = vcat(
            relevantVariableFeatures .+ mask, # F'xA
            relevantValueFeatures, #F'xA
        ) # (F'+F')xA
    end

    # output layer
    predictions = nn.outputChain(finalFeatures) # OxA

    return predictions
end

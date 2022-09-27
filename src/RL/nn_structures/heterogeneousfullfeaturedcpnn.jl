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

    function HeterogeneousFullFeaturedCPNN(graphChain, varChain::Flux.Chain, valChain::Flux.Chain, globalChain::Flux.Chain, outputChain::Union{Flux.Dense, Flux.Chain})
        return new(graphChain, varChain, valChain, globalChain, outputChain)
    end
    function HeterogeneousFullFeaturedCPNN(graphChain, nodeChain::Flux.Chain = Flux.Chain(), globalChain::Flux.Chain = Flux.Chain(), outputChain::Union{Flux.Dense, Flux.Chain} = Flux.Chain())
        return new(graphChain, nodeChain, deepcopy(nodeChain), globalChain, outputChain)
    end
end

# Enable the `|> gpu` syntax from Flux
Flux.@functor HeterogeneousFullFeaturedCPNN

Zygote.@adjoint CUDA.zeros(x...) = CUDA.zeros(x...), _ -> map(_ -> nothing, x)

# TODO make it possible to use global features

function (nn::HeterogeneousFullFeaturedCPNN)(states::BatchedHeterogeneousTrajectoryState)
    variableIdx = states.variableIdx
    batchSize = length(variableIdx)
    actionSpaceSize = size(states.fg.valnf, 2)
    Mask = nothing
    Zygote.ignore() do
        Mask = device(states) != Val{:cpu}() ? CUDA.zeros(Float32, 1, size(states.fg.varnf,2), actionSpaceSize, batchSize) : zeros(Float32, 1, size(states.fg.varnf,2), actionSpaceSize, batchSize) # this Mask will replace `reapeat` using broadcasted `+`
    end
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
    branchingVariableFeatures = nn.varChain(variableFeatures) # Fx1xB
    relevantVariableFeatures = reshape(branchingVariableFeatures, size(branchingVariableFeatures)[1], size(branchingVariableFeatures)[2], 1, size(branchingVariableFeatures)[3])
    #relevantVariableFeatures = reshape(nn.varChain(RL.flatten_batch(branchingVariableFeatures)), :, 1, batchSize) # F'x1xB

    # Extract the features corresponding to the values
    relevantValueFeatures = nn.valChain(valueFeatures)
    relevantValueFeatures = reshape(relevantValueFeatures, size(relevantValueFeatures)[1], 1 ,  size(relevantValueFeatures)[2],  size(relevantValueFeatures)[3])
    #relevantValueFeatures = reshape(nn.valChain(RL.flatten_batch(valueFeatures)), :, actionSpaceSize, batchSize) # F'xAxB

    finalFeatures = nothing
    if sizeof(globalFeatures) != 0

        # Extract the global features
        globalFeatures = reshape(nn.globalChain(globalFeatures), :, 1,1, batchSize) # G'x1xB

        # Prepare the input of the outputChain
        finalFeatures = vcat(
            relevantVariableFeatures .+ Mask, # F'xAxB
            globalFeatures .+ Mask, # G'xAxB
            relevantValueFeatures .+ Mask,
        ) # (F'+G'+F')xAxB
    else
        # Prepare the input of the outputChain
        finalFeatures = vcat(
            relevantVariableFeatures .+ Mask, # F'xAxB
            relevantValueFeatures.+ Mask,
        ) # (F'+F')xAxB
    end

    # output layer
    predictions = nn.outputChain(finalFeatures)# Ox(AxB)
    predictions  = permutedims(predictions, [1,3,2,4])
    #variableIndices = Flux.unsqueeze(CartesianIndex.(variableIdx, 1:batchSize), 1)|> gpu
    variableIndices = nothing
    Zygote.ignore() do
        variableIndices = device(states) != Val{:cpu}() ? CuArray(Flux.unsqueeze(CartesianIndex.(variableIdx, 1:batchSize), 1)) : Flux.unsqueeze(CartesianIndex.(variableIdx, 1:batchSize), 1)
    end
    output = dropdims(predictions[:,:, variableIndices], dims = tuple(findall(size(predictions[:,:, variableIndices]) .== 1)...))
    return output 
end

function (nn::HeterogeneousFullFeaturedCPNN)(states::HeterogeneousTrajectoryState)
    variableIdx = states.variableIdx
    actionSpaceSize = size(states.fg.valnf,2)


    # chain working on the graph(s) with the GNNs
    featuredGraph = nn.graphChain(states.fg)
    variableFeatures = featuredGraph.varnf # FxNxB
    valueFeatures = featuredGraph.valnf
    globalFeatures = featuredGraph.gf # GxB
    Mask = device(states) != Val{:cpu}() ? CUDA.zeros(Float32, 1,size(states.fg.varnf,2), actionSpaceSize) : zeros(Float32, 1,size(states.fg.varnf,2), actionSpaceSize) # this Mask will replace `reapeat` using broadcasted `+`

    # Extract the features corresponding to the varibales
    relevantVariableFeatures = nn.varChain(variableFeatures) # F'x1

    # Extract the features corresponding to the values
    relevantValueFeatures = nn.valChain(valueFeatures) # F'xA
    relevantValueFeatures = reshape(relevantValueFeatures,size(relevantValueFeatures)[1],1,:)
    finalFeatures = nothing

    if sizeof(globalFeatures) != 0

        # Prepare the input of the outputChain
        finalFeatures = vcat(
            relevantVariableFeatures .+ Mask, # F'xA
            globalFeatures .+ Mask, # G'xA
            relevantValueFeatures .+ Mask#F'xA
            , # F'xA
        ) # (F'+G'+F')xA
    else
        # Prepare the input of the outputChain
        finalFeatures = vcat(
            relevantVariableFeatures .+ Mask, # F'xA
            relevantValueFeatures .+ Mask#F'xA
        ) # (F'+F')xA
    end

    # output layer
    predictions = nn.outputChain(finalFeatures) |> cpu# OxA
    return vec(predictions[:,variableIdx,:])
end

"""
    HeterogeneousFFCPNNv2(;
        graphChain::Flux.Chain
        globalChain::Flux.Chain
        outputChain::Flux.Dense
    )

This structure is here to provide a flexible way to create a nn model which respect this approach:
Making modification on the graph, then extract one node feature and modify it. This CPNN is designed to process HeterogeneousFeaturedGraphs.
It is a modified version of `HeterogeneousFullFeaturedCPNN``.
This pipeline works in the following way : 

1) We apply a GNN (`graphChain`) on the input featured graph.
2) We extract the features of the branching variable and of the possible values, i.e. the values that are in the domain of the variable.
3) Optional: We extract the global features of the graph and pass it through `globalChain``.
3) We extract the respective poolings of the features of all the variables, all the values and all the constraints.
4) We concatenate vertically the previous results and pass it trought `outputChain`` to generate the output Q-vector.
"""
Base.@kwdef struct HeterogeneousFFCPNNv2 <: NNStructure
    graphChain
    globalChain::Flux.Chain = Flux.Chain()
    outputChain::Union{Flux.Dense, Flux.Chain} = Flux.Chain()

    function HeterogeneousFFCPNNv2(graphChain, globalChain::Flux.Chain = Flux.Chain(), outputChain::Union{Flux.Dense, Flux.Chain} = Flux.Chain())
        return new(graphChain, globalChain, outputChain)
    end
end

# Enable the `|> gpu` syntax from Flux
Flux.@functor HeterogeneousFFCPNNv2

# TODO make it possible to use global features
function (nn::HeterogeneousFFCPNNv2)(states::BatchedHeterogeneousTrajectoryState)
    variableIdx = states.variableIdx
    batchSize = length(variableIdx)
    actionSpaceSize = size(states.fg.valnf, 2)
    mask = device(states) == Val(:gpu) ? CUDA.zeros(Float32, 1, actionSpaceSize, batchSize) : zeros(Float32, 1, actionSpaceSize, batchSize) # this mask will replace `reapeat` using broadcasted `+`

    # chain working on the graph(s) with the GNNs
    featuredGraph = nn.graphChain(states.fg)
    variableFeatures = featuredGraph.varnf # FxNxB
    constraintFeatures = featuredGraph.connf # FxN'xB
    valueFeatures = featuredGraph.valnf # FxN''xB
    globalFeatures = featuredGraph.gf # GxB

    # Extract the features corresponding to the variables
    variableIndices = nothing
    Zygote.ignore() do
        variableIndices = Flux.unsqueeze(CartesianIndex.(variableIdx, 1:batchSize), 1)
    end
    branchingVariableFeatures = variableFeatures[:, variableIndices] # Fx1xB
    
    pooledVariableFeatures, pooledValueFeatures, pooledConstraintFeatures = nothing, nothing, nothing
    Zygote.ignore() do
        pooledVariableFeatures = reshape(mapslices(x -> sum(eachcol(x)), variableFeatures, dims=[1,2]), :, 1, batchSize)
        pooledConstraintFeatures = reshape(mapslices(x -> sum(eachcol(x)), constraintFeatures, dims=[1,2]), :, 1, batchSize)
        pooledValueFeatures = reshape(mapslices(x -> sum(eachcol(x)), valueFeatures, dims=[1,2]), :, 1, batchSize)
    end
    
    finalFeatures = nothing
    if sizeof(globalFeatures) != 0

        # Extract the global features
        globalFeatures = reshape(nn.globalChain(globalFeatures), :, 1, batchSize) # G'x1xB
        # Prepare the input of the outputChain
        finalFeatures = vcat(
            branchingVariableFeatures .+ mask, # F'xAxB
            valueFeatures, # F'xAxB
            globalFeatures .+ mask, # G'xAxB
            pooledVariableFeatures .+ mask, 
            pooledConstraintFeatures .+ mask,
            pooledValueFeatures .+ mask
        ) # (F'+G'+F')xAxB
        finalFeatures = RL.flatten_batch(finalFeatures) # (F'+G'+F')x(A*B)
    else
        # Prepare the input of the outputChain
        finalFeatures = vcat(
            branchingVariableFeatures .+ mask, # F'xAxB
            valueFeatures, # F'xAxB
            pooledVariableFeatures .+ mask, 
            pooledConstraintFeatures .+ mask,
            pooledValueFeatures .+ mask,
        ) # (F'+F')xAxB
        finalFeatures = RL.flatten_batch(finalFeatures) # (F'+F')x(A*B)
    end

    # output layer
    predictions = nn.outputChain(finalFeatures) # Ox(AxB)
    output = reshape(predictions, actionSpaceSize, batchSize) # OxAxB

    return output
end

function (nn::HeterogeneousFFCPNNv2)(states::HeterogeneousTrajectoryState)
    variableIdx = states.variableIdx
    actionSpaceSize = size(states.fg.valnf, 2)
    mask = device(states) == Val(:gpu) ? CUDA.zeros(Float32, 1, actionSpaceSize) : zeros(Float32, 1, actionSpaceSize) # this mask will replace `reapeat` using broadcasted `+`

    # chain working on the graph(s) with the GNNs
    featuredGraph = nn.graphChain(states.fg)
    variableFeatures = featuredGraph.varnf # FxN
    constraintFeatures = featuredGraph.connf # FxN'
    valueFeatures = featuredGraph.valnf #FxN''
    globalFeatures = featuredGraph.gf # G
    
    # Extract the features corresponding to the varibales
    branchingVariableFeatures = variableFeatures[:, variableIdx] # Fx1
    
    pooledVariableFeatures, pooledValueFeatures, pooledConstraintFeatures = nothing, nothing, nothing
    Zygote.ignore() do
        pooledVariableFeatures = mapslices(x -> sum(eachcol(x)), variableFeatures, dims=[1,2])
        pooledConstraintFeatures = mapslices(x -> sum(eachcol(x)), constraintFeatures, dims=[1,2])
        pooledValueFeatures = mapslices(x -> sum(eachcol(x)), valueFeatures, dims=[1,2])
    end
    
    finalFeatures = nothing
    if sizeof(globalFeatures) != 0
        globalFeatures = nn.globalChain(globalFeatures) 
        # Prepare the input of the outputChain
        finalFeatures = vcat(
            branchingVariableFeatures .+ mask, # Fx1
            valueFeatures, # FxA
            globalFeatures .+ mask, # G'xA
            pooledVariableFeatures .+ mask, #Fx1
            pooledConstraintFeatures .+ mask, #Fx1
            pooledValueFeatures .+ mask #Fx1
        ) # (5F+G')xA
    else
        # Prepare the input of the outputChain
        finalFeatures = vcat(
            branchingVariableFeatures .+ mask, # F'x1 
            valueFeatures, # F'xA 
            pooledVariableFeatures .+ mask,  #F'x1
            pooledConstraintFeatures .+ mask, #F'x1
            pooledValueFeatures .+ mask, #F'x1
        ) # (5F)xA
    end

    # output layer
    predictions = nn.outputChain(finalFeatures) # OxA

    return predictions
end

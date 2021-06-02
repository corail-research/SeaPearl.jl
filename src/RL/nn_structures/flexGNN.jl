using GraphSignals

"""
    FlexGNN(;
        graphChain::Flux.Chain
        nodeChain::Flux.Chain
        outputLayer::Flux.Dense
    )

This structure is here to provide a flexible way to create a nn model which respect this approach:
Making modification on the graph, then extract one node feature and modify it. 
"""
Base.@kwdef struct FlexGNN <: NNStructure
    graphChain::Flux.Chain
    nodeChain::Flux.Chain
    outputLayer::Flux.Dense
end

# Enable the `|> gpu` syntax from Flux
Flux.@functor FlexGNN

functor(::Type{FlexGNN}, c) = (c.graphChain, c.nodeChain, c.outputLayer), ls -> FlexGNN(ls...)

"""
    function (nn::FlexGNN)(x::AbstractArray{Float32,2})

x is the encoded Array representation of the AbstractStateRepresentation usefull for the trajectory.
#TODO try to avoid the graph reconstruction at each forward pass in the NN. the featured graph can be saved in cache and updated as the reseach progresses. CAUTION with backtracking

"""
function (nn::FlexGNN)(state::DefaultTrajectoryState)

    fg, variableIdx = state.fg, state.variabeIdx

    # chain working on the graph
    variableFeature = nn.graphChain(fg)[:, variableIdx]

    # chain working on the node feature (array)
    chainOutput = nn.nodeChain(variableFeature)

    # output layer
    output = nn.outputLayer(chainOutput)

    return output
end

"""
Not working yet, issue with line
nodeFeatures = cat(nn.graphChain.(fg)...; dims=3)
and Zygote.


function (nn::FlexGNN)(states::AbstractVector{DefaultTrajectoryState})

    batchSize = length(states)
    fg = map(s -> s.fg, states)
    variableIdx = map(s -> s.variabeIdx, states)

    # chain working on the graph
    nodeFeatures = cat(nn.graphChain.(fg)...; dims=3)
    return nodeFeatures[:,1,:]
    #nodeFeatures = rand(Float32, 2, 23, 2)

    # extract the feature of the variable we're working on 
    indices = [CartesianIndex(t) for t in zip(variableIdx, 1:batchSize)]
    variableFeature = nodeFeatures[:, indices]

    # chain working on the node feature (array)
    chainOutput = nn.nodeChain(variableFeature)

    # output layer
    output = nn.outputLayer(chainOutput)

    return output
end
"""
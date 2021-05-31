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
struct FlexGNN <: NNStructure
    graphChain::Flux.Chain
    nodeChain::Flux.Chain
    outputLayer::Flux.Dense
end

function FlexGNN(; 
    graphChain::Flux.Chain, 
    nodeChain::Flux.Chain, 
    outputLayer::Flux.Dense, 
    enableGPU::Bool=true
)
    if enableGPU
        return FlexGNN(
            graphChain |> gpu,
            nodeChain |> gpu,
            outputLayer |> gpu
        )
    else
        return FlexGNN(
            graphChain,
            nodeChain,
            outputLayer
        )
    end
end


Flux.@functor FlexGNN

# not sure about this line
functor(::Type{FlexGNN}, c) = (c.graphChain, c.nodeChain, c.outputLayer), ls -> FlexGNN(ls...)

"""
    function (nn::FlexGNN)(x::AbstractArray{Float32,2})

x is the encoded Array representation of the AbstractStateRepresentation usefull for the trajectory.
#TODO try to avoid the graph reconstruction at each forward pass in the NN. the featured graph can be saved in cache and updated as the reseach progresses. CAUTION with backtracking

"""
function (nn::FlexGNN)(x::AbstractArray{Float32,2})

    # get informations from the CPGraph (input) and encoded vector
    variableId = branchingvariable_id(x, DefaultStateRepresentation)
    fg = featuredgraph(x, DefaultStateRepresentation)

    # chain working on the graph
    fg = nn.graphChain(fg)

    # extract the feature of the variable we're working on 
    var_feature = GraphSignals.node_feature(fg)[:, variableId]

    # chain working on the node feature (array)
    chain_output = nn.nodeChain(var_feature)

    # output layer
    output = nn.outputLayer(chain_output)

    return output
end

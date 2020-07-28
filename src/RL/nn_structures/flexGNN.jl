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

Flux.@functor FlexGNN

# not sure about this line
functor(::Type{FlexGNN}, c) = (c.graphChain, c.nodeChain, c.outputLayer), ls -> FlexGNN(ls...)

"""
    (nn::FlexGNN)(x::AbstractArray)

Take the CPGraph and output the q_values. Not that this could be changed a lot in the futur.
Here we do not put a mask. We let the mask to the RL.jl but this is still under debate !
"""
function (nn::FlexGNN)(x::AbstractArray{Float32,3})
    batch_size = size(x)[end]
    qval = [nn(x[:, :, i]) for i in 1:batch_size]
    hcat(qval...)
end

function (nn::FlexGNN)(x::AbstractArray{Float32,2})

    # get informations from the CPGraph (input) 
    variableId = branchingvariable_id(x)
    fg = featuredgraph(x)

    # chain working on the graph
    fg = nn.graphChain(fg)

    # extract the feature of the variable we're working on 
    var_feature = GeometricFlux.feature(fg)[:, variableId]

    # chain working on the node feature (array)
    var_feature = nn.nodeChain(var_feature)

    # output layer
    var_feature = nn.outputLayer(var_feature)

    return var_feature
end
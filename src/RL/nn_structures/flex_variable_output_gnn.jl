using GraphSignals

"""
    FlexVariableOutputGNN(;
        graphChain::Flux.Chain
        nodeChain::Flux.Chain
        outputLayer::Flux.Dense
    )

This structure is here to provide a flexible way to create a nn model which respect this approach:
Making modification on the graph, then extract one node feature and modify it. 
"""
Base.@kwdef struct FlexVariableOutputGNN <: NNStructure
    graphChain::Flux.Chain
    nodeChain::Flux.Chain
    outputLayer::Flux.Dense
    state_rep::Type{<:AbstractStateRepresentation}
end

Flux.@functor FlexVariableOutputGNN

# not sure about this line
functor(::Type{FlexVariableOutputGNN}, c) = (c.graphChain, c.nodeChain, c.outputLayer), ls -> FlexVariableOutputGNN(ls...)

wears_mask(s::FlexVariableOutputGNN) = false


function (nn::FlexVariableOutputGNN)(x::AbstractArray{Float32,2})
    # get informations from the CPGraph (input) 
    variableId = branchingvariable_id(x, nn.state_rep)
    fg = featuredgraph(x, nn.state_rep)

    # chain working on the graph
    fg = nn.graphChain(fg)

    # extract the feature of the variable we're working on 
    var_feature = GraphSignals.node_feature(fg)[:, variableId]
    var_feature = nn.nodeChain(var_feature)

    val_feature = view(GraphSignals.node_feature(fg), :, possible_value_ids(x, nn.state_rep))
    # println("possible_value_ids(x, nn.state_rep)", possible_value_ids(x, nn.state_rep))

    toReturn = [nn.outputLayer(vcat(valf, var_feature))[1] for valf in [val_feature[:, i] for i in 1:size(val_feature, 2)]]
    return toReturn
end

Base.@kwdef struct FlexGNN
    GNNs::Flux.Chain
    ANNs::Flux.Chain
    outputLayer::Flux.Dense
end

Flux.@functor FlexGNN

functor(::Type{FlexGNN}, c) = (c.GNNs, c.ANNs, c.outputLayer), ls -> FlexGNN(ls...)


"""
    (nn::FixedOutputGCN)(x::CPGraph)

Take the CPGraph and output the q_values. Not that this could be changed a lot in the futur.
Here we do not put a mask. We let the mask to the RL.jl but this is still under debate !
"""
function (nn::FlexGNN)(x::AbstractArray{Float32,4})
    y = nn(x[:, :, 1, 1])
    reshape(y, size(y)..., 1)
end
function (nn::FlexGNN)(x::AbstractArray{Float32,3})
    N = size(x)[end]
    probs = zeros(Float32, 1, size(nn.outputLayer.W)[1], N)
    for i in 1:N
        probs[1, :, i] = nn(x[:, :, i])
    end
    probs
end

function (nn::FlexGNN)(x::AbstractArray{Float32,2})
    # Create the CPGraph
    cpg = CPRL.CPGraph(x)

    # get informations from the CPGraph (input) 
    variableId = cpg.variable_id
    fg = cpg.featuredgraph

    # go through the GCNConvs
    fg = nn.GNNs(fg)

    # extract the feature of the variable we're working on 
    var_feature = GeometricFlux.feature(fg)[:, variableId]

    var_feature = nn.ANNs(var_feature)
    
    var_feature = nn.outputLayer(var_feature)

    return var_feature
end
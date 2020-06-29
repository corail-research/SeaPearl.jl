Base.@kwdef mutable struct ArgsExpGCN
    maxDomainSize       ::Int = 20
    numInFeatures       ::Int = 20
    firstHiddenGCN      ::Int = 20
    secondHiddenGCN     ::Int = 20
    hiddenDense         ::Int = 20
end

Base.@kwdef struct ExpGCN
    GCNConv_1::GeometricFlux.GCNConv
    GCNConv_2::GeometricFlux.GCNConv
    GCNConv_3::GeometricFlux.GCNConv
    Dense_1::Flux.Dense
    Dense_2::Flux.Dense
    outputLayer::Flux.Dense
end

function build_model(::Type{ExpGCN}, args::ArgsExpGCN)
    return ExpGCN(
        GCNConv_1 = GeometricFlux.GCNConv(args.numInFeatures => args.firstHiddenGCN),
        GCNConv_2 = GeometricFlux.GCNConv(args.firstHiddenGCN => args.firstHiddenGCN),
        GCNConv_3 = GeometricFlux.GCNConv(args.firstHiddenGCN => args.secondHiddenGCN),
        Dense_1 = Flux.Dense(args.secondHiddenGCN, args.hiddenDense),
        Dense_2 = Flux.Dense(args.hiddenDense, args.hiddenDense),
        outputLayer = Flux.Dense(args.hiddenDense, args.maxDomainSize)
    )
end

Flux.@functor ExpGCN

functor(::Type{ExpGCN}, c) = (
        c.GCNConv_1, c.GCNConv_2, c.GCNConv_3, 
        c.Dense_1, c.Dense_2, c.outputLayer
    ), ls -> ExpGCN(ls...)


"""
    (nn::FixedOutputGCN)(x::CPGraph)

Take the CPGraph and output the q_values. Not that this could be changed a lot in the futur.
Here we do not put a mask. We let the mask to the RL.jl but this is still under debate !
"""
function (nn::ExpGCN)(x::AbstractArray{Float32,4})
    y = nn(x[:, :, 1, 1])
    reshape(y, size(y)..., 1)
end
function (nn::ExpGCN)(x::AbstractArray{Float32,3})
    N = size(x)[end]
    probs = zeros(Float32, 1, size(nn.outputLayer.W)[1], N)
    for i in 1:N
        probs[1, :, i] = nn(x[:, :, i])
    end
    probs
end

function (nn::ExpGCN)(x::AbstractArray{Float32,2})
    # Create the CPGraph
    cpg = CPRL.CPGraph(x)

    # get informations from the CPGraph (input) 
    variableId = cpg.variable_id
    fg = cpg.featuredgraph

    # go through the GCNConvs
    fg = nn.GCNConv_1(fg)
    fg = nn.GCNConv_2(fg)
    fg = nn.GCNConv_3(fg)

    # extract the feature of the variable we're working on 
    var_feature = GeometricFlux.feature(fg)[:, variableId]

    var_feature = nn.Dense_1(var_feature)
    var_feature = nn.Dense_2(var_feature)
    var_feature = nn.outputLayer(var_feature)

    return var_feature
end
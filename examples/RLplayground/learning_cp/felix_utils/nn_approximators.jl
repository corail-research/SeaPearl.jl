Base.@kwdef mutable struct ArgsExpGCN
    maxDomainSize       ::Int = 20
    numInFeatures       ::Int = 20
    firstHiddenGCN      ::Int = 20
    secondHiddenGCN     ::Int = 20
    hiddenDense         ::Int = 20
end

Base.@kwdef struct ExpGCN
    firstGCNHiddenLayer::GeometricFlux.GCNConv
    secondGCNHiddenLayer::GeometricFlux.GCNConv
    denseLayer::Flux.Dense
    dropoutLayer::Flux.Dropout
    outputLayer::Flux.Dense
end

function build_model(::Type{ExpGCN}, args::ArgsExpGCN)
    return ExpGCN(
        firstGCNHiddenLayer = GeometricFlux.GCNConv(args.numInFeatures=>args.firstHiddenGCN, Flux.relu),
        secondGCNHiddenLayer = GeometricFlux.GCNConv(args.firstHiddenGCN=>args.secondHiddenGCN, Flux.relu),
        denseLayer = Flux.Dense(args.secondHiddenGCN, args.hiddenDense, Flux.relu),
        dropoutLayer = Flux.Dropout(0.1),
        outputLayer = Flux.Dense(args.hiddenDense, args.maxDomainSize)
    )
end

Flux.@functor ExpGCN

functor(::Type{ExpGCN}, c) = (c.firstGCNHiddenLayer, c.secondGCNHiddenLayer, c.denseLayer, c.outputLayer), ls -> ExpGCN(ls...)


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
    featuredGraph = cpg.featuredgraph

    # go through the GCNConvs
    featuredGraph = nn.firstGCNHiddenLayer(featuredGraph)
    featuredGraph = nn.secondGCNHiddenLayer(featuredGraph)

    # extract the feature of the variable we're working on 
    var_feature = GeometricFlux.feature(featuredGraph)[:, variableId]

    var_feature = nn.denseLayer(var_feature)
    var_feature = nn.dropoutLayer(var_feature)
    var_feature = nn.outputLayer(var_feature)

    return Flux.softmax(var_feature)
end
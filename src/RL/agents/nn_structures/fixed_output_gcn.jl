using GeometricFlux

@with_kw mutable struct ArgsFixedOutputGCN <: NNArgs 
    maxDomainSize       ::Int = 20
    numInFeatures       ::Int = 20
    firstHiddenGCN      ::Int = 20
    secondHiddenGCN     ::Int = 20
    hiddenDense         ::Int = 20
end

@with_kw struct FixedOutputGCN <: NNStructure
    args                    ::ArgsFixedOutputGCN
    firstGCNHiddenLayer     ::GeometricFlux.GCNConv
    secondGCNHiddenLayer    ::GeometricFlux.GCNConv
    denseLayer              ::Flux.Dense
    outputLayer             ::Flux.Dense
end

function build_model(::Type{FixedOutputGCN}, args::ArgsFixedOutputGCN)
    return FixedOutputGCN(
        args = args,
        firstGCNHiddenLayer = GeometricFlux.GCNConv(args.numInFeatures=>args.firstHiddenGCN, Flux.relu),
        secondGCNHiddenLayer = GeometricFlux.GCNConv(args.firstHiddenGCN=>args.secondHiddenGCN, Flux.relu),
        denseLayer = Flux.Dense(args.secondHiddenGCN, args.hiddenDense, Flux.relu),
        outputLayer = Flux.Dense(args.hiddenDense, args.maxDomainSize, Flux.softmax)
    )
end

function (nn::FixedOutputGCN)(x, inDomainValues::Tuple{Int})
    graph = x.graph
    features = x.features
    variableId = x.variableId

    featuredGraph = GeometricFlux.FeaturedGraph(graph, features)
    featuredGraph = nn.firstGCNHiddenLayer(featuredGraph)
    featuredGraph = nn.secondGCNHiddenLayer(featuredGraph)

    variableFeatures = GeometricFlux.feature(featuredGraph)[variableId]
    variableFeatures = nn.denseLayer(variableFeatures)
    valueProbabilities = nn.outputLayer(variableFeatures)

    valueProbabilities = valueProbabilities[inDomainValues]
    return Flux.softmax(valueProbabilities)
end
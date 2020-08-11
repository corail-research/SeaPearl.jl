using GeometricFlux

"""
    ArgsFixedOutputGCN

The args to create an adapted nn model with build_model.
"""
Base.@kwdef mutable struct ArgsFixedOutputGCN <: NNArgs 
    maxDomainSize       ::Int = 20
    numInFeatures       ::Int = 20
    firstHiddenGCN      ::Int = 20
    secondHiddenGCN     ::Int = 20
    hiddenDense         ::Int = 20
end

"""
    FixedOutputGCN

What will be used as model in the learner of the agent (... of the value selection).
"""
Base.@kwdef struct FixedOutputGCN <: NNStructure
    firstGCNHiddenLayer     ::GeometricFlux.GCNConv
    secondGCNHiddenLayer    ::GeometricFlux.GCNConv
    denseLayer              ::Flux.Dense
    outputLayer             ::Flux.Dense
end

"""
    build_model(::Type{FixedOutputGCN}, args::ArgsFixedOutputGCN)

Build a model thanks to the args.
"""
function build_model(::Type{FixedOutputGCN}, args::ArgsFixedOutputGCN)
    return FixedOutputGCN(
        firstGCNHiddenLayer = GeometricFlux.GCNConv(args.numInFeatures=>args.firstHiddenGCN, Flux.relu),
        secondGCNHiddenLayer = GeometricFlux.GCNConv(args.firstHiddenGCN=>args.secondHiddenGCN, Flux.relu),
        denseLayer = Flux.Dense(args.secondHiddenGCN, args.hiddenDense, Flux.relu),
        outputLayer = Flux.Dense(args.hiddenDense, args.maxDomainSize)
    )
end

Flux.@functor FixedOutputGCN

functor(::Type{FixedOutputGCN}, c) = (c.firstGCNHiddenLayer, c.secondGCNHiddenLayer, c.denseLayer, c.outputLayer), ls -> FixedOutputGCN(ls...)


function (nn::FixedOutputGCN)(x::AbstractArray{Float32,2})
    # get informations from the CPGraph (input) 
    variableId = branchingvariable_id(x, DefaultStateRepresentation)
    featuredGraph = featuredgraph(x, DefaultStateRepresentation)

    # go through the GCNConvs
    featuredGraph = nn.firstGCNHiddenLayer(featuredGraph)
    featuredGraph = nn.secondGCNHiddenLayer(featuredGraph)

    # extract the feature of the variable we're working on 
    variableFeatures = GeometricFlux.feature(featuredGraph)[:, variableId]

    # get through the dense layers 
    # println("Variable features after GCNConvs :  ", variableFeatures)
    variableFeatures = nn.denseLayer(variableFeatures)
    # println("After first dense layer :  ", variableFeatures)
    valueProbabilities = nn.outputLayer(variableFeatures)
    # println("After output layer :  ", valueProbabilities)

    # output a vector (of values of the possibles values)
    # println("size(Flux.softmax(valueProbabilities))", size(Flux.softmax(valueProbabilities)))
    # println("valueProbabilities", valueProbabilities)
    return valueProbabilities
end
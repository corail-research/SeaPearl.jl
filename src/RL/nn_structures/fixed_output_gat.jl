using GeometricFlux

"""
    ArgsFixedOutputGAT

The args to create an adapted nn model with build_model.
"""
Base.@kwdef mutable struct ArgsFixedOutputGAT <: NNArgs 
    maxDomainSize       ::Int = 20
    numInFeatures       ::Int = 20
    firstHiddenGAT      ::Int = 20
    secondHiddenGAT     ::Int = 20
    hiddenDense         ::Int = 20
end

"""
    FixedOutputGAT

What will be used as model in the learner of the agent (... of the value selection).
"""
Base.@kwdef struct FixedOutputGAT <: NNStructure
    firstGATHiddenLayer     ::GeometricFlux.GATConv
    secondGATHiddenLayer    ::GeometricFlux.GATConv
    denseLayer              ::Flux.Dense
    outputLayer             ::Flux.Dense
end

"""
    build_model(::Type{FixedOutputGCN}, args::ArgsFixedOutputGCN)

Build a model thanks to the args.
"""
function build_model(::Type{FixedOutputGAT}, args::ArgsFixedOutputGAT)
    return FixedOutputGAT(
        firstGATHiddenLayer = GeometricFlux.GATConv(args.numInFeatures=>args.firstHiddenGAT),
        secondGATHiddenLayer = GeometricFlux.GATConv(args.secondHiddenGAT=>args.secondHiddenGAT),
        denseLayer = Flux.Dense(args.secondHiddenGAT, args.hiddenDense, Flux.relu),
        outputLayer = Flux.Dense(args.hiddenDense, args.maxDomainSize)
    )
end

Flux.@functor FixedOutputGAT

functor(::Type{FixedOutputGAT}, c) = (c.firstGATHiddenLayer, c.secondGATHiddenLayer, c.denseLayer, c.outputLayer), ls -> FixedOutputGCN(ls...)


function (nn::FixedOutputGAT)(x::AbstractArray{Float32,2})
    # get informations from the CPGraph (input) 
    variableId = branchingvariable_id(x, DefaultStateRepresentation)
    featuredGraph = featuredgraph(x, DefaultStateRepresentation)

    # go through the GCNConvs
    featuredGraph = nn.firstGATHiddenLayer(featuredGraph)
    featuredGraph = nn.secondGATHiddenLayer(featuredGraph)

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
    return Flux.softmax(valueProbabilities)
end
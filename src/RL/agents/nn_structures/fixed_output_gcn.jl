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
    args                    ::ArgsFixedOutputGCN
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
        args = args,
        firstGCNHiddenLayer = GeometricFlux.GCNConv(args.numInFeatures=>args.firstHiddenGCN, Flux.relu),
        secondGCNHiddenLayer = GeometricFlux.GCNConv(args.firstHiddenGCN=>args.secondHiddenGCN, Flux.relu),
        denseLayer = Flux.Dense(args.secondHiddenGCN, args.hiddenDense, Flux.relu),
        outputLayer = Flux.Dense(args.hiddenDense, args.maxDomainSize, Flux.relu)
    )
end

# I feel like we will need this line but I am not sure yet
# Flux.@functor FixedOutputGCN

"""
    (nn::FixedOutputGCN)(x::CPGraph, inDomainValues::Tuple{Vararg{Int}})

Take the CPGraph and output the q_values. Not that this could be changed a lot in the futur.
Here we do not put a mask. We let the mask to the RL.jl but this is still under debate !
"""
function (nn::FixedOutputGCN)(x::CPGraph, inDomainValues::Tuple{Vararg{Int}})
    # get informations from the CPGraph (input) 
    variableId = x.variable_id
    featuredGraph = x.featuredgraph

    # go through the GCNConvs
    featuredGraph = nn.firstGCNHiddenLayer(featuredGraph)
    featuredGraph = nn.secondGCNHiddenLayer(featuredGraph)

    # extract the feature of the variable we're working on 
    variableFeatures = GeometricFlux.feature(featuredGraph)[variableId, :]

    # get through the dense layers 
    println("Variable features after GCNConvs :  ", variableFeatures)
    variableFeatures = nn.denseLayer(variableFeatures)
    println("After first dense layer :  ", variableFeatures)
    valueProbabilities = nn.outputLayer(variableFeatures)
    println("After output layer :  ", valueProbabilities)

    """
    # extract the authorized outputs 
    valueProbabilities = valueProbabilities[inDomainValues]
    println("After filtering :  ", valueProbabilities)
    """

    # output a vector (of values of the possibles values)
    return Flux.softmax(valueProbabilities)
end
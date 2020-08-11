using GeometricFlux
using Flux
using LightGraphs

"""
    ArgsFixedOutputGCN

The args to create an adapted nn model with build_model.
"""
Base.@kwdef mutable struct ArgsVariableOutputGCN <: NNArgs 
    lastLayer       ::Int = 20
    numInFeatures       ::Int = 20
    firstHiddenGCN      ::Int = 20
    secondHiddenGCN     ::Int = 20
    hiddenDense         ::Int = 20
end

"""
    FixedOutputGCN

What will be used as model in the learner of the agent (... of the value selection).
"""
Base.@kwdef struct VariableOutputGCN <: NNStructure
    firstGCNHiddenLayer     ::GeometricFlux.GCNConv
    secondGCNHiddenLayer    ::GeometricFlux.GCNConv
    denseLayer              ::Flux.Dense
    lastLayer::Flux.Dense
    outputLayer             ::Flux.Dense
    numInFeatures::Int
end

wears_mask(s::VariableOutputGCN) = false

"""
    build_model(::Type{FixedOutputGCN}, args::ArgsFixedOutputGCN)

Build a model thanks to the args.
"""
function build_model(::Type{VariableOutputGCN}, args::ArgsVariableOutputGCN)
    return VariableOutputGCNLSTM(
        firstGCNHiddenLayer = GeometricFlux.GCNConv(args.numInFeatures=>args.firstHiddenGCN, Flux.relu),
        secondGCNHiddenLayer = GeometricFlux.GCNConv(args.firstHiddenGCN=>args.secondHiddenGCN, Flux.relu),
        denseLayer = Flux.Dense(args.secondHiddenGCN, args.hiddenDense, Flux.relu),
        lastLayer = Flux.Dense(args.lstmSize, args.lastLayer),
        outputLayer = Flux.Dense(args.secondHiddenGCN+args.lastLayer, 1),
        numInFeatures = args.numInFeatures
    )
end

Flux.@functor VariableOutputGCN

functor(::Type{VariableOutputGCN}, c) = (c.firstGCNHiddenLayer, c.secondGCNHiddenLayer, c.denseLayer, c.outputLayer), ls -> FixedOutputGCN(ls...)


# Resetting the reccurent part
function Flux.reset!(nn::VariableOutputGCN)
    Flux.reset!(nn.LSTMLayer)
end

function (nn::VariableOutputGCN)(x::AbstractArray{Float32,2})
    # get informations from the CPGraph (input) 
    variableId = branchingvariable_id(x, DefaultStateRepresentation)
    featuredGraph = featuredgraph(x, DefaultStateRepresentation)

    # go through the GCNConvs
    featuredGraph = nn.firstGCNHiddenLayer(featuredGraph)
    featuredGraph = nn.secondGCNHiddenLayer(featuredGraph)

    # extract the feature of the variable we're working on 
    variableFeatures = GeometricFlux.feature(featuredGraph)[:, variableId]

    valueFeatures = view(GeometricFlux.feature(featuredGraph), :, possible_value_ids(x, DefaultStateRepresentation))
    

    # get through the dense layers 
    # println("Variable features after GCNConvs :  ", variableFeatures)
    variableFeatures = nn.denseLayer(variableFeatures)


    # println("After first dense layer :  ", variableFeatures)
    variableFeatures = nn.lastLayer(variableFeatures)
    # println("size(variableFeatures)", size(variableFeatures))
    # println("After output layer :  ", valueProbabilities)

    # output a vector (of values of the possibles values)
    # println("size(Flux.softmax(valueProbabilities))", size(Flux.softmax(valueProbabilities)))
    toReturn = [nn.outputLayer(vcat(valf, variableFeatures))[1] for valf in [valueFeatures[:, i] for i in 1:size(valueFeatures, 2)]]
    # println("toReturn", toReturn)
    return toReturn
end
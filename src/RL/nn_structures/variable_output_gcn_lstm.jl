using GeometricFlux
using Flux
using LightGraphs

"""
    ArgsFixedOutputGCNLSTM

The args to create an adapted nn model with build_model.
"""
Base.@kwdef mutable struct ArgsVariableOutputGCNLSTM <: NNArgs 
    lastLayer       ::Int = 20
    numInFeatures       ::Int = 20
    firstHiddenGCN      ::Int = 20
    secondHiddenGCN     ::Int = 20
    hiddenDense         ::Int = 20
    lstmSize            ::Int = 20
end

"""
    FixedOutputGCN

What will be used as model in the learner of the agent (... of the value selection).
"""
Base.@kwdef struct VariableOutputGCNLSTM <: NNStructure
    firstGCNHiddenLayer     ::GeometricFlux.GCNConv
    secondGCNHiddenLayer    ::GeometricFlux.GCNConv
    denseLayer              ::Flux.Dense
    LSTMLayer               ::Flux.Recur{Flux.LSTMCell{Array{Float32,2},Array{Float32,1}}}
    lastLayer::Flux.Dense
    outputLayer             ::Flux.Dense
    numInFeatures::Int
end

wears_mask(s::VariableOutputGCNLSTM) = false

"""
    build_model(::Type{FixedOutputGCN}, args::ArgsFixedOutputGCN)

Build a model thanks to the args.
"""
function build_model(::Type{VariableOutputGCNLSTM}, args::ArgsVariableOutputGCNLSTM)
    return VariableOutputGCNLSTM(
        firstGCNHiddenLayer = GeometricFlux.GCNConv(args.numInFeatures=>args.firstHiddenGCN, Flux.relu),
        secondGCNHiddenLayer = GeometricFlux.GCNConv(args.firstHiddenGCN=>args.secondHiddenGCN, Flux.relu),
        denseLayer = Flux.Dense(args.secondHiddenGCN, args.hiddenDense, Flux.relu),
        LSTMLayer = Flux.LSTM(args.hiddenDense, args.lstmSize),
        lastLayer = Flux.Dense(args.lstmSize, args.lastLayer),
        outputLayer = Flux.Dense(args.secondHiddenGCN+args.lastLayer, 1),
        numInFeatures = args.numInFeatures
    )
end

Flux.@functor VariableOutputGCNLSTM

functor(::Type{VariableOutputGCNLSTM}, c) = (c.firstGCNHiddenLayer, c.secondGCNHiddenLayer, c.denseLayer, c.LSTMLayer, c.outputLayer), ls -> FixedOutputGCN(ls...)

"""
    (nn::FixedOutputGCN)(x::CPGraph)

Take the CPGraph and output the q_values. Not that this could be changed a lot in the futur.
Here we do not put a mask. We let the mask to the RL.jl but this is still under debate !
"""
function (nn::VariableOutputGCNLSTM)(x::AbstractArray{Float32,4})
    y = nn(x[:, :, 1, 1])
    reshape(y, size(y)..., 1)
end
function (nn::VariableOutputGCNLSTM)(x::AbstractArray{Float32,3})
    N = size(x)[end]
    probs = zeros(Float32, 1, size(nn.outputLayer.W)[1], N)
    for i in 1:N
        probs[1, :, i] = nn(x[:, :, i])
    end
    probs
end

# Resetting the reccurent part
function Flux.reset!(nn::VariableOutputGCNLSTM)
    Flux.reset!(nn.LSTMLayer)
end

function (nn::VariableOutputGCNLSTM)(x::AbstractArray{Float32,2})
    # get informations from the CPGraph (input) 
    variableId = branchingvariable_id(x)
    featuredGraph = featuredgraph(x)

    # go through the GCNConvs
    featuredGraph = nn.firstGCNHiddenLayer(featuredGraph)
    featuredGraph = nn.secondGCNHiddenLayer(featuredGraph)

    # extract the feature of the variable we're working on 
    variableFeatures = GeometricFlux.feature(featuredGraph)[:, variableId]

    valueFeatures = view(GeometricFlux.feature(featuredGraph), :, possible_value_ids(x))
    

    # get through the dense layers 
    # println("Variable features after GCNConvs :  ", variableFeatures)
    variableFeatures = nn.denseLayer(variableFeatures)
    variableFeatures = nn.LSTMLayer(variableFeatures)


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
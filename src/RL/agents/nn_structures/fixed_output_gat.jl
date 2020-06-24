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

"""
    (nn::FixedOutputGCN)(x::CPGraph)

Take the CPGraph and output the q_values. Not that this could be changed a lot in the futur.
Here we do not put a mask. We let the mask to the RL.jl but this is still under debate !
"""
function (nn::FixedOutputGAT)(x::AbstractArray{Float32,4})
    y = nn(x[:, :, 1, 1])
    reshape(y, size(y, 1), size(y, 2), 1, 1)
end
function (nn::FixedOutputGAT)(x::AbstractArray{Float32,3})
    N = size(x)[end]
    probs = zeros(Float32, 1, size(nn.outputLayer.W)[1], N)
    for i in 1:N
        probs[1, :, i] = nn(x[:, :, i])
    end
    probs
end

function (nn::FixedOutputGAT)(x::AbstractArray{Float32,2})
    # Create the CPGraph
    cpg = CPGraph(x)

    # get informations from the CPGraph (input) 
    variableId = cpg.variable_id
    featuredGraph = cpg.featuredgraph

    # go through the GCNConvs
    featuredGraph = nn.firstGATHiddenLayer(featuredGraph)
    featuredGraph = nn.secondGATHiddenLayer(featuredGraph)

    # extract the feature of the variable we're working on 
    variableFeatures = GeometricFlux.feature(featuredGraph)[:, variableId+1]

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
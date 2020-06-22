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
        outputLayer = Flux.Dense(args.hiddenDense, args.maxDomainSize, Flux.relu)
    )
end

Flux.@functor FixedOutputGCN

functor(::Type{FixedOutputGCN}, c) = (c.firstGCNHiddenLayer, c.secondGCNHiddenLayer, c.denseLayer, c.outputLayer), ls -> FixedOutputGCN(ls...)

"""
    (nn::FixedOutputGCN)(x::CPGraph)

Take the CPGraph and output the q_values. Not that this could be changed a lot in the futur.
Here we do not put a mask. We let the mask to the RL.jl but this is still under debate !
"""
function (nn::FixedOutputGCN)(x::AbstractArray{Float32,4})
    # N = size(x, 4)
    # probs = zeros(Float32, 1, size(nn.outputLayer.W)[1], size(x, 3), N)
    # for j in 1:size(x, 3)
    #     for i in 1:N
    #     # println("(nn::FixedOutputGCN)(x::AbstractArray{Float32,4}): ", i, " ", j)
    #     probs[1, :, j, i] = nn(x[:, :, j, i])
    #     end
    # end
    # println("(nn::FixedOutputGCN)(x::AbstractArray{Float32,4}):end ", probs)
    y = nn(x[:, :, 1, 1])
    reshape(y, size(y, 1), size(y, 2), 1, 1)
end
function (nn::FixedOutputGCN)(x::AbstractArray{Float32,3})
    N = size(x)[end]
    probs = zeros(Float32, 1, size(nn.outputLayer.W)[1], N)
    for i in 1:N
        println("(nn::FixedOutputGCN)(x::AbstractArray{Float32,3}): ", i)
        probs[1, :, i] = nn(x[:, :, i])
    end
    probs
end
function (nn::FixedOutputGCN)(x::AbstractArray{Float32,2})
    # Create the CPGraph
    cpg = CPGraph(x)

    # get informations from the CPGraph (input) 
    variableId = cpg.variable_id
    featuredGraph = cpg.featuredgraph

    # go through the GCNConvs
    featuredGraph = nn.firstGCNHiddenLayer(featuredGraph)
    featuredGraph = nn.secondGCNHiddenLayer(featuredGraph)

    # extract the feature of the variable we're working on 
    variableFeatures = GeometricFlux.feature(featuredGraph)[:, variableId+1]

    # get through the dense layers 
    println("Variable features after GCNConvs :  ", variableFeatures)
    variableFeatures = nn.denseLayer(variableFeatures)
    println("After first dense layer :  ", variableFeatures)
    valueProbabilities = nn.outputLayer(variableFeatures)
    println("After output layer :  ", valueProbabilities)

    # output a vector (of values of the possibles values)
    # println("size(Flux.softmax(valueProbabilities))", size(Flux.softmax(valueProbabilities)))
    return Flux.softmax(valueProbabilities)
end
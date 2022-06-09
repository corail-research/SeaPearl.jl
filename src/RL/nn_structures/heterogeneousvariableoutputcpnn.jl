"""
    HeterogeneousVariableOutputCPNN(;
        graphChain::Flux.Chain
        nodeChain::Flux.Chain
        outputChain::Flux.Dense
    )

This structure is here to provide a flexible way to create a nn model which respect this approach:
Making modification on the graph, then extract one node feature and modify it. 
"""
Base.@kwdef struct HeterogeneousVariableOutputCPNN <: NNStructure
    graphChain
    nodeChain::Flux.Chain = Flux.Chain()
    outputChain::Union{Flux.Dense, Flux.Chain} = Flux.Chain()
end

# Enable the `|> gpu` syntax from Flux
Flux.@functor HeterogeneousVariableOutputCPNN


wears_mask(s::HeterogeneousVariableOutputCPNN) = true

function (nn::HeterogeneousVariableOutputCPNN)(state::HeterogeneousTrajectoryState)
    variableIdx = state.variableIdx
    possibleValuesIdx = state.possibleValuesIdx
    # chain working on the graph(s)
    fg = nn.graphChain(state.fg)
    # chain working on the node(s) feature(s)
    variableFeatures = fg.varnf[:, variableIdx]
    valueFeatures = fg.valnf[:, possibleValuesIdx]
    chainOutput = nn.nodeChain(hcat(variableFeatures, valueFeatures))
    variableOutput = chainOutput[:, 1]
    valueOutput = chainOutput[:, 2:end]

    finalInput = vcat(repeat(variableOutput, 1, length(possibleValuesIdx)), valueOutput)
    output = dropdims(nn.outputChain(finalInput); dims = 1)
    finalOutput = zeros(Float32, size(fg.valnf, 2))
    for i in 1:length(possibleValuesIdx)
        finalOutput[possibleValuesIdx[i]] = output[i]
    end
    return finalOutput
    
end

function (nn::HeterogeneousVariableOutputCPNN)(state::BatchedHeterogeneousTrajectoryState)
    variableIdx = state.variableIdx #Vector of size B
    batchSize = length(variableIdx)
    possibleValuesIdx = [deepcopy(indexes) for indexes in state.possibleValuesIdx]
    
    @assert batchSize == length(possibleValuesIdx)
    actionSpaceSizes = [length(possibleValuesIdxPerVar) for possibleValuesIdxPerVar in possibleValuesIdx]
    maxActionSpaceSize = Base.maximum(actionSpaceSizes)
    #the largest action space size in the batch
    
    # chain working on the graph(s)
    fg = nn.graphChain(state.fg)
    
    # extract the feature(s) of the variable(s) we're working on
    indices = nothing
    Zygote.ignore() do
        indices = CartesianIndex.(zip(variableIdx, 1:batchSize))
    end
    variableFeatures = nothing
    numPadded = nothing
    Zygote.ignore() do
        variableFeatures = reshape(fg.varnf[:, indices], (:,1,batchSize)) # Fx1xB
        # extract the feature(s) of the variable(s) we're working on
        numPadded = [maxActionSpaceSize - actionSpaceSizes[i] for i in 1:batchSize] #number of padding zeros needed fo each element of the batch
    end
    
    valueIndices = nothing
    Zygote.ignore() do 
        paddedPossibleValuesIdx = [append!(possibleValuesIdx[i], repeat([possibleValuesIdx[i][1]], numPadded[i])) for i in 1:batchSize]
        paddedPossibleValuesIdx = mapreduce(identity, hcat, paddedPossibleValuesIdx) #convert from Vector to Matrix
        #create a CartesianIndex matrix of size (maxActionSpaceSize x batch_size)
        valueIndices = CartesianIndex.(paddedPossibleValuesIdx, repeat(transpose(1:batchSize); outer=(maxActionSpaceSize, 1)))
    end

    valueFeatures = fg.valnf[:, valueIndices] #FxAxB
    
    f = size(valueFeatures, 1)
    Zygote.ignore() do    
        for i in 1:batchSize
            for j in 1:numPadded[i]
                valueFeatures[:,maxActionSpaceSize-j+1,i] = zeros(Float32, f)
            end
        end
    end
    
    # chain working on the node(s) feature(s)
    chainOutput = nn.nodeChain(hcat(variableFeatures, valueFeatures)) #F'x(A+1)xB where F' is the output size of nodeChain
    
    variableOutput = nothing
    valueOutput = nothing
    Zygote.ignore() do
        variableOutput = reshape(chainOutput[:,1,:], (:,1,batchSize)) #F'xB
        valueOutput = chainOutput[:,2:end,:] #F'xAxB
    end
    
    finalInput = nothing 
    Zygote.ignore() do
        finalInput = []
        for i in 1:batchSize
            singleFinalInput = vcat(repeat(variableOutput[:,:,i], 1, maxActionSpaceSize), valueOutput[:,:,i]) #one element of the batch
            finalInput = isempty(finalInput) ? [singleFinalInput] : append!(finalInput, [singleFinalInput])
        end
    end
    #finalInput: vector of matrices of size F'xA (total size BxF'xA)
    Zygote.ignore() do
        f, a = size(finalInput[1])
        finalInput = reshape(collect(Iterators.flatten(finalInput)), (f, maxActionSpaceSize, batchSize)) #!!TO TEST #convert vector of matrices into a 3-dimensional matrix
        
    end

    output = dropdims(nn.outputChain(finalInput); dims=1) #AxB
    
    finalOutput = nothing
    Zygote.ignore() do
        finalOutput = reshape(
            Float32[-Inf32 for _ in 1:(size(fg.valnf,2)*size(fg.valnf,3))], 
            size(fg.valnf,2), 
            size(fg.valnf,3)
        )
    end
    
    Zygote.ignore() do
        for i in 1:batchSize
            for j in 1:actionSpaceSizes[i]
                #note that possibleValuesIdx is a Vector{Vector{Int64}} while output and finalOutput are Matrix{Int64}
                #thus the indexing can be inverted, e.g. the batches are in dim 1 for a Vector{Vector{Int64}} and in dim 2 for a Matrix{Int64}
                finalOutput[possibleValuesIdx[i][j], i] = output[j,i]
            end
        end
    end

    return finalOutput

end

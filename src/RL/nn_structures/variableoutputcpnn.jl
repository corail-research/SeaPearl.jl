"""
    VariableOutputCPNN(;
        graphChain::Flux.Chain
        nodeChain::Flux.Chain
        outputChain::Flux.Dense
    )

This structure is here to provide a flexible way to create a nn model which respect this approach:
Making modification on the graph, then extract one node feature and modify it. 
"""
Base.@kwdef struct VariableOutputCPNN <: NNStructure
    graphChain::Flux.Chain = Flux.Chain()
    nodeChain::Flux.Chain = Flux.Chain()
    outputChain::Union{Flux.Dense, Flux.Chain} = Flux.Chain()
end

# Enable the `|> gpu` syntax from Flux
Flux.@functor VariableOutputCPNN

wears_mask(s::VariableOutputCPNN) = true

function (nn::VariableOutputCPNN)(state::BatchedDefaultTrajectoryState)
    variableIdx = state.variableIdx #Vector of size B
    batchSize = length(variableIdx)
    possibleValuesIdx = [deepcopy(indexes) for indexes in state.possibleValuesIdx]
    
    @assert batchSize == length(possibleValuesIdx)
    actionSpaceSizes = [length(possibleValuesIdxPerVar) for possibleValuesIdxPerVar in possibleValuesIdx]
    maxActionSpaceSize = length(state.allValuesIdx) #Base.maximum(actionSpaceSizes)
    #the largest action space size in the batch
    
    # chain working on the graph(s)
    nodeFeatures = nn.graphChain(state.fg).nf #matrix of size FxNxB (features after graphChain x # of nodes x batch_size)
    
    # extract the feature(s) of the variable(s) we're working on
    indices = nothing
    ChainRulesCore.ignore_derivatives() do
        indices = CartesianIndex.(zip(variableIdx, 1:batchSize))
    end
    variableFeatures = nothing
    numPadded = nothing
    ChainRulesCore.ignore_derivatives() do
        variableFeatures = reshape(nodeFeatures[:, indices], (:,1,batchSize)) # Fx1xB
        # extract the feature(s) of the variable(s) we're working on
        numPadded = [maxActionSpaceSize - actionSpaceSizes[i] for i in 1:batchSize] #number of padding zeros needed fo each element of the batch
    end
    
    valueIndices = nothing
    ChainRulesCore.ignore_derivatives() do 
        paddedPossibleValuesIdx = [append!(possibleValuesIdx[i], repeat([possibleValuesIdx[i][1]], numPadded[i])) for i in 1:batchSize]
        paddedPossibleValuesIdx = mapreduce(identity, hcat, paddedPossibleValuesIdx) #convert from Vector to Matrix
        #create a CartesianIndex matrix of size (maxActionSpaceSize x batch_size)
        valueIndices = CartesianIndex.(paddedPossibleValuesIdx, repeat(transpose(1:batchSize); outer=(maxActionSpaceSize, 1)))
    end

    valueFeatures = nodeFeatures[:, valueIndices] #FxAxB
    
    f = size(valueFeatures, 1)
    ChainRulesCore.ignore_derivatives() do    
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
    ChainRulesCore.ignore_derivatives() do
        variableOutput = reshape(chainOutput[:,1,:], (:,1,batchSize)) #F'xB
        valueOutput = chainOutput[:,2:end,:] #F'xAxB
    end

    finalInput = nothing 
    ChainRulesCore.ignore_derivatives() do
        finalInput = []
        for i in 1:batchSize
            singleFinalInput = vcat(repeat(variableOutput[:,:,i], 1, maxActionSpaceSize), valueOutput[:,:,i])
            finalInput = isempty(finalInput) ? [singleFinalInput] : append!(finalInput, [singleFinalInput])
        end
    end
    ChainRulesCore.ignore_derivatives() do
        f, a = size(finalInput[1])
        finalInput = reshape(collect(Iterators.flatten(finalInput)), (f, maxActionSpaceSize, batchSize)) #!!TO TEST #convert vector of matrices into a 3-dimensional matrix 
    end

    output = dropdims(nn.outputChain(finalInput); dims=1) #AxB
    finalOutput = nothing
    ChainRulesCore.ignore_derivatives() do
        finalOutput = reshape(
            Float32[-Inf32 for _ in 1:(size(state.allValuesIdx,1)*size(state.allValuesIdx,2))], 
            size(state.allValuesIdx,1), 
            size(state.allValuesIdx,2)
        )
    end
    
    ChainRulesCore.ignore_derivatives() do
        for i in 1:batchSize
            for j in 1:actionSpaceSizes[i]
                #the order of a vertex_id in allValuesIdx
                order = from_id_to_order(state, possibleValuesIdx[i][j]; which_list="allValuesIdx", idx_in_batch=i) 
                #note that possibleValuesIdx is a Vector{Vector{Int64}} while output and finalOutput are Matrix{Int64}
                #thus the indexing can be inverted, e.g. the batches are in dim 1 for a Vector{Vector{Int64}} and in dim 2 for a Matrix{Int64}
                finalOutput[order,i] = output[j, i]
            end
        end
    end
    
    return finalOutput

end


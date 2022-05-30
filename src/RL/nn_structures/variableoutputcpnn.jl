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

wears_mask(s::VariableOutputCPNN) = false

function (nn::VariableOutputCPNN)(state::BatchedDefaultTrajectoryState)
    
    variableIdx = state.variableIdx #Vector of size B
    #println("variableIdx: ", variableIdx)
    batchSize = length(variableIdx)

    #println("batchSize: ", batchSize)
    #println("allValuesIdx: ", state.allValuesIdx)
    #display(state.allValuesIdx)
    
    possibleValuesIdx = [deepcopy(indexes) for indexes in state.possibleValuesIdx]
    
    @assert batchSize == length(possibleValuesIdx)
    #println("possibleValuesIdx: ", possibleValuesIdx) 
    #display(possibleValuesIdx)
    actionSpaceSizes = [length(possibleValuesIdxPerVar) for possibleValuesIdxPerVar in possibleValuesIdx]
    #println("actionSpaceSizes: ", actionSpaceSizes)
    maxActionSpaceSize = Base.maximum(actionSpaceSizes) #the largest action space size in the batch
    #println("maxActionSpaceSize: ", maxActionSpaceSize)

    # chain working on the graph(s)
    nodeFeatures = nn.graphChain(state.fg).nf #matrix of size FxNxB (features after graphChain x # of nodes x batch_size)
    #println("nodeFeatures: ", size(nodeFeatures))

    # extract the feature(s) of the variable(s) we're working on
    indices = nothing
    Zygote.ignore() do
        indices = CartesianIndex.(zip(variableIdx, 1:batchSize))
    end
    #println("indices: ")
    #display(indices)
    variableFeatures = nothing
    numPadded = nothing
    Zygote.ignore() do
        variableFeatures = reshape(nodeFeatures[:, indices], (:,1,batchSize)) # Fx1xB
        #println("variableFeatures: ", size(variableFeatures)) 
        # extract the feature(s) of the variable(s) we're working on
        numPadded = [maxActionSpaceSize - actionSpaceSizes[i] for i in 1:batchSize] #number of padding zeros needed fo each element of the batch
        #println("numPadded: ", numPadded)
    end
    
    valueIndices = nothing
    Zygote.ignore() do 
        paddedPossibleValuesIdx = [append!(possibleValuesIdx[i], repeat([possibleValuesIdx[i][1]], numPadded[i])) for i in 1:batchSize]
        #println("paddedPossibleValuesIdx: ", paddedPossibleValuesIdx)
        paddedPossibleValuesIdx = mapreduce(identity, hcat, paddedPossibleValuesIdx) #convert from Vector to Matrix
        #create a CartesianIndex matrix of size (maxActionSpaceSize x batch_size)
        valueIndices = CartesianIndex.(paddedPossibleValuesIdx, repeat(transpose(1:batchSize); outer=(maxActionSpaceSize, 1)))
        #println("valueIndices: ", valueIndices)
    end

    #println("valueIndices: ") 
    #display(valueIndices)
    valueFeatures = nodeFeatures[:, valueIndices] #FxAxB
    
    f = size(valueFeatures, 1)
    Zygote.ignore() do    
        for i in 1:batchSize
            for j in 1:numPadded[i]
                valueFeatures[:,maxActionSpaceSize-j+1,i] = zeros(Float32, f)
            end
        end
    end
    #println("valueFeatures: ")
    #display(valueFeatures)
    #println("valueFeatures: ", size(valueFeatures)) 

    # chain working on the node(s) feature(s)
    chainOutput = nn.nodeChain(hcat(variableFeatures, valueFeatures)) #F'x(A+1)xB where F' is the output size of nodeChain
    #println("concatFeatures: ", size(hcat(variableFeatures, valueFeatures))) 
    #println("chainOutput: ", size(chainOutput))
   
    variableOutput = nothing
    valueOutput = nothing
    Zygote.ignore() do
        variableOutput = reshape(chainOutput[:,1,:], (:,1,batchSize)) #F'xB
        #println("variableOutput: ", size(variableOutput))
        valueOutput = chainOutput[:,2:end,:] #F'xAxB
        #println("valueOutput: ", size(valueOutput))
    end

    finalInput = nothing 
    Zygote.ignore() do
        finalInput = []
        for i in 1:batchSize
            singleFinalInput = vcat(repeat(variableOutput[:,:,i], 1, maxActionSpaceSize), valueOutput[:,:,i])
            #println("singleFinalInput: ", size(singleFinalInput))
            finalInput = isempty(finalInput) ? [singleFinalInput] : append!(finalInput, [singleFinalInput])
        end
    end
    #finalInput: vector of matrices of size F'xA (total size BxF'xA)
    Zygote.ignore() do
        f, a = size(finalInput[1])
        finalInput = reshape(collect(Iterators.flatten(finalInput)), (f, maxActionSpaceSize, batchSize)) #!!TO TEST #convert vector of matrices into a 3-dimensional matrix
        #println("finalInput: ", size(finalInput)) 
    end

    output = dropdims(nn.outputChain(finalInput); dims=1) #AxB
    #println("output: ")
    #display(output)

    finalOutput = nothing
    Zygote.ignore() do
        finalOutput = reshape(
            Float32[-Inf32 for _ in 1:(size(state.allValuesIdx,1)*size(state.allValuesIdx,2))], 
            size(state.allValuesIdx,1), size(state.allValuesIdx,2)
        )
    end
    
    Zygote.ignore() do
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
    
    #println("finalOutput: ", finalOutput)

    return finalOutput

end


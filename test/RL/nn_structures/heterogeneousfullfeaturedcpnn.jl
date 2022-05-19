@testset "heterogeneousfullfeaturedcpnn" begin

    @testset "array manipulmation verification for BatchedHeterogeneousTrajectoryState input" begin 

        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        x = SeaPearl.IntVar(2, 4, "x", trailer)
        y = SeaPearl.IntVar(3, 4, "y", trailer)
        z = SeaPearl.IntVar(3, 5, "z", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        SeaPearl.addVariable!(model, z)

        SeaPearl.addConstraint!(model, SeaPearl.NotEqual(x, y, trailer))
        SeaPearl.addConstraint!(model, SeaPearl.NotEqual(y, z, trailer))

        chosen_features = Dict(
            "constraint_activity" => false,
            "constraint_type" => true,
            "nb_involved_constraint_propagation" => false,
            "nb_not_bounded_variable" => false,
            "variable_domain_size" => true,
            "variable_initial_domain_size" => true,
            "variable_is_bound" => false,
            "values_onehot" => true,
            "values_raw" => false,
        )

        lh = SeaPearl.SimpleLearnedHeuristic{SeaPearl.HeterogeneousStateRepresentation{SeaPearl.DefaultFeaturization,SeaPearl.HeterogeneousTrajectoryState}, SeaPearl.DefaultReward, SeaPearl.VariableOutput}(agent; chosen_features=chosen_features)
        
        SeaPearl.update_with_cpmodel!(lh, model, chosen_features=chosen_features)

        state1 = deepcopy(SeaPearl.get_observation!(lh, model, x).state)
        SeaPearl.assign!(x, 2)
        state2 = SeaPearl.get_observation!(lh, model, y).state
        states = [state1,state2] |> cpu      #create BatchedDefaultTrajectoryState with two samples
        nn = SeaPearl.HeterogeneousFullFeaturedCPNN(Flux.Chain(),Flux.Chain(),Flux.Chain(),Flux.Dense(6, 1, Flux.leakyrelu))

        @test  SeaPearl.wears_mask(nn) == true

        #We copy the entire HeterogeneousFullFeaturedCPNN pipeline to be able to access intermediate elements, we finally ensure that the result obtained using the nn object is identic to the result obtained here. 

        variableIdx = states.variableIdx
        batchSize = length(variableIdx)
        actionSpaceSize = size(states.fg.valnf, 2)
        mask = device(states) == Val(:gpu) ? CUDA.zeros(Float32, 1, actionSpaceSize, batchSize) : zeros(Float32, 1, actionSpaceSize, batchSize) # this mask will replace `reapeat` using broadcasted `+`
    
        # chain working on the graph(s) with the GNNs
        featuredGraph = nn.graphChain(states.fg)
        variableFeatures = featuredGraph.varnf # FxNxB
        valueFeatures = featuredGraph.valnf
        globalFeatures = featuredGraph.gf # GxB
    
        # Extract the features corresponding to the varibales
        variableIndices = Flux.unsqueeze(CartesianIndex.(variableIdx, 1:batchSize), 1)
        branchingVariableFeatures = variableFeatures[:, variableIndices] # Fx1xB

        CorrectbranchingVariableFeatures = reshape([3 1 2 2],2,1,2) #embeddings of the variables [3,1] for x and [2,2] for y
        @test branchingVariableFeatures == CorrectbranchingVariableFeatures

        relevantVariableFeatures = reshape(nn.nodeChain(RL.flatten_batch(branchingVariableFeatures)), :, 1, batchSize) # F'x1xB
    
        # Extract the features corresponding to the values
        relevantValueFeatures = reshape(nn.nodeChain(RL.flatten_batch(valueFeatures)), :, actionSpaceSize, batchSize) # F'xAxB
    
        finalFeatures = nothing
        if sizeof(globalFeatures) != 0
    
            # Extract the global features
            globalFeatures = reshape(nn.globalChain(globalFeatures), :, 1, batchSize) # G'x1xB
    
            # Prepare the input of the outputChain
            finalFeatures = vcat(
                relevantVariableFeatures .+ mask, # F'xAxB
                globalFeatures .+ mask, # G'xAxB
                relevantValueFeatures,
            ) # (F'+G'+F')xAxB
            finalFeatures = RL.flatten_batch(finalFeatures) # (F'+G'+F')x(AxB)
        else
            # Prepare the input of the outputChain
            finalFeatures = vcat(
                relevantVariableFeatures .+ mask, # F'xAxB
                relevantValueFeatures,
            ) # (F'+F')xAxB
            finalFeatures = RL.flatten_batch(finalFeatures) # (F'+F')x(A+B)
        end
    
        # output layer
        predictions = nn.outputChain(finalFeatures) # Ox(A+B)
        output = reshape(predictions, actionSpaceSize, batchSize) # OxAxB
    
        @test output == nn(states)
    end 
end 

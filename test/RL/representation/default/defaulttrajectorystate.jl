approximator_GNN = SeaPearl.GraphConv(64 => 64, Flux.leakyrelu)
target_approximator_GNN = SeaPearl.GraphConv(64 => 64, Flux.leakyrelu)
gnnlayers = 1
approximator_model = SeaPearl.CPNN(
    graphChain = Flux.Chain(
        SeaPearl.GraphConv(3 => 64, Flux.leakyrelu),
        [approximator_GNN for i = 1:gnnlayers]...
    ),
    nodeChain = Flux.Chain(
        Flux.Dense(64, 32, Flux.leakyrelu),
        Flux.Dense(32, 32, Flux.leakyrelu),
        Flux.Dense(32, 16, Flux.leakyrelu),
    ),
    outputChain = Flux.Dense(16, 4),
) |> cpu
target_approximator_model = SeaPearl.CPNN(
    graphChain = Flux.Chain(
        SeaPearl.GraphConv(3 => 64, Flux.leakyrelu),
        [target_approximator_GNN for i = 1:gnnlayers]...
    ),
    nodeChain = Flux.Chain(
        Flux.Dense(64, 32, Flux.leakyrelu),
        Flux.Dense(32, 32, Flux.leakyrelu),
        Flux.Dense(32, 16, Flux.leakyrelu),
    ),
    outputChain = Flux.Dense(16, 4),
) |> cpu
            
agent = RL.Agent(
    policy = RL.QBasedPolicy(
        learner = RL.DQNLearner(
            approximator = RL.NeuralNetworkApproximator(
                model = approximator_model,
                optimizer = ADAM(0.001f0)
            ),
            target_approximator = RL.NeuralNetworkApproximator(
                model = target_approximator_model,
                optimizer = ADAM(0.001f0)
            ),
            loss_func = Flux.Losses.huber_loss,
            stack_size = nothing,
            γ = 0.99f0,
            batch_size = 32,
            update_horizon = 1,
            min_replay_history = 1,
            update_freq = 1,
            target_update_freq = 100,
        ), 
        explorer = RL.EpsilonGreedyExplorer(
            ϵ_stable = 0.01,
            kind = :exp,
            ϵ_init = 1.0,
            warmup_steps = 0,
            decay_steps = 500,
            step = 1,
            is_break_tie = false, 
            #is_training = true,
        )
    ),
    trajectory = RL.CircularArraySLARTTrajectory(
        capacity = 500,
        state = SeaPearl.DefaultTrajectoryState[] => (),
        action = Int => (),
        legal_actions_mask = Vector{Bool} => (4, ),
    )
)

@testset "defaulttrajectorystate.jl" begin
    
    @testset "DefaultTrajectoryState" begin
        graph = Matrix(adjacency_matrix(random_regular_graph(6,3)))
        ts1 = SeaPearl.DefaultTrajectoryState(
            SeaPearl.FeaturedGraph(graph; nf=rand(3,6)),
            2,
            collect(3:6), 
            collect(3:4), 
        )
        ts2 = SeaPearl.DefaultTrajectoryState(
            SeaPearl.FeaturedGraph(graph; nf=rand(3,6)),
            2
        )

        batched1 = ts1 |> cpu
        batched2 = ts2 |> cpu
        @test isa(batched1, SeaPearl.BatchedDefaultTrajectoryState{Float32})

        @test all(ts1.fg.graph .== batched1.fg.graph[:, :, 1])
        @test all(abs.(ts1.fg.nf .- batched1.fg.nf[:,:,1]) .< 1e-5)
        @test ts1.variableIdx == batched1.variableIdx[1]
        @test all(ts1.allValuesIdx .==  batched1.allValuesIdx[:,1])

        @test isnothing(batched2.allValuesIdx)
        @test all(ts2.fg.graph .== batched2.fg.graph[:, :, 1])
        @test all(abs.(ts2.fg.nf .- batched2.fg.nf[:,:,1]) .< 1e-5)
        @test ts2.variableIdx == batched2.variableIdx[1]
    end

    @testset "BatchedFeaturedGraph" begin
        graph = cat(Matrix.(adjacency_matrix.([random_regular_graph(6,3) for i =1:3]))...; dims=3)
        nf = rand(4, 6, 3)
        ef = rand(2, 6, 6, 3)
        gf = rand(2, 3)

        batched1 = SeaPearl.BatchedFeaturedGraph(graph, nf, ef, gf)

        @test isa(batched1, SeaPearl.BatchedFeaturedGraph{Float32})

        batched2 = SeaPearl.BatchedFeaturedGraph{Float32}(graph)

        @test size(batched2.graph) == (6,6,3)
        @test size(batched2.nf) == (0,6,3)
        @test size(batched2.ef) == (0, 6, 6, 3)
        @test size(batched2.gf) == (0,3)
    end

    @testset "BatchedDefaultTrajectoryState" begin
        graph = cat(Matrix.(adjacency_matrix.([random_regular_graph(6, i) for i = 2:4]))...; dims=3)
        bfg = SeaPearl.BatchedFeaturedGraph{Float32}(graph)
        var = collect(1:3)
        val = rand(1:6, 2, 3)
        posval = [rand(1:6, 2) for i in 1:3 ]
        batched = SeaPearl.BatchedDefaultTrajectoryState(bfg, var, val, posval)

        @test isa(batched, SeaPearl.BatchedDefaultTrajectoryState{Float32})

        batched = SeaPearl.BatchedDefaultTrajectoryState{Float32}(fg=bfg, variableIdx=var, possibleValuesIdx = posval)

        @test isnothing(batched.allValuesIdx) 
    end

    # TODO test Flux.functor(::Type{Vector{DefaultTrajectoryState}}, v)
    @testset "Flux.functor(::Type{Vector{DefaultTrajectoryState}}, v)" begin
        graph= Matrix(adjacency_matrix(random_regular_graph(6,3)))
        ts1 = SeaPearl.DefaultTrajectoryState(
            SeaPearl.FeaturedGraph(graph; nf=rand(3,6)),
            2,
            collect(3:6), 
            collect(3:4), 
        )
        ts2 = SeaPearl.DefaultTrajectoryState(
            SeaPearl.FeaturedGraph(graph; nf=rand(3,6)),
            2,
            collect(2:5), 
            collect(2:4), 
        )

        batched1 = [ts1,ts2] |> cpu

        @test isa(batched1, SeaPearl.BatchedDefaultTrajectoryState{Float32})

    end

    @testset "Flux.functor(::Type{BatchedDefaultTrajectoryState{T}}, ts)" begin
        graph = Matrix(adjacency_matrix(random_regular_graph(6,3)))
        ts1 = SeaPearl.DefaultTrajectoryState(
            SeaPearl.FeaturedGraph(graph; nf=rand(3,6)),
            2,
            collect(3:6), 
            collect(3:4), 
        )

        batched = ts1 |> cpu
        batched = batched |> cpu

        @test isa(batched, SeaPearl.BatchedDefaultTrajectoryState{Float32})
    end

     @testset "building trajectoryState from a CPmodel :" begin 

        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        x = SeaPearl.IntVar(2, 3, "x", trailer)
        y = SeaPearl.IntVar(2, 3, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)

        lh = SeaPearl.SimpleLearnedHeuristic{SeaPearl.DefaultStateRepresentation{SeaPearl.DefaultFeaturization,SeaPearl.DefaultTrajectoryState}, SeaPearl.DefaultReward, SeaPearl.VariableOutput}(agent)
        SeaPearl.update_with_cpmodel!(lh, model)

        state = SeaPearl.get_observation!(lh, model, y).state

        @test state.allValuesIdx  == [3,4]

        SeaPearl.addConstraint!(model, SeaPearl.NotEqual(x, y, trailer))

        SeaPearl.update_with_cpmodel!(lh, model)

        state = SeaPearl.get_observation!(lh, model, y).state

        @test state.allValuesIdx  == [4,5] #we added one constraint
        @test state.variableIdx == 3 

        state = SeaPearl.get_observation!(lh, model, x).state
        @test state.variableIdx == 2

    end

    @testset "Advanced test on DefaultTrajectoryState  :" begin     
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        x = SeaPearl.IntVar(2, 3, "x", trailer)
        y = SeaPearl.IntVar(3, 4, "y", trailer)
        z = SeaPearl.IntVar(4, 5, "z", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        SeaPearl.addVariable!(model, z)

        SeaPearl.addConstraint!(model, SeaPearl.NotEqual(x, y, trailer))
        SeaPearl.addConstraint!(model, SeaPearl.NotEqual(y, z, trailer))

        chosen_features = Dict(
        "values_onehot" => false,
        "values_raw" => true,
        )

        lh = SeaPearl.SimpleLearnedHeuristic{SeaPearl.DefaultStateRepresentation{SeaPearl.DefaultFeaturization,SeaPearl.DefaultTrajectoryState}, SeaPearl.DefaultReward, SeaPearl.VariableOutput}(agent; chosen_features=chosen_features)
        
        SeaPearl.update_with_cpmodel!(lh, model, chosen_features=chosen_features)

        state1 = SeaPearl.get_observation!(lh, model, x).state
        batched_state_1 = state1 |> cpu             #create BatchedDefaultTrajectoryState with one sample

        @test batched_state_1.fg.nf[:,batched_state_1.possibleValuesIdx...][4, :] == collect(x.domain)   #retrieve the raw values in the features and compare it the the domain of the variable.
        
        SeaPearl.assign!(x, 2)

        state2 = SeaPearl.get_observation!(lh, model, x).state
        batched_state_2 = state2 |> cpu             #create BatchedDefaultTrajectoryState with one sample

        @test batched_state_2.fg.nf[:,batched_state_2.possibleValuesIdx...][4, :] == collect(x.domain) 
        
        state3 = SeaPearl.get_observation!(lh, model, y).state
        batched_state = [state2,state3] |> cpu      #create BatchedDefaultTrajectoryState with two samples

        @test batched_state.variableIdx == [3,4]
        @test batched_state.fg.nf[:,batched_state.possibleValuesIdx[1] ,1][4, :] == collect(x.domain) 
        @test batched_state.fg.nf[:,batched_state.possibleValuesIdx[2] ,2][4, :] == collect(y.domain)

        @test isa(batched_state_1, SeaPearl.BatchedDefaultTrajectoryState{Float32})
        @test isa(batched_state_2, SeaPearl.BatchedDefaultTrajectoryState{Float32})
        @test isa(batched_state, SeaPearl.BatchedDefaultTrajectoryState{Float32})
    end

end
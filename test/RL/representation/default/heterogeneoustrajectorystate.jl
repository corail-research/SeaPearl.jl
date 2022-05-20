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

@testset "heterogeneoustrajectorystate.jl" begin

    @testset "HeterogeneousTrajectoryState" begin 
        contovar = Matrix([1 1])
        valtovar = Matrix([1 0
                           1 1
                           0 1])
        varnf = rand(4, 2)
        connf = rand(4, 1)
        valnf = rand(4, 3)
        gf = rand(3)
        fg = SeaPearl.HeterogeneousFeaturedGraph(contovar, valtovar, varnf, connf, valnf, gf)
        
        var = 3 #out of bound variable
        val = [1,2]
        @test_throws AssertionError SeaPearl.HeterogeneousTrajectoryState(fg, var, val)

        var = 2 
        val = [1,2,4] #out of bound values
        @test_throws AssertionError SeaPearl.HeterogeneousTrajectoryState(fg, var, val)

        
        var = 2 
        val = [1,2, 2] # one value with unexpected multiplicity 2
        @test_throws AssertionError SeaPearl.HeterogeneousTrajectoryState(fg, var, val)
    end 

    @testset "BatchedHeterogeneousTrajectoryState" begin 
        contovar = cat([1 1], [1 1], dims=3)
        valtovar = cat([1 0; 1 1; 0 1], [1 0; 1 1; 0 1], dims= 3)
        varnf = rand(4, 2, 2)
        connf = rand(4, 1, 2)
        valnf = rand(4, 3, 2)
        gf = rand(3, 2)

        fg = SeaPearl.BatchedHeterogeneousFeaturedGraph{Float32}(contovar, valtovar, varnf, connf, valnf, gf)  

        var = [2,3]
        val = [[1,2, 3],[1,2]]
        @test_throws AssertionError SeaPearl.BatchedHeterogeneousTrajectoryState(fg,var,val)

        var = [2,1]
        val = [[1,2, 3, 4],[1,2]]
        @test_throws AssertionError SeaPearl.BatchedHeterogeneousTrajectoryState(fg,var,val)

        var = [2,1]
        val = [[1,3, 3],[1,2]]
        @test_throws AssertionError SeaPearl.BatchedHeterogeneousTrajectoryState(fg,var,val)
    end 

    @testset "Flux.functor(::Type{<:HeterogeneousTrajectoryState}, s)" begin
        contovar = Matrix([1 1])
        valtovar = Matrix([1 0
                           1 1
                           0 1])
        varnf = rand(4, 2)
        connf = rand(4, 1)
        valnf = rand(4, 3)
        gf = rand(3)
        fg = SeaPearl.HeterogeneousFeaturedGraph(contovar, valtovar, varnf, connf, valnf, gf)
        
        var = 1 #out of bound variable
        val = [1,2]
        hts = SeaPearl.HeterogeneousTrajectoryState(fg, var, val)
        bhts = hts |> cpu

        @test isa(bhts, SeaPearl.BatchedHeterogeneousTrajectoryState)
    end

    @testset "Flux.functor(::Type{Vector{HeterogeneousTrajectoryState}}, v)" begin 
        contovar = Matrix([1 1])
        valtovar = Matrix([1 0
                           1 1
                           0 1])
        varnf = rand(4, 2)
        connf = rand(4, 1)
        valnf = rand(4, 3)
        gf = rand(3)
        fg = SeaPearl.HeterogeneousFeaturedGraph(contovar, valtovar, varnf, connf, valnf, gf)
        
        var = 1 #out of bound variable
        val = [1,2]
        hts1 = SeaPearl.HeterogeneousTrajectoryState(fg, var, val)
        hts2 = SeaPearl.HeterogeneousTrajectoryState(fg, var, val)
        bhts = [hts1,hts2] |> cpu

        @test isa(bhts, SeaPearl.BatchedHeterogeneousTrajectoryState)
    end

    @testset "Flux.functor(::Type{BatchedHeterogeneousTrajectoryState{T}}, ts)" begin
        contovar = Matrix([1 1])
        valtovar = Matrix([1 0
                           1 1
                           0 1])
        varnf = rand(4, 2)
        connf = rand(4, 1)
        valnf = rand(4, 3)
        gf = rand(3)
        fg = SeaPearl.HeterogeneousFeaturedGraph(contovar, valtovar, varnf, connf, valnf, gf)
        
        var = 1 #out of bound variable
        val = [1,2]
        hts = SeaPearl.HeterogeneousTrajectoryState(fg, var, val)
        bhts = hts |> cpu  |> cpu 

        @test isa(bhts, SeaPearl.BatchedHeterogeneousTrajectoryState)
    end

    @testset "advanced testset on BatchedHeterogeneousTrajectoryState" begin

    end
end
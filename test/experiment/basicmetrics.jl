using Flux
using GeometricFlux
#agent declaration
approximator_model = SeaPearl.FlexGNN(
    graphChain = Flux.Chain(
        GeometricFlux.GATConv(3 => 10, heads=2, concat=true),
        GeometricFlux.GATConv(20 => 20, heads=2, concat=false),
    ),
    nodeChain = Flux.Chain(
        Flux.Dense(20, 20),
    ),
    outputLayer = Flux.Dense(20, 2)
)
target_approximator_model = SeaPearl.FlexGNN(
    graphChain = Flux.Chain(
        GeometricFlux.GATConv(3 => 10, heads=2, concat=true),
        GeometricFlux.GATConv(20 => 20, heads=2, concat=false),
    ),
    nodeChain = Flux.Chain(
        Flux.Dense(20, 20),
    ),
    outputLayer = Flux.Dense(20,  2)
)

agent = RL.Agent(
    policy = RL.QBasedPolicy(
        learner = RL.DQNLearner(
            approximator = RL.NeuralNetworkApproximator(
                model = approximator_model,
                optimizer = ADAM(0.0005f0)
            ),
            target_approximator = RL.NeuralNetworkApproximator(
                model = target_approximator_model,
                optimizer = ADAM(0.0005f0)
            ),
            loss_func = Flux.Losses.huber_loss,
            stack_size = nothing,
            γ = 0.9999f0,
            batch_size = 1, #32,
            update_horizon = 25,
            min_replay_history = 1,
            update_freq = 10,
            target_update_freq = 200,
        ), 
        explorer = RL.EpsilonGreedyExplorer(
            ϵ_stable = 0.001,
            kind = :exp,
            ϵ_init = 1.0,
            warmup_steps = 0,
            decay_steps = 5000,
            step = 1,
            is_break_tie = false, 
            #is_training = true,
            rng = MersenneTwister(33)
        )
    ),
    trajectory = RL.CircularArraySARTTrajectory(
        capacity = 8000,
        state = Matrix{Float32} => (5,11),
    )   
)

@testset "basicmetrics.jl" begin
    
    @testset "constructor basicmetrics.jl" begin
        trailer = SeaPearl.Trailer()
        cpmodel = SeaPearl.CPModel(trailer)
        basicheuristic = SeaPearl.BasicHeuristic()
        
        metrics  = SeaPearl.BasicMetrics(cpmodel, basicheuristic)

        
        @test isempty(metrics.nodeVisited)== true
        @test isempty(metrics.meanNodeVisitedUntilOptimality) == true
        @test isempty(metrics.timeneeded) == true
        @test isnothing(metrics.scores) == true
        @test isnothing(metrics.totalReward) == true
        @test isnothing(metrics.loss) == true
        @test metrics.meanOver == 20
        @test metrics.nbEpisodes == 0

        metrics  = SeaPearl.BasicMetrics(cpmodel, basicheuristic;meanOver=100)
        @test metrics.meanOver == 100

        
        trailer = SeaPearl.Trailer()
        cpmodel = SeaPearl.CPModel(trailer)
        x = SeaPearl.IntVar(1, 2, "x", trailer)
        y = SeaPearl.IntVar(1, 2, "y", trailer)

        SeaPearl.addVariable!(cpmodel, x)
        SeaPearl.addVariable!(cpmodel, y)

        basicheuristic = SeaPearl.BasicHeuristic()
        learnedheuristic = SeaPearl.LearnedHeuristic(agent)

        metrics  = SeaPearl.BasicMetrics(cpmodel, basicheuristic)
        @test typeof(metrics) ==  SeaPearl.BasicMetrics{SeaPearl.DontTakeObjective, SeaPearl.BasicHeuristic}

        metrics  = SeaPearl.BasicMetrics(cpmodel, learnedheuristic)
        @test typeof(metrics) ==  SeaPearl.BasicMetrics{SeaPearl.DontTakeObjective, SeaPearl.LearnedHeuristic{SeaPearl.DefaultStateRepresentation, SeaPearl.DefaultReward, SeaPearl.FixedOutput}} 
        @test isnothing(metrics.totalReward) == false
        @test isnothing(metrics.loss) == false 

        SeaPearl.addObjective!(cpmodel,y)

        metrics  = SeaPearl.BasicMetrics(cpmodel, basicheuristic)
        @test typeof(metrics) ==  SeaPearl.BasicMetrics{SeaPearl.TakeObjective, SeaPearl.BasicHeuristic}
        @test isnothing(metrics.scores) == false

        metrics  = SeaPearl.BasicMetrics(cpmodel, learnedheuristic)
        @test typeof(metrics) ==  SeaPearl.BasicMetrics{SeaPearl.TakeObjective, SeaPearl.LearnedHeuristic{SeaPearl.DefaultStateRepresentation, SeaPearl.DefaultReward, SeaPearl.FixedOutput}} 

    end

    @testset "BasicMetrics{DontTakeObjective, BasicHeuristic} " begin
       
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        basicheuristic = SeaPearl.BasicHeuristic()

        x = SeaPearl.IntVar(2, 3, "x", trailer)
        y = SeaPearl.IntVar(2, 3, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        push!(model.constraints, SeaPearl.Equal(x, y, trailer))

        metrics  = SeaPearl.BasicMetrics(model, basicheuristic)
        dt = @elapsed SeaPearl.search!(model, SeaPearl.DFSearch, SeaPearl.MinDomainVariableSelection(), basicheuristic) 
        metrics(model,dt)

        @test metrics.nodeVisited[1] == [2,3]
        @test size(metrics.timeneeded,1) == 1
        @test metrics.nbEpisodes == 1 
        
    end

    @testset "BasicMetrics{DontTakeObjective, LearnedHeuristic}" begin
        
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        learnedheuristic = SeaPearl.LearnedHeuristic(agent)
        x = SeaPearl.IntVar(2, 3, "x", trailer)
        y = SeaPearl.IntVar(2, 3, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        push!(model.constraints, SeaPearl.Equal(x, y, trailer))

        metrics  = SeaPearl.BasicMetrics(model, learnedheuristic)
        dt = @elapsed SeaPearl.search!(model, SeaPearl.DFSearch, SeaPearl.MinDomainVariableSelection(), learnedheuristic) 
        
        metrics(model,dt)


        @test isempty(metrics.nodeVisited) == false #the number of solution found and their relative score depend on the stochastic heuristic...
        @test metrics.nbEpisodes == 1 
        @test size(metrics.timeneeded,1) == 1
        @test size(metrics.totalReward,1) == 1
        @test size(metrics.loss,1) == 1

    end

    @testset "BasicMetrics{TakeObjective, BasicHeuristic}" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        basicheuristic = SeaPearl.BasicHeuristic()

        x = SeaPearl.IntVar(2, 3, "x", trailer)
        y = SeaPearl.IntVar(2, 3, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        push!(model.constraints, SeaPearl.Equal(x, y, trailer))
        SeaPearl.addObjective!(model,y)
        metrics  = SeaPearl.BasicMetrics(model, basicheuristic)
        dt = @elapsed SeaPearl.search!(model, SeaPearl.DFSearch, SeaPearl.MinDomainVariableSelection(), basicheuristic) 
        metrics(model,dt)

        @test metrics.nodeVisited[1] == [2, 3] #only one soluion found due to Objective prunning 
        @test metrics.scores[1] == [1.5, 1.0] #relative to the optimal score
        @test size(metrics.timeneeded,1) == 1
        @test metrics.nbEpisodes == 1 
    end

    @testset "BasicMetrics{TakeObjective, LearnedHeuristic}" begin

        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        learnedheuristic = SeaPearl.LearnedHeuristic(agent)
        x = SeaPearl.IntVar(2, 3, "x", trailer)
        y = SeaPearl.IntVar(2, 3, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        push!(model.constraints, SeaPearl.Equal(x, y, trailer))
        SeaPearl.addObjective!(model,y)

        metrics  = SeaPearl.BasicMetrics(model, learnedheuristic)
        dt = @elapsed SeaPearl.search!(model, SeaPearl.DFSearch, SeaPearl.MinDomainVariableSelection(), learnedheuristic) 
        
        metrics(model,dt)

        @test isempty(metrics.nodeVisited) == false #the number of solution found and their relative score depend on the stochastic heuristic...
        @test isempty(metrics.scores) == false 
        @test metrics.nbEpisodes == 1 
        @test size(metrics.timeneeded,1) == 1
        @test size(metrics.totalReward,1) == 1
        @test size(metrics.loss,1) == 1
    end

    @testset "test !" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        basicheuristic = SeaPearl.BasicHeuristic()
        metrics  = SeaPearl.BasicMetrics(model, basicheuristic; meanOver=4)

        push!(metrics.nodeVisited, [10,0])
        push!(metrics.nodeVisited, [10,0])
        push!(metrics.nodeVisited, [10,0])
        push!(metrics.nodeVisited, [10,0])
        push!(metrics.nodeVisited, [0,10])
        push!(metrics.nodeVisited, [0,10])
        push!(metrics.nodeVisited, [0,10])
        push!(metrics.nodeVisited, [0,10])

        push!(metrics.meanNodeVisitedUntilOptimality, 0)
        push!(metrics.meanNodeVisitedUntilOptimality, 0)
        push!(metrics.meanNodeVisitedUntilOptimality, 0)
        push!(metrics.meanNodeVisitedUntilOptimality, 0)
        push!(metrics.meanNodeVisitedUntilOptimality, 10)
        push!(metrics.meanNodeVisitedUntilOptimality, 10)
        push!(metrics.meanNodeVisitedUntilOptimality, 10)
        push!(metrics.meanNodeVisitedUntilOptimality, 10)
        
        metrics.nbEpisodes = 8
        SeaPearl.computemean!(metrics)
        @test metrics.meanNodeVisitedUntilfirstSolFound == [10.0, 7.5, 5.0, 2.5, 0.0]
        @test metrics.meanNodeVisitedUntilOptimality == [0.0, 2.5, 5.0, 7.5, 10.0]

    end
end
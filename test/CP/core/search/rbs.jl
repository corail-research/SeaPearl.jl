@testset "rbs.jl" begin
    @testset "expandRbs!()" begin
        ### Checking status ###
        # :NodeLimitStop
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        model.limit.numberOfNodes = 1
        toCall = Stack{Function}()
        @test SeaPearl.expandRbs!(toCall, model, 1, SeaPearl.MinDomainVariableSelection(), SeaPearl.BasicHeuristic()) == :NodeLimitStop
        @test isempty(toCall)

        # :SolutionLimitStop
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        model.limit.numberOfSolutions = 0
        
        toCall = Stack{Function}()
        @test SeaPearl.expandRbs!(toCall, model, 1, SeaPearl.MinDomainVariableSelection(), SeaPearl.BasicHeuristic()) == :SolutionLimitStop
        @test isempty(toCall)

        # :Infeasible
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        
        x = SeaPearl.IntVar(2, 2, "x", trailer)
        y = SeaPearl.IntVar(3, 3, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        push!(model.constraints, SeaPearl.Equal(x, y, trailer))

        toCall = Stack{Function}()
        @test SeaPearl.expandRbs!(toCall, model, 1, SeaPearl.MinDomainVariableSelection(), SeaPearl.BasicHeuristic()) == :Infeasible
        @test isempty(toCall)

        # :Feasible
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        
        x = SeaPearl.IntVar(2, 2, "x", trailer)
        y = SeaPearl.IntVar(2, 2, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        push!(model.constraints, SeaPearl.Equal(x, y, trailer))

        toCall = Stack{Function}()
        @test SeaPearl.expandRbs!(toCall, model, 1, SeaPearl.MinDomainVariableSelection(), SeaPearl.BasicHeuristic()) == :FoundSolution
        @test isempty(toCall)


        ### Checking stack ###
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        
        x = SeaPearl.IntVar(2, 3, "x", trailer)
        y = SeaPearl.IntVar(2, 3, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        push!(model.constraints, SeaPearl.Equal(x, y, trailer))

        toCall = Stack{Function}()
        @test SeaPearl.expandRbs!(toCall, model, 1, SeaPearl.MinDomainVariableSelection(), SeaPearl.BasicHeuristic()) == :Feasible
        @test length(toCall) == 6

        @test pop!(toCall)(model) == :SavingState
        @test length(model.trailer.prior) == 1 # saveState!()

        @test pop!(toCall)(model) == :FoundSolution
        @test length(model.statistics.solutions) == 1 # Found a solution

        @test pop!(toCall)(model) == :BackTracking
        @test length(model.trailer.prior) == 0 # restoreState!()

        @test pop!(toCall)(model) == :SavingState
        @test length(model.trailer.prior) == 1 # saveState!()

        @test pop!(toCall)(model) == :FoundSolution
        @test length(model.statistics.solutions) == 2 # Found another solution

        @test pop!(toCall)(model) == :BackTracking
        @test length(model.trailer.prior) == 0 # restoreState!()
    end

    @testset "initroot(::staticRBSearch)" begin
        # :Feasible
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        
        x = SeaPearl.IntVar(2, 2, "x", trailer)
        y = SeaPearl.IntVar(2, 2, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        push!(model.constraints, SeaPearl.Equal(x, y, trailer))

        toCall = Stack{Function}()
        @test SeaPearl.initroot!(toCall, SeaPearl.staticRBSearch(10, 5), model, SeaPearl.MinDomainVariableSelection(), SeaPearl.BasicHeuristic()) == :FoundSolution
        @test length(toCall) == 4
        @test pop!(toCall).nodeLimit == 10
        @test pop!(toCall).nodeLimit == 10
        @test pop!(toCall).nodeLimit == 10
        @test pop!(toCall).nodeLimit == 10

    end

    @testset "initroot(::geometricRBSearch)" begin
        # :Feasible
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        
        x = SeaPearl.IntVar(2, 2, "x", trailer)
        y = SeaPearl.IntVar(2, 2, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        push!(model.constraints, SeaPearl.Equal(x, y, trailer))

        toCall = Stack{Function}()
        @test SeaPearl.initroot!(toCall, SeaPearl.geometricRBSearch(10, 5, 1.1), model, SeaPearl.MinDomainVariableSelection(), SeaPearl.BasicHeuristic())== :FoundSolution
        @test length(toCall) == 4
        @test pop!(toCall).Limit == 11
        @test pop!(toCall).Limit == 13
        @test pop!(toCall).Limit == 14
        @test pop!(toCall).Limit == 15

        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        
        x = SeaPearl.IntVar(2, 2, "x", trailer)
        y = SeaPearl.IntVar(2, 2, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        push!(model.constraints, SeaPearl.Equal(x, y, trailer))

        toCall = Stack{Function}()
        @test SeaPearl.initroot!(toCall, SeaPearl.geometricRBSearch(10, 1, 1.1), model, SeaPearl.MinDomainVariableSelection(), SeaPearl.BasicHeuristic())== :FoundSolution
        @test isempty(toCall) 
    end

    @testset "initroot(::lubyRBSearch)" begin   # The Luby sequence is a sequence of the following form: 1,1,2,1,1,2,4,1,1,2,1,1,2,4,8, . .
        # :Feasible   
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        
        x = SeaPearl.IntVar(2, 2, "x", trailer)
        y = SeaPearl.IntVar(2, 2, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        push!(model.constraints, SeaPearl.Equal(x, y, trailer))

        toCall = Stack{Function}()
        @test SeaPearl.initroot!(toCall, SeaPearl.lubyRBSearch(10,5), model, SeaPearl.MinDomainVariableSelection(), SeaPearl.BasicHeuristic())== :FoundSolution
        @test length(toCall) == 4
        @test pop!(toCall).Limit == 10
        @test pop!(toCall).Limit == 20
        @test pop!(toCall).Limit == 10
        @test pop!(toCall).Limit == 10

        @test SeaPearl.Luby(31)==[1,1,2,1,1,2,4,1,1,2,1,1,2,4,8,1,1,2,1,1,2,4,1,1,2,1,1,2,4,8,16]
    end
    
    @testset "search!(::RBSearch)" begin
        ### Checking status ###
        # :LimitStop
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        model.limit.numberOfNodes = 1
        @test SeaPearl.search!(model, SeaPearl.staticRBSearch(10,10), SeaPearl.MinDomainVariableSelection()) == :NodeLimitStop

        # :SolutionLimitStop
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        model.limit.numberOfSolutions = 0
        
        x = SeaPearl.IntVar(2, 3, "x", trailer)
        y = SeaPearl.IntVar(2, 3, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        @test SeaPearl.search!(model, SeaPearl.staticRBSearch(10,10), SeaPearl.MinDomainVariableSelection()) == :SolutionLimitStop

        # :Infeasible
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        
        x = SeaPearl.IntVar(2, 2, "x", trailer)
        y = SeaPearl.IntVar(3, 3, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        push!(model.constraints, SeaPearl.Equal(x, y, trailer))

        @test SeaPearl.search!(model, SeaPearl.staticRBSearch(10,10), SeaPearl.MinDomainVariableSelection()) == :Infeasible

        # :Optimal
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        
        x = SeaPearl.IntVar(2, 2, "x", trailer)
        y = SeaPearl.IntVar(2, 2, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        push!(model.constraints, SeaPearl.Equal(x, y, trailer))
        @test SeaPearl.search!(model, SeaPearl.staticRBSearch(10,10), SeaPearl.MinDomainVariableSelection()) == :Optimal
        @test length(model.statistics.solutions) == 1


        ### Checking more complex solutions ###
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        
        x = SeaPearl.IntVar(2, 3, "x", trailer)
        y = SeaPearl.IntVar(2, 3, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        push!(model.constraints, SeaPearl.Equal(x, y, trailer))

        @test SeaPearl.search!(model, SeaPearl.staticRBSearch(10,10), SeaPearl.MinDomainVariableSelection()) == :Optimal
        @test length(model.statistics.solutions) == 2
        @test model.statistics.solutions[1] == Dict("x" => 3,"y" => 3)
        @test model.statistics.solutions[2] == Dict("x" => 2,"y" => 2)

    end

    @testset "search!() with a BasicHeuristic" begin

        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        
        x = SeaPearl.IntVar(2, 3, "x", trailer)
        y = SeaPearl.IntVar(2, 3, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        push!(model.constraints, SeaPearl.Equal(x, y, trailer))

        @test SeaPearl.search!(model, SeaPearl.staticRBSearch(10,10), SeaPearl.MinDomainVariableSelection(), SeaPearl.BasicHeuristic()) == :Optimal
        @test model.statistics.solutions[1] == Dict("x" => 3,"y" => 3)
        @test model.statistics.solutions[2] == Dict("x" => 2,"y" => 2)

        SeaPearl.empty!(model)

        x = SeaPearl.IntVar(2, 3, "x", model.trailer)
        y = SeaPearl.IntVar(2, 3, "y", model.trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        push!(model.constraints, SeaPearl.Equal(x, y, model.trailer))

        my_heuristic(x::SeaPearl.IntVar; cpmodel=nothing) = minimum(x.domain)
        @test SeaPearl.search!(model, SeaPearl.staticRBSearch(10,10), SeaPearl.MinDomainVariableSelection(), SeaPearl.BasicHeuristic(my_heuristic)) == :Optimal
        @test model.statistics.solutions[1] == Dict("x" => 2,"y" => 2)
        @test model.statistics.solutions[2] == Dict("x" => 3,"y" => 3)

    end

    @testset "search!() with a BasicHeuristic - out_solver being true" begin

        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        
        x = SeaPearl.IntVar(2, 3, "x", trailer)
        y = SeaPearl.IntVar(2, 3, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        push!(model.constraints, SeaPearl.Equal(x, y, trailer))

        @test SeaPearl.search!(model, SeaPearl.staticRBSearch(10,10), SeaPearl.MinDomainVariableSelection(), SeaPearl.BasicHeuristic(); out_solver=true) == :FoundSolution
        @test length(model.statistics.solutions) == 1
        @test model.statistics.solutions[1] == Dict("x" => 3,"y" => 3)

        SeaPearl.empty!(model)

        x = SeaPearl.IntVar(2, 3, "x", model.trailer)
        y = SeaPearl.IntVar(2, 3, "y", model.trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        push!(model.constraints, SeaPearl.Equal(x, y, model.trailer))

        my_heuristic(x::SeaPearl.IntVar; cpmodel=nothing) = minimum(x.domain)
        @test SeaPearl.search!(model, SeaPearl.staticRBSearch(10,10), SeaPearl.MinDomainVariableSelection(), SeaPearl.BasicHeuristic(my_heuristic); out_solver=true) == :FoundSolution
        @test length(model.statistics.solutions) == 1
        @test model.statistics.solutions[1] == Dict("x" => 2,"y" => 2)

    end

    @testset "search!() with PPO/RBS" begin

    using Random
    approximator_GNN = GeometricFlux.GraphConv(64 => 64, Flux.leakyrelu)
    target_approximator_GNN = GeometricFlux.GraphConv(64 => 64, Flux.leakyrelu)
    gnnlayers = 10
    seed = 123
    rng = MersenneTwister(seed)
    
    actor_approximator = SeaPearl.FlexGNN(
        graphChain = Flux.Chain(
            GeometricFlux.GraphConv(numInFeatures => 64, Flux.leakyrelu),
            [approximator_GNN for i = 1:gnnlayers]...
        ),
        nodeChain = Flux.Chain(
            Flux.Dense(64, 32, Flux.leakyrelu; initW = glorot_uniform(rng)),
            Flux.Dense(32, 32, Flux.leakyrelu; initW = glorot_uniform(rng)),
            Flux.Dense(32, 16, Flux.leakyrelu; initW = glorot_uniform(rng)),
        ),
        outputLayer = Flux.Dense(16, 4; initW = glorot_uniform(rng)),
    ) 
    critic_approximator = SeaPearl.FlexGNN(
        graphChain = Flux.Chain(
            GeometricFlux.GraphConv(numInFeatures => 64, Flux.leakyrelu),
            [target_approximator_GNN for i = 1:gnnlayers]...
        ),
        nodeChain = Flux.Chain(
            Flux.Dense(64, 32, Flux.leakyrelu; initW = glorot_uniform(rng)),
            Flux.Dense(32, 32, Flux.leakyrelu; initW = glorot_uniform(rng)),
            Flux.Dense(32, 16, Flux.leakyrelu; initW = glorot_uniform(rng)),
        ),
        outputLayer = Flux.Dense(16, 1; initW = glorot_uniform(rng)),
    ) 
        
                
    UPDATE_FREQ = 1

    # Agent definition
    agent = RL.Agent(
        policy = RL.QBasedPolicy(
            learner = RL.A2CLearner(
                approximator =RL.ActorCritic(
                    actor = actor_approximator,
                    critic = critic_approximator,
                    optimizer = ADAM(1e-3),
                ) |> cpu,
                γ = 0.99f0,
                actor_loss_weight = 1.0f0,
                critic_loss_weight = 0.5f0,
                entropy_loss_weight = 0.001f0,
                update_freq = UPDATE_FREQ,
            
            ),
            explorer = GumbelSoftmaxExplorer(),
            ),        
        trajectory = RL.CircularArraySARTTrajectory(
            capacity = 8,
            state = SeaPearl.DefaultTrajectoryState => (),
            action = Vector{Int} => (1,),
            reward = Vector{Float32} => (1,),
            terminal = Vector{Bool} => (1,),
        )
    )
        
        # define the value selection
        valueSelection = SeaPearl.LearnedHeuristic(agent)

        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        x1 = SeaPearl.IntVar(1, 2, "x1", trailer)
        x2 = SeaPearl.IntVar(1, 2, "x2", trailer)
        x3 = SeaPearl.IntVar(2, 3, "x3", trailer)
        x4 = SeaPearl.IntVar(1, 4, "x4", trailer)
        SeaPearl.addVariable!(model, x1)
        SeaPearl.addVariable!(model, x2)
        SeaPearl.addVariable!(model, x3)
        SeaPearl.addVariable!(model, x4)

        push!(model.constraints, SeaPearl.NotEqual(x1, x2, trailer))
        push!(model.constraints, SeaPearl.NotEqual(x2, x3, trailer))
        push!(model.constraints, SeaPearl.NotEqual(x3, x4, trailer))

        # define the variable selection
        variableSelection = SeaPearl.MinDomainVariableSelection()

        # launch the search 
        SeaPearl.search!(model, SeaPearl.geometricRBSearch(3,10,1.1), variableSelection, valueSelection)

        possible_solutions = [
            Dict("x1" => 1, "x2" => 2, "x3" => 3, "x4" => 1),
            Dict("x1" => 1, "x2" => 2, "x3" => 3, "x4" => 2),
            Dict("x1" => 1, "x2" => 2, "x3" => 3, "x4" => 4),
            Dict("x1" => 2, "x2" => 1, "x3" => 3, "x4" => 1),
            Dict("x1" => 2, "x2" => 1, "x3" => 3, "x4" => 2),
            Dict("x1" => 2, "x2" => 1, "x3" => 3, "x4" => 4),
            Dict("x1" => 2, "x2" => 1, "x3" => 2, "x4" => 1),
            Dict("x1" => 2, "x2" => 1, "x3" => 2, "x4" => 3),
            Dict("x1" => 2, "x2" => 1, "x3" => 2, "x4" => 4)
        ]

        for solution in model.statistics.solutions
            @test solution in possible_solutions
        end

    end

    @testset "search!() with a PPO/RBS" begin

   
        using Random
        approximator_GNN = GeometricFlux.GraphConv(64 => 64, Flux.leakyrelu)
        target_approximator_GNN = GeometricFlux.GraphConv(64 => 64, Flux.leakyrelu)
        gnnlayers = 10
        seed = 123
        rng = MersenneTwister(seed)
        
        actor_approximator = SeaPearl.FlexGNN(
            graphChain = Flux.Chain(
                GeometricFlux.GraphConv(numInFeatures => 64, Flux.leakyrelu),
                [approximator_GNN for i = 1:gnnlayers]...
            ),
            nodeChain = Flux.Chain(
                Flux.Dense(64, 32, Flux.leakyrelu; initW = glorot_uniform(rng)),
                Flux.Dense(32, 32, Flux.leakyrelu; initW = glorot_uniform(rng)),
                Flux.Dense(32, 16, Flux.leakyrelu; initW = glorot_uniform(rng)),
            ),
            outputLayer = Flux.Dense(16, 4; initW = glorot_uniform(rng)),
        ) 
        critic_approximator = SeaPearl.FlexGNN(
            graphChain = Flux.Chain(
                GeometricFlux.GraphConv(numInFeatures => 64, Flux.leakyrelu),
                [target_approximator_GNN for i = 1:gnnlayers]...
            ),
            nodeChain = Flux.Chain(
                Flux.Dense(64, 32, Flux.leakyrelu; initW = glorot_uniform(rng)),
                Flux.Dense(32, 32, Flux.leakyrelu; initW = glorot_uniform(rng)),
                Flux.Dense(32, 16, Flux.leakyrelu; initW = glorot_uniform(rng)),
            ),
            outputLayer = Flux.Dense(16, 1; initW = glorot_uniform(rng)),
        ) 
            
                    
        UPDATE_FREQ = 1
    
        # Agent definition
        agent = RL.Agent(
            policy = RL.QBasedPolicy(
                learner = RL.A2CLearner(
                    approximator =RL.ActorCritic(
                        actor = actor_approximator,
                        critic = critic_approximator,
                        optimizer = ADAM(1e-3),
                    ) |> cpu,
                    γ = 0.99f0,
                    actor_loss_weight = 1.0f0,
                    critic_loss_weight = 0.5f0,
                    entropy_loss_weight = 0.001f0,
                    update_freq = UPDATE_FREQ,
                
                ),
                explorer = GumbelSoftmaxExplorer(),
                ),        
            trajectory = RL.CircularArraySARTTrajectory(
                capacity = 8,
                state = SeaPearl.DefaultTrajectoryState => (),
                action = Vector{Int} => (1,),
                reward = Vector{Float32} => (1,),
                terminal = Vector{Bool} => (1,),
            )
        )

        # define the value selection
        valueSelection = SeaPearl.LearnedHeuristic(agent)

        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        x1 = SeaPearl.IntVar(1, 2, "x1", trailer)
        x2 = SeaPearl.IntVar(1, 2, "x2", trailer)
        x3 = SeaPearl.IntVar(2, 3, "x3", trailer)
        x4 = SeaPearl.IntVar(1, 4, "x4", trailer)
        SeaPearl.addVariable!(model, x1)
        SeaPearl.addVariable!(model, x2)
        SeaPearl.addVariable!(model, x3)
        SeaPearl.addVariable!(model, x4)

        push!(model.constraints, SeaPearl.NotEqual(x1, x2, trailer))
        push!(model.constraints, SeaPearl.NotEqual(x2, x3, trailer))
        push!(model.constraints, SeaPearl.NotEqual(x3, x4, trailer))

        # define the variable selection
        variableSelection = SeaPearl.MinDomainVariableSelection()

        # launch the search 
        SeaPearl.search!(model, SeaPearl.geometricRBSearch(3,10,1.1), variableSelection, valueSelection; out_solver=true)

        possible_solutions = [
            Dict("x1" => 1, "x2" => 2, "x3" => 3, "x4" => 1),
            Dict("x1" => 1, "x2" => 2, "x3" => 3, "x4" => 2),
            Dict("x1" => 1, "x2" => 2, "x3" => 3, "x4" => 4),
            Dict("x1" => 2, "x2" => 1, "x3" => 3, "x4" => 1),
            Dict("x1" => 2, "x2" => 1, "x3" => 3, "x4" => 2),
            Dict("x1" => 2, "x2" => 1, "x3" => 3, "x4" => 4),
            Dict("x1" => 2, "x2" => 1, "x3" => 2, "x4" => 1),
            Dict("x1" => 2, "x2" => 1, "x3" => 2, "x4" => 3),
            Dict("x1" => 2, "x2" => 1, "x3" => 2, "x4" => 4)
        ]

        for solution in model.statistics.solutions
            @test solution in possible_solutions
        end

    end

    @testset "advanced test for RBS" begin 

    end

end

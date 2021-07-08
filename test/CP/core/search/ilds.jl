@testset "ilds.jl" begin
    @testset "expandIlds!()" begin
        ### Checking status ###
        # :NodeLimitStop
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        model.limit.numberOfNodes = 1
        toCall = Stack{Function}()
        @test SeaPearl.expandIlds!(toCall,0, model, SeaPearl.MinDomainVariableSelection(), SeaPearl.BasicHeuristic(),nothing) == :NodeLimitStop
        @test isempty(toCall)

        # :SolutionLimitStop
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        model.limit.numberOfSolutions = 0
        
        toCall = Stack{Function}()
        @test SeaPearl.expandIlds!(toCall,0, model, SeaPearl.MinDomainVariableSelection(), SeaPearl.BasicHeuristic(),nothing) == :SolutionLimitStop
        @test isempty(toCall)

        # :Infeasible
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        
        x = SeaPearl.IntVar(2, 2, "x", trailer)
        y = SeaPearl.IntVar(3, 3, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        SeaPearl.addConstraint!(model, SeaPearl.Equal(x, y, trailer))

        toCall = Stack{Function}()
        @test SeaPearl.expandIlds!(toCall,0, model, SeaPearl.MinDomainVariableSelection(), SeaPearl.BasicHeuristic(),nothing) == :Infeasible
        @test isempty(toCall)

        # :Feasible
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        
        x = SeaPearl.IntVar(2, 2, "x", trailer)
        y = SeaPearl.IntVar(2, 2, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        SeaPearl.addConstraint!(model, SeaPearl.Equal(x, y, trailer))

        toCall = Stack{Function}()
        @test SeaPearl.expandIlds!(toCall,0, model, SeaPearl.MinDomainVariableSelection(), SeaPearl.BasicHeuristic(),nothing) == :FoundSolution
        @test isempty(toCall)


        ### Checking stack ###
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        
        x = SeaPearl.IntVar(2, 3, "x", trailer)
        y = SeaPearl.IntVar(2, 3, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        SeaPearl.addConstraint!(model, SeaPearl.Equal(x, y, trailer))

        toCall = Stack{Function}()
        @test SeaPearl.expandIlds!(toCall,0, model, SeaPearl.MinDomainVariableSelection(), SeaPearl.BasicHeuristic(),nothing) == :Feasible
        @test length(toCall) == 3

        @test pop!(toCall)(model) == :SavingState
        @test length(model.trailer.prior) == 1 # saveState!()

        @test pop!(toCall)(model) == :FoundSolution
        @test length(model.statistics.solutions) == 1 # Found a solution

        @test pop!(toCall)(model) == :BackTracking
        @test length(model.trailer.prior) == 0 # restoreState!()
    end

    @testset "initroot(::ILDSearch)" begin
        # :Feasible
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        
        x = SeaPearl.IntVar(2, 2, "x", trailer)
        y = SeaPearl.IntVar(2, 2, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        SeaPearl.addConstraint!(model, SeaPearl.Equal(x, y, trailer))

        toCall = Stack{Function}()
        @test SeaPearl.initroot!(toCall, SeaPearl.ILDSearch(0), model, SeaPearl.MinDomainVariableSelection(), SeaPearl.BasicHeuristic()) == :FoundSolution
        @test isempty(toCall)

    end
    
    @testset "search!(::ILDSearch)" begin
        ### Checking status ###
        # :LimitStop
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        model.limit.numberOfNodes = 1
        x = SeaPearl.IntVar(1, 1, "x", trailer)
        SeaPearl.addVariable!(model, x)

        @test SeaPearl.search!(model, SeaPearl.ILDSearch(0), SeaPearl.MinDomainVariableSelection()) == :NodeLimitStop

        # :SolutionLimitStop
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        model.limit.numberOfSolutions = 0
        
        x = SeaPearl.IntVar(2, 3, "x", trailer)
        y = SeaPearl.IntVar(2, 3, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        @test SeaPearl.search!(model, SeaPearl.ILDSearch(0), SeaPearl.MinDomainVariableSelection()) == :SolutionLimitStop

        # :Infeasible
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        
        x = SeaPearl.IntVar(2, 2, "x", trailer)
        y = SeaPearl.IntVar(3, 3, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        SeaPearl.addConstraint!(model, SeaPearl.Equal(x, y, trailer))

        @test SeaPearl.search!(model, SeaPearl.ILDSearch(0), SeaPearl.MinDomainVariableSelection()) == :Infeasible

        # :Optimal
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        
        x = SeaPearl.IntVar(2, 2, "x", trailer)
        y = SeaPearl.IntVar(2, 2, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        SeaPearl.addConstraint!(model, SeaPearl.Equal(x, y, trailer))

        @test SeaPearl.search!(model, SeaPearl.ILDSearch(0), SeaPearl.MinDomainVariableSelection()) == :NonOptimal
        @test length(model.statistics.solutions) == 1


        ### Checking more complex statistics.solutions ###
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        
        x = SeaPearl.IntVar(2, 3, "x", trailer)
        y = SeaPearl.IntVar(2, 3, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        SeaPearl.addConstraint!(model, SeaPearl.Equal(x, y, trailer))

        @test SeaPearl.search!(model, SeaPearl.ILDSearch(1), SeaPearl.MinDomainVariableSelection()) == :NonOptimal
        @test length(model.statistics.solutions) == 2
        @test model.statistics.solutions[2] == Dict("x" => 2,"y" => 2)
        @test model.statistics.solutions[1] == Dict("x" => 3,"y" => 3)

    end

    @testset "search!() with a BasicHeuristic" begin

        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        
        x = SeaPearl.IntVar(2, 3, "x", trailer)
        y = SeaPearl.IntVar(2, 3, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        SeaPearl.addConstraint!(model, SeaPearl.Equal(x, y, trailer))

        @test SeaPearl.search!(model, SeaPearl.ILDSearch(1), SeaPearl.MinDomainVariableSelection(), SeaPearl.BasicHeuristic()) == :NonOptimal
        @test model.statistics.solutions[2] == Dict("x" => 2,"y" => 2)
        @test model.statistics.solutions[1] == Dict("x" => 3,"y" => 3)

        SeaPearl.empty!(model)

        x = SeaPearl.IntVar(2, 3, "x", model.trailer)
        y = SeaPearl.IntVar(2, 3, "y", model.trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        SeaPearl.addConstraint!(model, SeaPearl.Equal(x, y, model.trailer))

        my_heuristic(x::SeaPearl.IntVar; cpmodel=nothing) = minimum(x.domain)
        @test SeaPearl.search!(model, SeaPearl.ILDSearch(1), SeaPearl.MinDomainVariableSelection(), SeaPearl.BasicHeuristic(my_heuristic)) == :NonOptimal
        @test model.statistics.solutions[2] == Dict("x" => 3,"y" => 3)

        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        
        x1 = SeaPearl.IntVar(1, 2, "x1", trailer)
        x2 = SeaPearl.IntVar(1, 3, "x2", trailer)
        x3 = SeaPearl.IntVar(2, 4, "x3", trailer)
        SeaPearl.addVariable!(model, x1)
        SeaPearl.addVariable!(model, x2)
        SeaPearl.addVariable!(model, x3)

        SeaPearl.addConstraint!(model, SeaPearl.NotEqual(x1, x2, trailer))
        SeaPearl.addConstraint!(model, SeaPearl.NotEqual(x2, x3, trailer))
        @test SeaPearl.search!(model, SeaPearl.ILDSearch(3), SeaPearl.MinDomainVariableSelection(), SeaPearl.BasicHeuristic()) == :NonOptimal


        #in this specific finding order with the given heuristic and iLDS method.
        @test model.statistics.solutions[1] == Dict("x1" => 2,"x2" => 3,"x3" => 4)
        @test model.statistics.solutions[2] == Dict("x1" => 2,"x2" => 3,"x3" => 2)
        @test model.statistics.solutions[3] == Dict("x1" => 2,"x2" => 1,"x3" => 4)
        @test model.statistics.solutions[4] == Dict("x1" => 1,"x2" => 3,"x3" => 4)
        @test model.statistics.solutions[5] == Dict("x1" => 2,"x2" => 1,"x3" => 3)
        @test model.statistics.solutions[6] == Dict("x1" => 1,"x2" => 3,"x3" => 2)
        @test model.statistics.solutions[7] == Dict("x1" => 1,"x2" => 2,"x3" => 4)
        @test model.statistics.solutions[8] == Dict("x1" => 2,"x2" => 1,"x3" => 2)
        @test model.statistics.solutions[9] == Dict("x1" => 1,"x2" => 2,"x3" => 3)

    end
    @testset "search!() with a BasicHeuristic - out_solver being true" begin

        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        
        x = SeaPearl.IntVar(2, 3, "x", trailer)
        y = SeaPearl.IntVar(2, 3, "y", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        SeaPearl.addConstraint!(model, SeaPearl.Equal(x, y, trailer))

        @test SeaPearl.search!(model, SeaPearl.ILDSearch(1), SeaPearl.MinDomainVariableSelection(), SeaPearl.BasicHeuristic(); out_solver=true) == :FoundSolution
        @test length(model.statistics.solutions) == 1
        @test model.statistics.solutions[1] == Dict("x" => 3,"y" => 3)

        SeaPearl.empty!(model)

        x = SeaPearl.IntVar(2, 3, "x", model.trailer)
        y = SeaPearl.IntVar(2, 3, "y", model.trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        SeaPearl.addConstraint!(model, SeaPearl.Equal(x, y, model.trailer))

        my_heuristic(x::SeaPearl.IntVar; cpmodel=nothing) = minimum(x.domain)
        @test SeaPearl.search!(model, SeaPearl.ILDSearch(1), SeaPearl.MinDomainVariableSelection(), SeaPearl.BasicHeuristic(my_heuristic); out_solver=true) == :FoundSolution
        @test length(model.statistics.solutions) == 1
        @test model.statistics.solutions[1] == Dict("x" => 2,"y" => 2)

    end

    @testset "search!() with a LearnedHeuristic I" begin

 
        approximator_GNN = GeometricFlux.GraphConv(64 => 64, Flux.leakyrelu)
        target_approximator_GNN = GeometricFlux.GraphConv(64 => 64, Flux.leakyrelu)
        gnnlayers = 1
        approximator_model = SeaPearl.CPNN(
            graphChain = Flux.Chain(
                GeometricFlux.GraphConv(3 => 64, Flux.leakyrelu),
                [approximator_GNN for i = 1:gnnlayers]...
            ),
            nodeChain = Flux.Chain(
                Flux.Dense(64, 32, Flux.leakyrelu),
                Flux.Dense(32, 32, Flux.leakyrelu),
                Flux.Dense(32, 16, Flux.leakyrelu),
            ),
            outputChain = Flux.Dense(16, 4),
        ) 
        target_approximator_model = SeaPearl.CPNN(
            graphChain = Flux.Chain(
                GeometricFlux.GraphConv(3 => 64, Flux.leakyrelu),
                [target_approximator_GNN for i = 1:gnnlayers]...
            ),
            nodeChain = Flux.Chain(
                Flux.Dense(64, 32, Flux.leakyrelu),
                Flux.Dense(32, 32, Flux.leakyrelu),
                Flux.Dense(32, 16, Flux.leakyrelu),
            ),
            outputChain = Flux.Dense(16, 4),
        ) 
                    
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
                    rng = MersenneTwister(33)
                )
            ),
            trajectory = RL.CircularArraySLARTTrajectory(
                capacity = 500,
                state = SeaPearl.DefaultTrajectoryState[] => (),
                action = Int => (),
                legal_actions_mask = Vector{Bool} => (4, ),
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

        SeaPearl.addConstraint!(model, SeaPearl.NotEqual(x1, x2, trailer))
        SeaPearl.addConstraint!(model, SeaPearl.NotEqual(x2, x3, trailer))
        SeaPearl.addConstraint!(model, SeaPearl.NotEqual(x3, x4, trailer))

        # define the variable selection
        variableSelection = SeaPearl.MinDomainVariableSelection()

        # launch the search 
        SeaPearl.search!(model, SeaPearl.ILDSearch(6), variableSelection, valueSelection)

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

    @testset "search!() with a LearnedHeuristic out of the solver" begin


        approximator_GNN = GeometricFlux.GraphConv(64 => 64, Flux.leakyrelu)
        target_approximator_GNN = GeometricFlux.GraphConv(64 => 64, Flux.leakyrelu)
        gnnlayers = 1
        approximator_model = SeaPearl.CPNN(
            graphChain = Flux.Chain(
                GeometricFlux.GraphConv(3 => 64, Flux.leakyrelu),
                [approximator_GNN for i = 1:gnnlayers]...
            ),
            nodeChain = Flux.Chain(
                Flux.Dense(64, 32, Flux.leakyrelu),
                Flux.Dense(32, 32, Flux.leakyrelu),
                Flux.Dense(32, 16, Flux.leakyrelu),
            ),
            outputChain = Flux.Dense(16, 4),
        ) 
        target_approximator_model = SeaPearl.CPNN(
            graphChain = Flux.Chain(
                GeometricFlux.GraphConv(3 => 64, Flux.leakyrelu),
                [target_approximator_GNN for i = 1:gnnlayers]...
            ),
            nodeChain = Flux.Chain(
                Flux.Dense(64, 32, Flux.leakyrelu),
                Flux.Dense(32, 32, Flux.leakyrelu),
                Flux.Dense(32, 16, Flux.leakyrelu),
            ),
            outputChain = Flux.Dense(16, 4),
        ) 
                    
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
                    rng = MersenneTwister(33)
                )
            ),
            trajectory = RL.CircularArraySLARTTrajectory(
                capacity = 500,
                state = SeaPearl.DefaultTrajectoryState[] => (),
                action = Int => (),
                legal_actions_mask = Vector{Bool} => (4, ),
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

        SeaPearl.addConstraint!(model, SeaPearl.NotEqual(x1, x2, trailer))
        SeaPearl.addConstraint!(model, SeaPearl.NotEqual(x2, x3, trailer))
        SeaPearl.addConstraint!(model, SeaPearl.NotEqual(x3, x4, trailer))

        # define the variable selection
        variableSelection = SeaPearl.MinDomainVariableSelection()


        # launch the search 
        SeaPearl.search!(model, SeaPearl.ILDSearch(6), variableSelection, valueSelection; out_solver=true)

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



end


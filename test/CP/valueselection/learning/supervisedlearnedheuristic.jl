@testset "learnedheuristic.jl" begin

    @testset "SupervisedLearnedHeuristic" begin

        supervisedlearnedheuristic = SeaPearl.SupervisedLearnedHeuristic(agent)

        @test supervisedlearnedheuristic.agent == agent
        @test isnothing(supervisedlearnedheuristic.fitted_problem)
        @test isnothing(supervisedlearnedheuristic.fitted_strategy)
        @test isnothing(supervisedlearnedheuristic.action_space)
        @test isnothing(supervisedlearnedheuristic.current_state)
        @test isnothing(supervisedlearnedheuristic.reward)
        @test isnothing(supervisedlearnedheuristic.search_metrics)

        supervisedlearnedheuristic.fitted_problem = SeaPearl.LegacyGraphColoringGenerator
        supervisedlearnedheuristic.fitted_strategy = SeaPearl.DFSearch

        @test supervisedlearnedheuristic.fitted_problem == SeaPearl.LegacyGraphColoringGenerator
        @test supervisedlearnedheuristic.fitted_strategy == SeaPearl.DFSearch

    end


    @testset "SupervisedLearnedHeuristic in action" begin
        approximator_model = SeaPearl.CPNN(
            graphChain=Flux.Chain(
                SeaPearl.GraphConv(3 => 64, Flux.leakyrelu)
            ),
            nodeChain=Flux.Chain(
                Flux.Dense(64, 16, Flux.leakyrelu)
            ),
            outputChain=Flux.Dense(16, 4),
        )
        target_approximator_model = SeaPearl.CPNN(
            graphChain=Flux.Chain(
                SeaPearl.GraphConv(3 => 64, Flux.leakyrelu)
            ),
            nodeChain=Flux.Chain(
                Flux.Dense(64, 16, Flux.leakyrelu)
            ),
            outputChain=Flux.Dense(16, 4),
        )

        agent = RL.Agent(
            policy=RL.QBasedPolicy(
                learner=RL.DQNLearner(
                    approximator=RL.NeuralNetworkApproximator(
                        model=approximator_model,
                        optimizer=ADAM(0.001f0)
                    ),
                    target_approximator=RL.NeuralNetworkApproximator(
                        model=target_approximator_model,
                        optimizer=ADAM(0.001f0)
                    ),
                    loss_func=Flux.Losses.huber_loss
                ),
                explorer=RL.EpsilonGreedyExplorer(
                    ϵ_stable=0.01,
                    rng=MersenneTwister(33)
                )
            ),
            trajectory=RL.CircularArraySLARTTrajectory(
                capacity=500,
                state=SeaPearl.DefaultTrajectoryState[] => (),
                action=Int => (),
                legal_actions_mask=Vector{Bool} => (4,),
            )
        )

        #EPISODE 1
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

        lh = SeaPearl.SupervisedLearnedHeuristic(
            agent,
            eta_init=1.0,
            eta_stable=0.0,
            warmup_steps=2,
            decay_steps=2
        )
        SeaPearl.update_with_cpmodel!(lh, model)
        false_x = first(values(model.variables))
        env = SeaPearl.get_observation!(lh, model, false_x)


        Flux.reset!(lh.agent)
        lh.agent(RL.PRE_EPISODE_STAGE, env)
        _, _ = SeaPearl.fixPoint!(model)
        env = SeaPearl.get_observation!(lh, model, x1)

        v1 = lh.agent(env)
        lh.agent(RL.PRE_ACT_STAGE, env, v1)
        SeaPearl.assign!(x1, v1)
        _, _ = SeaPearl.fixPoint!(model, SeaPearl.getOnDomainChange(x1))
        env = SeaPearl.get_observation!(lh, model, x2)
        lh.agent(RL.POST_ACT_STAGE, env)

        v2 = lh.agent(env)
        lh.agent(RL.PRE_ACT_STAGE, env, v2)
        SeaPearl.assign!(x2, v2)
        _, _ = SeaPearl.fixPoint!(model, SeaPearl.getOnDomainChange(x2))
        env = SeaPearl.get_observation!(lh, model, x3)
        lh.agent(RL.POST_ACT_STAGE, env)

        v3 = lh.agent(env)
        lh.agent(RL.PRE_ACT_STAGE, env, v3)
        SeaPearl.assign!(x3, v3)
        _, _ = SeaPearl.fixPoint!(model, SeaPearl.getOnDomainChange(x3))
        env = SeaPearl.get_observation!(lh, model, x4)
        lh.agent(RL.POST_ACT_STAGE, env)

        v4 = lh.agent(env)
        lh.agent(RL.PRE_ACT_STAGE, env, v4)
        SeaPearl.assign!(x4, v4)
        _, _ = SeaPearl.fixPoint!(model, SeaPearl.getOnDomainChange(x4))
        env = SeaPearl.get_observation!(lh, model, x4)
        lh.agent(RL.POST_ACT_STAGE, env)
        lh.agent(RL.POST_EPISODE_STAGE, env) #a state is pushed at the end of an episode and a dummy action into the trajectory


        @test length(lh.agent.trajectory[:state]) == 5
        @test size(lh.agent.trajectory[:legal_actions_mask]) == (4, 5)
        @test length(lh.agent.trajectory[:action]) == 5
        @test length(lh.agent.trajectory[:reward]) == 4
        @test length(lh.agent.trajectory[:terminal]) == 4

    end

    @testset "advanced test on supervisedlearnedheuristic.jl" begin
        approximator_model = SeaPearl.CPNN(
            graphChain=Flux.Chain(
                SeaPearl.GraphConv(3 => 64, Flux.leakyrelu)
            ),
            nodeChain=Flux.Chain(
                Flux.Dense(64, 16, Flux.leakyrelu)
            ),
            outputChain=Flux.Dense(16, 4),
        )
        target_approximator_model = SeaPearl.CPNN(
            graphChain=Flux.Chain(
                SeaPearl.GraphConv(3 => 64, Flux.leakyrelu)
            ),
            nodeChain=Flux.Chain(
                Flux.Dense(64, 16, Flux.leakyrelu)
            ),
            outputChain=Flux.Dense(16, 4),
        )

        agent = RL.Agent(
            policy=RL.QBasedPolicy(
                learner=RL.DQNLearner(
                    approximator=RL.NeuralNetworkApproximator(
                        model=approximator_model,
                        optimizer=ADAM(0.001f0)
                    ),
                    target_approximator=RL.NeuralNetworkApproximator(
                        model=target_approximator_model,
                        optimizer=ADAM(0.001f0)
                    ),
                    loss_func=Flux.Losses.huber_loss
                ),
                explorer=RL.EpsilonGreedyExplorer(
                    ϵ_stable=0.01,
                    rng=MersenneTwister(33)
                )
            ),
            trajectory=RL.CircularArraySLARTTrajectory(
                capacity=500,
                state=SeaPearl.DefaultTrajectoryState[] => (),
                action=Int => (),
                legal_actions_mask=Vector{Bool} => (4,),
            )
        )

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

        variableHeuristic = SeaPearl.MinDomainVariableSelection{true}()
        x = variableHeuristic(model)

        lh = SeaPearl.SupervisedLearnedHeuristic(agent)
        SeaPearl.update_with_cpmodel!(lh, model)

        lh.firstActionTaken = true
        lh(SeaPearl.DecisionPhase, model, x)
        @test !isnothing(model.statistics.lastVar)
        @test lh.agent.trajectory[:reward][end] == -0.025f0

        lh(SeaPearl.EndingPhase, model, :Optimal)
        @test lh.agent.trajectory[:reward][end] == 0.975f0    #last DecisionReward (-0.025f0) + EndingReward (+1)

    end

    @testset "SupervisedLearnedHeuristic test helpSolution" begin
        approximator_model = SeaPearl.CPNN(
            graphChain=Flux.Chain(
                SeaPearl.GraphConv(3 => 64, Flux.leakyrelu)
            ),
            nodeChain=Flux.Chain(
                Flux.Dense(64, 16, Flux.leakyrelu)
            ),
            outputChain=Flux.Dense(16, 4),
        )
        target_approximator_model = SeaPearl.CPNN(
            graphChain=Flux.Chain(
                SeaPearl.GraphConv(3 => 64, Flux.leakyrelu)
            ),
            nodeChain=Flux.Chain(
                Flux.Dense(64, 16, Flux.leakyrelu)
            ),
            outputChain=Flux.Dense(16, 4),
        )

        agent = RL.Agent(
            policy=RL.QBasedPolicy(
                learner=RL.DQNLearner(
                    approximator=RL.NeuralNetworkApproximator(
                        model=approximator_model,
                        optimizer=ADAM(0.001f0)
                    ),
                    target_approximator=RL.NeuralNetworkApproximator(
                        model=target_approximator_model,
                        optimizer=ADAM(0.001f0)
                    ),
                    loss_func=Flux.Losses.huber_loss
                ),
                explorer=RL.EpsilonGreedyExplorer(
                    ϵ_stable=0.01,
                    rng=MersenneTwister(33)
                )
            ),
            trajectory=RL.CircularArraySLARTTrajectory(
                capacity=500,
                state=SeaPearl.DefaultTrajectoryState[] => (),
                action=Int => (),
                legal_actions_mask=Vector{Bool} => (4,),
            )
        )

        #EPISODE 1
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

        variable_heuristic = SeaPearl.MinDomainVariableSelection()
        lh = SeaPearl.SupervisedLearnedHeuristic(
            agent,
            eta_init=1.0,
            eta_stable=0.0,
            warmup_steps=2,
            decay_steps=2
        )
        SeaPearl.update_with_cpmodel!(lh, model)

        # At the beginning there is no helpSolution
        @test isnothing(lh.helpSolution)

        # Since eta_init = 1.0 an helpSolution is calculated
        lh(SeaPearl.InitializingPhase, model)
        @test !isnothing(lh.helpSolution)
        @test lh.helpSolution == Dict{String,Union{Bool,Int64,Set{Int64}}}("x1" => 1, "x2" => 2, "x3" => 3, "x4" => 1)

        # We check that the values returned by the heuristic correspond to those of the helpSolution.
        # Variable 1
        lh(SeaPearl.StepPhase, model, :Feasible)
        x = variable_heuristic(model)
        v = lh(SeaPearl.DecisionPhase, model, x)
        @test v == lh.helpSolution[x.id]
        lh(SeaPearl.EndingPhase, model, :Feasible)
        SeaPearl.assign!(x, v)

        # Variable 2
        lh(SeaPearl.StepPhase, model, :Feasible)
        x = variable_heuristic(model)
        v = lh(SeaPearl.DecisionPhase, model, x)
        @test v == lh.helpSolution[x.id]
        lh(SeaPearl.EndingPhase, model, :Feasible)
        SeaPearl.assign!(x, v)

        # Variable 3
        lh(SeaPearl.StepPhase, model, :Feasible)
        x = variable_heuristic(model)
        v = lh(SeaPearl.DecisionPhase, model, x)
        @test v == lh.helpSolution[x.id]
        lh(SeaPearl.EndingPhase, model, :Feasible)
        SeaPearl.assign!(x, v)

        # Variable 4
        lh(SeaPearl.StepPhase, model, :Feasible)
        x = variable_heuristic(model)
        v = lh(SeaPearl.DecisionPhase, model, x)
        @test v == lh.helpSolution[x.id]
        lh(SeaPearl.EndingPhase, model, :Feasible)
        SeaPearl.assign!(x, v)
    end

    @testset "SupervisedLearnedHeuristic test get_eta" begin
        approximator_model = SeaPearl.CPNN(
            graphChain=Flux.Chain(
                SeaPearl.GraphConv(3 => 64, Flux.leakyrelu)
            ),
            nodeChain=Flux.Chain(
                Flux.Dense(64, 16, Flux.leakyrelu)
            ),
            outputChain=Flux.Dense(16, 4),
        )
        target_approximator_model = SeaPearl.CPNN(
            graphChain=Flux.Chain(
                SeaPearl.GraphConv(3 => 64, Flux.leakyrelu)
            ),
            nodeChain=Flux.Chain(
                Flux.Dense(64, 16, Flux.leakyrelu)
            ),
            outputChain=Flux.Dense(16, 4),
        )

        agent = RL.Agent(
            policy=RL.QBasedPolicy(
                learner=RL.DQNLearner(
                    approximator=RL.NeuralNetworkApproximator(
                        model=approximator_model,
                        optimizer=ADAM(0.001f0)
                    ),
                    target_approximator=RL.NeuralNetworkApproximator(
                        model=target_approximator_model,
                        optimizer=ADAM(0.001f0)
                    ),
                    loss_func=Flux.Losses.huber_loss
                ),
                explorer=RL.EpsilonGreedyExplorer(
                    ϵ_stable=0.01,
                    rng=MersenneTwister(33)
                )
            ),
            trajectory=RL.CircularArraySLARTTrajectory(
                capacity=500,
                state=SeaPearl.DefaultTrajectoryState[] => (),
                action=Int => (),
                legal_actions_mask=Vector{Bool} => (4,),
            )
        )

        lh = SeaPearl.SupervisedLearnedHeuristic(
            agent,
            eta_init=1.0,
            eta_stable=0.2,
            warmup_steps=2,
            decay_steps=4
        )

        # EPISODE 1
        @test round(SeaPearl.get_eta(lh); digits=1) == 1.0 # step = 1
        # EPISODE 2
        @test round(SeaPearl.get_eta(lh); digits=1) == 1.0 # step = 2
        # EPISODE 3
        @test round(SeaPearl.get_eta(lh); digits=1) == 0.8 # step = 3
        # EPISODE 4
        @test round(SeaPearl.get_eta(lh); digits=1) == 0.6 # step = 4
        # EPISODE 5
        @test round(SeaPearl.get_eta(lh); digits=1) == 0.4 # step = 5
        # EPISODE 6
        @test round(SeaPearl.get_eta(lh); digits=1) == 0.2 # step = 6
        # EPISODE 7
        @test round(SeaPearl.get_eta(lh); digits=1) == 0.2 # step = 7
        # EPISODE 8
        @test round(SeaPearl.get_eta(lh); digits=1) == 0.2 # step = 8
    end

    @testset "Random generator test" begin

        approximator_model = SeaPearl.CPNN(
            graphChain=Flux.Chain(
                SeaPearl.GraphConv(3 => 64, Flux.leakyrelu)
            ),
            nodeChain=Flux.Chain(
                Flux.Dense(64, 16, Flux.leakyrelu)
            ),
            outputChain=Flux.Dense(16, 4),
        )
        target_approximator_model = SeaPearl.CPNN(
            graphChain=Flux.Chain(
                SeaPearl.GraphConv(3 => 64, Flux.leakyrelu)
            ),
            nodeChain=Flux.Chain(
                Flux.Dense(64, 16, Flux.leakyrelu)
            ),
            outputChain=Flux.Dense(16, 4),
        )

        agent = RL.Agent(
            policy=RL.QBasedPolicy(
                learner=RL.DQNLearner(
                    approximator=RL.NeuralNetworkApproximator(
                        model=approximator_model,
                        optimizer=ADAM(0.001f0)
                    ),
                    target_approximator=RL.NeuralNetworkApproximator(
                        model=target_approximator_model,
                        optimizer=ADAM(0.001f0)
                    ),
                    loss_func=Flux.Losses.huber_loss
                ),
                explorer=RL.EpsilonGreedyExplorer(
                    ϵ_stable=0.01,
                    rng=MersenneTwister(33)
                )
            ),
            trajectory=RL.CircularArraySLARTTrajectory(
                capacity=500,
                state=SeaPearl.DefaultTrajectoryState[] => (),
                action=Int => (),
                legal_actions_mask=Vector{Bool} => (4,),
            )
        )

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

        variable_heuristic = SeaPearl.MinDomainVariableSelection()
        lh = SeaPearl.SupervisedLearnedHeuristic(
            agent,
            eta_init=.5,
            eta_stable=0.5,
            warmup_steps=0,
            decay_steps=0,
            rng=MersenneTwister(1234)
        )
        SeaPearl.update_with_cpmodel!(lh, model)

        lh(SeaPearl.InitializingPhase, model)
        @test isnothing(lh.helpSolution)
        SeaPearl.reset_model!(model)
        
        lh(SeaPearl.InitializingPhase, model)
        @test isnothing(lh.helpSolution)
        SeaPearl.reset_model!(model)
        
        lh(SeaPearl.InitializingPhase, model)
        @test isnothing(lh.helpSolution)
        SeaPearl.reset_model!(model)
        
        lh(SeaPearl.InitializingPhase, model)
        @test !isnothing(lh.helpSolution)
        SeaPearl.reset_model!(model)
        
        lh(SeaPearl.InitializingPhase, model)
        @test isnothing(lh.helpSolution)

    end
end
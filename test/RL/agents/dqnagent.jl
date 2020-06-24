
@testset "dqnagent.jl" begin

    @testset "DQNAgent constructor" begin

        args_foGCN = CPRL.ArgsFixedOutputGCN(
            maxDomainSize = 2,
            numInFeatures = 6,
            firstHiddenGCN = 20,
            secondHiddenGCN = 6,
            hiddenDense = 6
        )

        foGCN = CPRL.build_model(CPRL.FixedOutputGCN, args_foGCN)

        agent = CPRL.DQNAgent(
            nn_model = foGCN
        )

        @test typeof(agent.policy.learner.approximator.model) == CPRL.FixedOutputGCN
        @test typeof(agent.policy.learner.target_approximator.model) == CPRL.FixedOutputGCN

        @test isa(agent.trajectory, RL.CircularCompactSARTSATrajectory)

    end

    @testset "DQNAgent's policy I" begin

        # constructing an agent 
        args_foGCN = CPRL.ArgsFixedOutputGCN(
            maxDomainSize = 2,
            numInFeatures = 6,
            firstHiddenGCN = 20,
            secondHiddenGCN = 6,
            hiddenDense = 6
        )

        foGCN = CPRL.build_model(CPRL.FixedOutputGCN, args_foGCN)

        agent = CPRL.DQNAgent(
            nn_model = foGCN,
            state_size = (6, 13)
        )

        # constructing a CPGraph
        trailer = CPRL.Trailer()
        model = CPRL.CPModel(trailer)

        x = CPRL.IntVar(2, 3, "x", trailer)
        y = CPRL.IntVar(2, 3, "y", trailer)
        CPRL.addVariable!(model, x)
        CPRL.addVariable!(model, y)
        push!(model.constraints, CPRL.Equal(x, y, trailer))
        push!(model.constraints, CPRL.NotEqual(x, y, trailer))

        env = CPRL.RLEnv(model)
        obs = CPRL.observe!(env, model, x)

        """
        value = agent(RL.PRE_ACT_STAGE, obs)
        println(value)

        @test value in [1, 2]
        """

    end

    @testset "DQNAgent's policy II" begin

        # constructing an agent 
        args_foGCN = CPRL.ArgsFixedOutputGCN(
            maxDomainSize = 4,
            numInFeatures = 11,
            firstHiddenGCN = 20,
            secondHiddenGCN = 11, # need to be equal to numInFeatures atm 
            hiddenDense = 11
        )

        foGCN = CPRL.build_model(CPRL.FixedOutputGCN, args_foGCN)

        agent = RL.Agent(
            policy = RL.QBasedPolicy(
                learner = CPRL.CPDQNLearner(
                    approximator = RL.NeuralNetworkApproximator(
                        model = Chain(
                            Flux.flatten,
                            Dense(11*23, 20, Flux.relu),
                            Dense(20, 20, Flux.relu),
                            Dense(20, 4, Flux.relu)
                        ),
                        optimizer = ADAM(0.001f0)
                    ),
                    target_approximator = RL.NeuralNetworkApproximator(
                        model = Chain(
                            Flux.flatten,
                            Dense(11*23, 20, Flux.relu),
                            Dense(20, 20, Flux.relu),
                            Dense(20, 4, Flux.relu)
                        ),
                        optimizer = ADAM(0.001f0)
                    ),
                    loss_func = huber_loss,
                    stack_size = nothing,
                    γ = 0.99f0,
                    batch_size = 32,
                    update_horizon = 1,
                    min_replay_history = 1,
                    update_freq = 1,
                    target_update_freq = 100,
                    seed = 22,
                ), 
                explorer = CPRL.CPEpsilonGreedyExplorer(
                    ϵ_stable = 0.01,
                    kind = :exp,
                    ϵ_init = 1.0,
                    warmup_steps = 0,
                    decay_steps = 500,
                    step = 1,
                    is_break_tie = false, 
                    #is_training = true,
                    seed = 33
                )
            ),
            trajectory = RL.CircularCompactSARTSATrajectory(
                capacity = 1000, 
                state_type = Float32, 
                state_size = (11, 23, 1),
                action_type = Int,
                action_size = (),
                reward_type = Float32,
                reward_size = (),
                terminal_type = Bool,
                terminal_size = ()
            ),
            role = :DEFAULT_PLAYER
        )

        # constructing a CPGraph
        trailer = CPRL.Trailer()
        model = CPRL.CPModel(trailer)

        x1 = CPRL.IntVar(1, 2, "x1", trailer)
        x2 = CPRL.IntVar(1, 2, "x2", trailer)
        x3 = CPRL.IntVar(2, 3, "x3", trailer)
        x4 = CPRL.IntVar(1, 4, "x4", trailer)
        CPRL.addVariable!(model, x1)
        CPRL.addVariable!(model, x2)
        CPRL.addVariable!(model, x3)
        CPRL.addVariable!(model, x4)

        push!(model.constraints, CPRL.NotEqual(x1, x2, trailer))
        push!(model.constraints, CPRL.NotEqual(x2, x3, trailer))
        push!(model.constraints, CPRL.NotEqual(x3, x4, trailer))

        env = CPRL.RLEnv(model)


        obs = CPRL.observe!(env, model, x1)
        v1 = agent(RL.PRE_ACT_STAGE, obs)

        println(" ----------------- ")
        println("Value ", v1, " is assigned to ", x1.id)    
        println(" ----------------- ")

        CPRL.assign!(x1, v1)
        _, _ = CPRL.fixPoint!(model, CPRL.getOnDomainChange(x1))


        obs = CPRL.observe!(env, model, x2)
        agent(RL.POST_ACT_STAGE, obs)

        v2 = agent(RL.PRE_ACT_STAGE, obs)

        println(" ----------------- ")
        println("Value ", v2, " is assigned to ", x2.id)    
        println(" ----------------- ")

        CPRL.assign!(x2, v2)
        _, _ = CPRL.fixPoint!(model, CPRL.getOnDomainChange(x2))

        
        obs = CPRL.observe!(env, model, x3)
        agent(RL.POST_ACT_STAGE, obs)

        v3 = agent(RL.PRE_ACT_STAGE, obs)

        println(" ----------------- ")
        println("Value ", v3, " is assigned to ", x3.id)    
        println(" ----------------- ")
        
        CPRL.assign!(x3, v3)
        _, _ = CPRL.fixPoint!(model, CPRL.getOnDomainChange(x2))

        
        obs = CPRL.observe!(env, model, x4)
        agent(RL.POST_ACT_STAGE, obs)

        v4 = agent(RL.PRE_ACT_STAGE, obs)

        println(" ----------------- ")
        println("Value ", v4, " is assigned to ", x4.id)    
        println(" ----------------- ")

    end

    

end

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

        @test isa(agent.trajectory, RL.VectorialCompactSARTSATrajectory)

    end

    @testset "DQNAgent's policy" begin

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
            nn_model = foGCN
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

        value = agent(RL.PRE_ACT_STAGE, obs)
        println(value)

        @test value in [1, 2]

    end

    

end
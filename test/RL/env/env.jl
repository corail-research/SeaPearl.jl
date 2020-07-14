@testset "env.jl" begin

    @testset "RLEnv constructor" begin
        rng = MersenneTwister(1)
        env = CPRL.RLEnv{CPRL.DefaultReward}(
            RL.DiscreteSpace([1, 2, 3]),
            CPRL.CPGraph(CPRL.CPModel(CPRL.Trailer()), 0),
            1,
            0,
            false,
            rng,
            8,
            CPRL.SearchMetrics()
        )

        @test typeof(env.action_space) == RL.DiscreteSpace{Array{Int64,1}}
        @test env.action_space.span == [1, 2, 3]
        @test typeof(env.state) == CPRL.CPGraph
        @test env.action == 1
        @test env.reward == 0
        @test env.done == false 
        @test env.cpnodes_max == 8
    end

    @testset "RLEnv from CPModel" begin
        trailer = CPRL.Trailer()
        model = CPRL.CPModel(trailer)

        x = CPRL.IntVar(2, 3, "x", trailer)
        y = CPRL.IntVar(2, 3, "y", trailer)
        CPRL.addVariable!(model, x)
        CPRL.addVariable!(model, y)
        push!(model.constraints, CPRL.Equal(x, y, trailer))
        push!(model.constraints, CPRL.NotEqual(x, y, trailer))

        env = CPRL.RLEnv(model)

        @test typeof(env.action_space) == RL.DiscreteSpace{Array{Int64,1}}
        @test env.action_space.span == [2, 3]
        @test typeof(env.state) == CPRL.CPGraph
        @test env.action == 1
        @test env.reward == 0
        @test env.done == false 
        @test isa(env, CPRL.RLEnv{CPRL.DefaultReward})
    end

    @testset "set_done!()" begin
        trailer = CPRL.Trailer()
        model = CPRL.CPModel(trailer)

        x = CPRL.IntVar(2, 3, "x", trailer)
        y = CPRL.IntVar(2, 3, "y", trailer)
        CPRL.addVariable!(model, x)
        CPRL.addVariable!(model, y)
        push!(model.constraints, CPRL.Equal(x, y, trailer))
        push!(model.constraints, CPRL.NotEqual(x, y, trailer))

        env = CPRL.RLEnv(model)

        CPRL.set_done!(env, true)
        @test env.done == true 

        CPRL.set_done!(env, false)
        @test env.done == false 
    end

    @testset "sync_state!()" begin
        trailer = CPRL.Trailer()
        model = CPRL.CPModel(trailer)

        x = CPRL.IntVar(2, 3, "x", trailer)
        y = CPRL.IntVar(2, 3, "y", trailer)
        CPRL.addVariable!(model, x)
        CPRL.addVariable!(model, y)
        push!(model.constraints, CPRL.Equal(x, y, trailer))
        push!(model.constraints, CPRL.NotEqual(x, y, trailer))

        env = CPRL.RLEnv(model)

        CPRL.sync_state!(env, model, x)

        @test Matrix(env.state.featuredgraph.graph[]) == [0 0 1 1 0 0
                                                          0 0 1 1 0 0
                                                          1 1 0 0 1 1
                                                          1 1 0 0 1 1
                                                          0 0 1 1 0 0
                                                          0 0 1 1 0 0]

        @test env.state.featuredgraph.feature[] == Float32[ 1 1 0 0 0 0
                                                            0 0 1 1 0 0
                                                            0 0 0 0 1 1]
        
        @test env.state.variable_id == 3

        CPRL.assign!(x, 2)
        CPRL.sync_state!(env, model, y)

        @test Matrix(env.state.featuredgraph.graph[]) == [0 0 1 1 0 0
                                                          0 0 1 1 0 0
                                                          1 1 0 0 1 0
                                                          1 1 0 0 1 1
                                                          0 0 1 1 0 0
                                                          0 0 0 1 0 0]

        @test env.state.featuredgraph.feature[] == Float32[ 1 1 0 0 0 0
                                                            0 0 1 1 0 0
                                                            0 0 0 0 1 1]
        
        @test env.state.variable_id == 4

    end

    @testset "observe!()" begin
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

        @test obs.reward == 0
        @test obs.terminal == false 
        @test obs.legal_actions == [2, 3]
        @test obs.legal_actions_mask == [true, true]

        CPRL.remove!(x.domain, 2)

        obs = CPRL.observe!(env, model, x)

        @test obs.reward == 0
        @test obs.terminal == false 
        @test obs.legal_actions == [3]
        @test obs.legal_actions_mask == [false, true]

    end

end
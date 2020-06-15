@testset "env.jl" begin

    @testset "RLEnv constructor" begin
        rng = MersenneTwister(1)
        env = CPRL.RLEnv(
            RL.DiscreteSpace([1, 2, 3]),
            CPRL.CPGraphSpace(4),
            Random.rand(rng, CPRL.CPGraphSpace(4)),
            1,
            -1,
            false,
            rng
        )

        @test typeof(env.action_space) == RL.DiscreteSpace{Array{Int64,1}}
        @test env.action_space.span == [1, 2, 3]
        @test env.observation_space == CPRL.CPGraphSpace(4)
        @test typeof(env.state) == CPRL.CPGraph
        @test env.action == 1
        @test env.reward == -1 
        @test env.done == false 
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
        @test env.observation_space == CPRL.CPGraphSpace(2)
        @test typeof(env.state) == CPRL.CPGraph
        @test env.action == 1
        @test env.reward == -1 
        @test env.done == false 
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

    @testset "set_reward!()" begin
        nothing
    end

    @testset "set_final_reward!()" begin
        nothing
    end

end
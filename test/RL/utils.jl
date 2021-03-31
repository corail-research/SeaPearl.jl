@testset "utils.jl" begin
    @testset "last_episode_total_reward()" begin
        trajectory = RL.CircularArraySARTTrajectory(
            capacity = 1000,
            state = Matrix{Float32} => (2, 2, 1),
        )

        

        push!(trajectory; state = Float32[1. 2.; 5. -1.], action = 2)
        push!(trajectory; reward = -2.5, terminal = false)

        push!(trajectory; state = Float32[1. 2.; 5. -1.], action = 2)
        push!(trajectory; reward = -2.5, terminal = false)

        push!(trajectory; state = Float32[1. 2.; 5. -1.], action = 2)
        push!(trajectory; reward = -100., terminal = true)

        push!(trajectory; state = Float32[1. 2.; 5. -1.], action = 2)
        push!(trajectory; reward = -1., terminal = false)

        push!(trajectory; state = Float32[1. 2.; 5. -1.], action = 2)
        push!(trajectory; reward = 3., terminal = false)

        push!(trajectory; state = Float32[1. 2.; 5. -1.], action = 2)
        push!(trajectory; reward = 3, terminal = false)

        push!(trajectory; state = Float32[1. 2.; 5. -1.], action = 2)
        push!(trajectory; reward = 100., terminal = true)

        @test SeaPearl.last_episode_total_reward(trajectory) == 105.

        push!(trajectory; state = Float32[1. 2.; 5. -1.], action = 2)
        push!(trajectory; reward = -2.5, terminal = false)

        push!(trajectory; state = Float32[1. 2.; 5. -1.], action = 2)
        push!(trajectory; reward = -2., terminal = false)

        push!(trajectory; state = Float32[1. 2.; 5. -1.], action = 2)
        push!(trajectory; reward = -100., terminal = true)

        @test SeaPearl.last_episode_total_reward(trajectory) == -104.5
    end
end
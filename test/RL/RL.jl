using CPRL
using ReinforcementLearning
using Statistics

const RL = ReinforcementLearning

@testset "RL.jl" begin

    @testset "selectValue()" begin
        # @test CPRL.selectValue() == 3
    end

    @testset "CartPole" begin
        env = CartPoleEnv(;T=Float32, seed=123)

        agent = Agent(
            policy = RandomPolicy(env;seed=456),
            trajectory = CircularCompactSARTSATrajectory(; capacity=3, state_type=Float32, state_size = (4,)),
        )
    
        hook = ComposedHook(TotalRewardPerEpisode(), TimePerStep())
    
        run(agent, env, StopAfterEpisode(10_000), hook)
    
        @info "stats for random policy" avg_reward = mean(hook[1].rewards) avg_fps = 1 / mean(hook[2].times)
    end


    
end
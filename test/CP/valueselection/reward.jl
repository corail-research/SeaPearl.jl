struct TestReward <: CPRL.AbstractReward end

function CPRL.set_reward!(::CPRL.DecisionPhase, env::CPRL.RLEnv{TestReward}, model::CPRL.CPModel)
    env.reward += 3
    nothing
end

function CPRL.set_reward!(::CPRL.EndingPhase, env::CPRL.RLEnv{TestReward}, model::CPRL.CPModel, symbol::Union{Nothing, Symbol})
    env.reward += -5
    nothing
end

@testset "reward.jl" begin
    @testset "Default reward" begin
        @testset "set_reward!(DecisionPhase)" begin
            trailer = CPRL.Trailer()
            model = CPRL.CPModel(trailer)

            env = CPRL.RLEnv(model)

            env.reward = 0
            CPRL.set_reward!(CPRL.DecisionPhase(), env, model)
            @test env.reward == -1/40
        end
        @testset "set_reward!(EndingPhase)" begin
            trailer = CPRL.Trailer()
            model = CPRL.CPModel(trailer)

            env = CPRL.RLEnv(model)

            env.reward = 5
            model.statistics.numberOfNodes = 30
            CPRL.set_reward!(CPRL.EndingPhase(), env, model, nothing)
            @test env.reward == 6
        end
    end
    @testset "Custom reward" begin
        @testset "set_reward!(DecisionPhase)" begin
            trailer = CPRL.Trailer()
            model = CPRL.CPModel(trailer)

            env = CPRL.RLEnv{TestReward}(model)

            env.reward = 0
            CPRL.set_reward!(CPRL.DecisionPhase(), env, model)
            @test env.reward == 3
        end
        @testset "set_reward!(EndingPhase)" begin
            trailer = CPRL.Trailer()
            model = CPRL.CPModel(trailer)

            env = CPRL.RLEnv{TestReward}(model)

            env.reward = 6
            CPRL.set_reward!(CPRL.EndingPhase(), env, model, nothing)
            @test env.reward == 1
        end
    end
end

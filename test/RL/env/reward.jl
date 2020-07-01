struct TestReward <: CPRL.AbstractReward end

function CPRL.set_backtracking_reward!(env::CPRL.RLEnv{TestReward}, model::CPRL.CPModel, current_status::Union{Nothing, Symbol})
    env.reward += 5
    nothing
end

function CPRL.set_before_next_decision_reward!(env::CPRL.RLEnv{TestReward}, model::CPRL.CPModel)
    env.reward += 3
    nothing
end

function CPRL.set_after_decision_reward!(env::CPRL.RLEnv{TestReward}, model::CPRL.CPModel)
    env.reward = 18
    nothing
end

function CPRL.set_final_reward!(env::CPRL.RLEnv{TestReward}, model::CPRL.CPModel)
    env.reward += -5
    nothing
end

@testset "reward.jl" begin
@testset "Default reward" begin
    @testset "set_before_next_decision_reward!()" begin
        trailer = CPRL.Trailer()
        model = CPRL.CPModel(trailer)

        env = CPRL.RLEnv(model)

        env.reward = 0
        CPRL.set_before_next_decision_reward!(env, model)
        @test env.reward == -1/40
    end
    @testset "set_backtracking_reward!()" begin
        trailer = CPRL.Trailer()
        model = CPRL.CPModel(trailer)

        env = CPRL.RLEnv(model)

        env.reward = 0
        CPRL.set_backtracking_reward!(env, model, :status)
        @test env.reward == -1/80
    end
    @testset "set_after_decision_reward!()" begin
        trailer = CPRL.Trailer()
        model = CPRL.CPModel(trailer)

        env = CPRL.RLEnv(model)

        env.reward = 5
        CPRL.set_after_decision_reward!(env, model)
        @test env.reward == 0
    end
    @testset "set_final_reward!()" begin
        trailer = CPRL.Trailer()
        model = CPRL.CPModel(trailer)

        env = CPRL.RLEnv(model)

        env.reward = 5
        model.statistics.numberOfNodes = 30
        CPRL.set_final_reward!(env, model)
        @test env.reward == 6
    end
end
@testset "Custom reward" begin
    @testset "set_before_next_decision_reward!()" begin
        trailer = CPRL.Trailer()
        model = CPRL.CPModel(trailer)

        env = CPRL.RLEnv{TestReward}(model)

        env.reward = 0
        CPRL.set_before_next_decision_reward!(env, model)
        @test env.reward == 3
    end
    @testset "set_backtracking_reward!()" begin
        trailer = CPRL.Trailer()
        model = CPRL.CPModel(trailer)

        env = CPRL.RLEnv{TestReward}(model)

        env.reward = 0
        CPRL.set_backtracking_reward!(env, model, :status)
        @test env.reward == 5
    end
    @testset "set_after_decision_reward!()" begin
        trailer = CPRL.Trailer()
        model = CPRL.CPModel(trailer)

        env = CPRL.RLEnv{TestReward}(model)

        env.reward = 5
        CPRL.set_after_decision_reward!(env, model)
        @test env.reward == 18
    end
    @testset "set_final_reward!()" begin
        trailer = CPRL.Trailer()
        model = CPRL.CPModel(trailer)

        env = CPRL.RLEnv{TestReward}(model)

        env.reward = 6
        CPRL.set_final_reward!(env, model)
        @test env.reward == 1
    end
end
end
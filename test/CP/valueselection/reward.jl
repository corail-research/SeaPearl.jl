struct TestReward <: CPRL.AbstractReward end

function CPRL.set_reward!(::CPRL.DecisionPhase, lh::CPRL.LearnedHeuristic{TestReward, O}, model::CPRL.CPModel) where O <: CPRL.ActionOutput
    env.reward += 3
    nothing
end

function CPRL.set_reward!(::CPRL.EndingPhase, env::CPRL.LearnedHeuristic{TestReward, O}, model::CPRL.CPModel, symbol::Union{Nothing, Symbol}) where O <: CPRL.ActionOutput
    env.reward += -5
    nothing
end

@testset "reward.jl" begin
    @testset "Default reward" begin
        @testset "set_reward!(DecisionPhase)" begin
            trailer = CPRL.Trailer()
            model = CPRL.CPModel(trailer)

            lh = CPRL.LearnedHeuristic(agent)
            CPRL.update_with_cpmodel!(lh, model)

            lh.current_reward = 0
            CPRL.set_reward!(CPRL.DecisionPhase(), lh, model)
            @test lh.current_reward == -1/40
        end

        @testset "set_reward!(EndingPhase)" begin
            trailer = CPRL.Trailer()
            model = CPRL.CPModel(trailer)

            lh = CPRL.LearnedHeuristic(agent)
            CPRL.update_with_cpmodel!(lh, model)

            lh.current_reward = 5
            model.statistics.numberOfNodes = 30
            CPRL.set_reward!(CPRL.EndingPhase(), lh, model, nothing)
            @test lh.current_reward == 6
        end
    end
    @testset "Custom reward" begin
        @testset "set_reward!(DecisionPhase)" begin
            trailer = CPRL.Trailer()
            model = CPRL.CPModel(trailer)

            lh = CPRL.LearnedHeuristic{TestReward, CPRL.FixedOutput}(agent)
            CPRL.update_with_cpmodel!(lh, model)

            lh.current_reward = 0
            CPRL.set_reward!(CPRL.DecisionPhase(), lh, model)
            @test lh.current_reward == 3
        end
        @testset "set_reward!(EndingPhase)" begin
            trailer = CPRL.Trailer()
            model = CPRL.CPModel(trailer)

            lh = CPRL.LearnedHeuristic{TestReward, CPRL.FixedOutput}(agent)
            CPRL.update_with_cpmodel!(lh, model)

            lh.current_reward = 6
            CPRL.set_reward!(CPRL.EndingPhase(), lh, model, nothing)
            @test lh.current_reward == 1
        end
    end
end

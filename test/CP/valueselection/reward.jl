struct TestReward <: SeaPearl.AbstractReward end

function SeaPearl.set_reward!(::SeaPearl.DecisionPhase, lh::SeaPearl.LearnedHeuristic{SR, TestReward, A}, model::SeaPearl.CPModel) where {
    SR <: SeaPearl.AbstractStateRepresentation, 
    A <: SeaPearl.ActionOutput
}
    lh.current_reward += 3
    nothing
end

function SeaPearl.set_reward!(::SeaPearl.EndingPhase, lh::SeaPearl.LearnedHeuristic{SR, TestReward, A}, model::SeaPearl.CPModel, symbol::Union{Nothing, Symbol}) where {
    SR <: SeaPearl.AbstractStateRepresentation, 
    A <: SeaPearl.ActionOutput
}
    lh.current_reward += -5
    nothing
end

@testset "reward.jl" begin
    @testset "Default reward" begin
        @testset "set_reward!(DecisionPhase)" begin
            trailer = SeaPearl.Trailer()
            model = SeaPearl.CPModel(trailer)

            lh = SeaPearl.LearnedHeuristic(agent)
            SeaPearl.update_with_cpmodel!(lh, model)

            lh.current_reward = 0
            SeaPearl.set_reward!(SeaPearl.DecisionPhase(), lh, model)
            @test lh.current_reward == -1/40
        end

        @testset "set_reward!(EndingPhase)" begin
            trailer = SeaPearl.Trailer()
            model = SeaPearl.CPModel(trailer)

            lh = SeaPearl.LearnedHeuristic(agent)
            SeaPearl.update_with_cpmodel!(lh, model)

            lh.current_reward = 5
            model.statistics.numberOfNodes = 30
            SeaPearl.set_reward!(SeaPearl.EndingPhase(), lh, model, nothing)
            @test lh.current_reward == 6
        end
    end
    @testset "Custom reward" begin
        @testset "set_reward!(DecisionPhase)" begin
            trailer = SeaPearl.Trailer()
            model = SeaPearl.CPModel(trailer)

            lh = SeaPearl.LearnedHeuristic{SeaPearl.DefaultStateRepresentation, TestReward, SeaPearl.FixedOutput}(agent)
            SeaPearl.update_with_cpmodel!(lh, model)

            lh.current_reward = 0
            SeaPearl.set_reward!(SeaPearl.DecisionPhase(), lh, model)
            @test lh.current_reward == 3
        end
        @testset "set_reward!(EndingPhase)" begin
            trailer = SeaPearl.Trailer()
            model = SeaPearl.CPModel(trailer)

            lh = SeaPearl.LearnedHeuristic{SeaPearl.DefaultStateRepresentation, TestReward, SeaPearl.FixedOutput}(agent)
            SeaPearl.update_with_cpmodel!(lh, model)

            lh.current_reward = 6
            SeaPearl.set_reward!(SeaPearl.EndingPhase(), lh, model, nothing)
            @test lh.current_reward == 1
        end
    end
end


@testset "Default reward" begin
    @testset "set_reward!(DecisionPhase)" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        lh = SeaPearl.LearnedHeuristic(agent)
        SeaPearl.update_with_cpmodel!(lh, model)

        lh.reward.value = 0
        SeaPearl.set_reward!(SeaPearl.DecisionPhase(), lh, model)
        @test lh.reward.value == -0.025f0
    end

    @testset "set_reward!(EndingPhase)" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        lh = SeaPearl.LearnedHeuristic(agent)
        SeaPearl.update_with_cpmodel!(lh, model)

        lh.reward.value = 5
        model.statistics.numberOfNodes = 30
        SeaPearl.set_reward!(SeaPearl.EndingPhase(), lh, model, nothing)
        @test lh.reward.value == 6
    end
end
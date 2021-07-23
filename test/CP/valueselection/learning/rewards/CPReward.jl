@testset "CPReward" begin
    @testset "set_reward!(DecisionPhase)" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        lh = SeaPearl.LearnedHeuristic{SeaPearl.DefaultStateRepresentation{SeaPearl.DefaultFeaturization, SeaPearl.DefaultTrajectoryState}, SeaPearl.CPReward, SeaPearl.FixedOutput}(agent)
        SeaPearl.update_with_cpmodel!(lh, model)

        lh.reward.value = 0
        SeaPearl.set_reward!(SeaPearl.DecisionPhase, lh, model)
        @test lh.reward.value == 0
    end

    @testset "set_reward!(StepPhase)" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        lh = SeaPearl.LearnedHeuristic{SeaPearl.DefaultStateRepresentation{SeaPearl.DefaultFeaturization, SeaPearl.DefaultTrajectoryState}, SeaPearl.CPReward, SeaPearl.FixedOutput}(agent)
        SeaPearl.update_with_cpmodel!(lh, model)

        lh.reward.value = 0
        SeaPearl.set_reward!(SeaPearl.StepPhase, lh, model,nothing)
        @test lh.reward.value == 0
    end

    @testset "set_reward!(EndingPhase)" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        x = SeaPearl.IntVar(2, 3, "x", trailer)
        y = SeaPearl.IntVar(3, 4, "y", trailer)
        z = SeaPearl.IntVar(4, 5, "z", trailer)
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        SeaPearl.addVariable!(model, z; branchable=false)
        lh = SeaPearl.LearnedHeuristic{SeaPearl.DefaultStateRepresentation{SeaPearl.DefaultFeaturization, SeaPearl.DefaultTrajectoryState}, SeaPearl.CPReward, SeaPearl.FixedOutput}(agent)
        SeaPearl.update_with_cpmodel!(lh, model)

        lh.reward.value = 5
        model.statistics.numberOfNodes = 30
        SeaPearl.set_reward!(SeaPearl.EndingPhase, lh, model, :FoundSolution)
        @test lh.reward.value == 6
        SeaPearl.assign!(x,2)
        SeaPearl.set_reward!(SeaPearl.EndingPhase, lh, model, :Infeasible)
        @test lh.reward.value == 4
    end
end

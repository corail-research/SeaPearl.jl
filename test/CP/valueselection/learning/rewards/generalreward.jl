@testset "GeneralReward" begin
    @testset "set_reward!" begin
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)
        x = SeaPearl.IntVar(1, 2, "x", trailer)
        y = SeaPearl.IntVar(-1, 1, "y", trailer)
        z = SeaPearl.IntVar(-3, 0, "z", trailer)
        # Minimize z knowing that z = -x -y : equivalent to taking the largest x and y as possible
        SeaPearl.addVariable!(model, x)
        SeaPearl.addVariable!(model, y)
        SeaPearl.addVariable!(model, z; branchable=false)
        SeaPearl.addObjective!(model, z)
        SeaPearl.addConstraint!(model, SeaPearl.SumToZero([x,y,z], trailer))
        lh = SeaPearl.SimpleLearnedHeuristic{SeaPearl.DefaultStateRepresentation{SeaPearl.DefaultFeaturization, SeaPearl.DefaultTrajectoryState}, SeaPearl.GeneralReward, SeaPearl.FixedOutput}(agent)
        SeaPearl.update_with_cpmodel!(lh, model)
        lh.firstActionTaken = true
        prunedDomains = SeaPearl.CPModification();
        SeaPearl.addToPrunedDomains!(prunedDomains, x, SeaPearl.assign!(x, 1));
        # Assigning 1 to x means that the objective value can't take the value -3 anymore
        feasible, pruned = SeaPearl.fixPoint!(model, nothing, prunedDomains)
        SeaPearl.updateStatistics!(model,pruned)
        SeaPearl.set_reward!(SeaPearl.DecisionPhase, lh, model)
        # Variable part: 2 variables are removed, and beta and gamma are set to 2 by default, initialNumberOfVariableValueLinks = 6
        # variable part = 2*(1/3)^2 = 2/9
        # Objective part: -3 is removed, so the objective part is -1/3
        # Total reward for this decision: 2/9-1/3 = -1/9
        @test lh.reward.value + 1/9 <= 0.0001
        prunedDomains = SeaPearl.CPModification();
        SeaPearl.addToPrunedDomains!(prunedDomains, x, SeaPearl.assign!(y, 1));
        # Assigning 1 to y ends the problem
        # Variable part: 3 variables are removed: 2*(2/3)^2=8/9
        # Objective part: 2/3
        # Total reward for this decision: 14/9
        feasible, pruned = SeaPearl.fixPoint!(model, nothing, prunedDomains)
        SeaPearl.updateStatistics!(model,pruned)
        SeaPearl.set_reward!(SeaPearl.DecisionPhase, lh, model)
        @test lh.reward.value - 14/9 <= 0.0001
        SeaPearl.set_reward!(SeaPearl.EndingPhase, lh, model, :FoundSolution)
        @test lh.reward.value >= 0
        SeaPearl.set_reward!(SeaPearl.EndingPhase, lh, model, :Infeasible)
        # -1 -gamma = -1 - 2 = -3
        @test lh.reward.value >= -3
    end
end

mutable struct TestReward <: SeaPearl.AbstractReward 
    value::Float32
end

TestReward(model::SeaPearl.CPModel) = TestReward(0)

function SeaPearl.set_reward!(::Type{SeaPearl.InitializingPhase}, lh::SeaPearl.LearnedHeuristic{SR, TestReward, A}, model::SeaPearl.CPModel) where {
    SR <: SeaPearl.AbstractStateRepresentation, 
    A <: SeaPearl.ActionOutput
}
    lh.reward.value += 1
    nothing
end
function SeaPearl.set_reward!(::Type{SeaPearl.StepPhase}, lh::SeaPearl.LearnedHeuristic{SR, TestReward, A}, model::SeaPearl.CPModel) where {
    SR <: SeaPearl.AbstractStateRepresentation, 
    A <: SeaPearl.ActionOutput
}
    lh.reward.value += 2
    nothing
end
function SeaPearl.set_reward!(::Type{SeaPearl.DecisionPhase}, lh::SeaPearl.LearnedHeuristic{SR, TestReward, A}, model::SeaPearl.CPModel) where {
    SR <: SeaPearl.AbstractStateRepresentation, 
    A <: SeaPearl.ActionOutput
}
    lh.reward.value += 3
    nothing
end
function SeaPearl.set_reward!(::Type{SeaPearl.EndingPhase}, lh::SeaPearl.LearnedHeuristic{SR, TestReward, A}, model::SeaPearl.CPModel, symbol::Union{Nothing, Symbol}) where {
    SR <: SeaPearl.AbstractStateRepresentation, 
    A <: SeaPearl.ActionOutput
}
    lh.reward.value += -5
    nothing
end

@testset "rewards.jl" begin 

    include("defaultreward.jl")
    include("generalreward.jl")
    include("tsptwreward.jl")

    @testset "Custom reward" begin
        @testset "set_reward(StepPhase)" begin
            trailer = SeaPearl.Trailer()
            model = SeaPearl.CPModel(trailer)
    
            lh = SeaPearl.SimpleLearnedHeuristic(agent)
            SeaPearl.update_with_cpmodel!(lh, model)
    
            lh.reward.value = 0 
            model.statistics.numberOfNodes = 1
            SeaPearl.set_reward!(SeaPearl.StepPhase, lh, model,:Infeasible)
            @test lh.reward.value == 0
    
            lh.reward.value = 0 
            SeaPearl.set_reward!(SeaPearl.StepPhase, lh, model,:FoundSolution)
            @test lh.reward.value == 0
         
            lh.reward.value = 0 
            SeaPearl.set_reward!(SeaPearl.StepPhase, lh, model,:Feasible)
            @test lh.reward.value == 0
         
            lh.reward.value = 0 
            SeaPearl.set_reward!(SeaPearl.StepPhase, lh, model,:BackTracking)
            @test lh.reward.value == 0

            lh.reward.value = 0 
            SeaPearl.set_reward!(SeaPearl.DecisionPhase, lh, model)
            @test lh.reward.value == -1
    
        end

        @testset "set_reward!(InitializingPhase)" begin
            trailer = SeaPearl.Trailer()
            model = SeaPearl.CPModel(trailer)

            lh = SeaPearl.SimpleLearnedHeuristic{SeaPearl.DefaultStateRepresentation{SeaPearl.DefaultFeaturization, SeaPearl.DefaultTrajectoryState}, TestReward, SeaPearl.FixedOutput}(agent)
            SeaPearl.update_with_cpmodel!(lh, model)

            lh.reward.value = 0
            SeaPearl.set_reward!(SeaPearl.InitializingPhase, lh, model)
            @test lh.reward.value == 1
        end

        @testset "set_reward!(StepPhase)" begin
            trailer = SeaPearl.Trailer()
            model = SeaPearl.CPModel(trailer)

            lh = SeaPearl.SimpleLearnedHeuristic{SeaPearl.DefaultStateRepresentation{SeaPearl.DefaultFeaturization, SeaPearl.DefaultTrajectoryState}, TestReward, SeaPearl.FixedOutput}(agent)
            SeaPearl.update_with_cpmodel!(lh, model)

            lh.reward.value = 0
            SeaPearl.set_reward!(SeaPearl.StepPhase, lh, model)
            @test lh.reward.value == 2
        end

        @testset "set_reward!(DecisionPhase)" begin
            trailer = SeaPearl.Trailer()
            model = SeaPearl.CPModel(trailer)

            lh = SeaPearl.SimpleLearnedHeuristic{SeaPearl.DefaultStateRepresentation{SeaPearl.DefaultFeaturization, SeaPearl.DefaultTrajectoryState}, TestReward, SeaPearl.FixedOutput}(agent)
            SeaPearl.update_with_cpmodel!(lh, model)

            lh.reward.value = 0
            SeaPearl.set_reward!(SeaPearl.DecisionPhase, lh, model)
            @test lh.reward.value == 3
        end

        @testset "set_reward!(EndingPhase)" begin
            trailer = SeaPearl.Trailer()
            model = SeaPearl.CPModel(trailer)

            lh = SeaPearl.SimpleLearnedHeuristic{SeaPearl.DefaultStateRepresentation{SeaPearl.DefaultFeaturization, SeaPearl.DefaultTrajectoryState}, TestReward, SeaPearl.FixedOutput}(agent)
            SeaPearl.update_with_cpmodel!(lh, model)

            lh.reward.value = 6
            SeaPearl.set_reward!(SeaPearl.EndingPhase, lh, model, nothing)
            @test lh.reward.value == 1
        end
    end

end
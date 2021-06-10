mutable struct TestReward <: SeaPearl.AbstractReward 
    value::Float32
end

TestReward(model::SeaPearl.CPModel) = TestReward(0)

function SeaPearl.set_reward!(::Type{SeaPearl.DecisionPhase}, lh::SeaPearl.LearnedHeuristic{SR, TestReward, A}, model::SeaPearl.CPModel) where {
    SR <: SeaPearl.AbstractStateRepresentation, 
    A <: SeaPearl.ActionOutput
}
    lh.reward.value += 3
    nothing
end
function SeaPearl.set_reward!(::Type{SeaPearl.StepPhase}, lh::SeaPearl.LearnedHeuristic{SR, TestReward, A}, model::SeaPearl.CPModel) where {
    SR <: SeaPearl.AbstractStateRepresentation, 
    A <: SeaPearl.ActionOutput
}
    lh.reward.value += 3
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
    include("tsptwreward.jl")

    @testset "Custom reward" begin
        @testset "set_reward!(DecisionPhase)" begin
            trailer = SeaPearl.Trailer()
            model = SeaPearl.CPModel(trailer)

            lh = SeaPearl.LearnedHeuristic{SeaPearl.DefaultStateRepresentation, TestReward, SeaPearl.FixedOutput}(agent)
            SeaPearl.update_with_cpmodel!(lh, model)

            lh.reward.value = 0
            SeaPearl.set_reward!(SeaPearl.DecisionPhase(), lh, model)
            @test lh.reward.value == 3
        end

        @testset "set_reward!(EndingPhase)" begin
            trailer = SeaPearl.Trailer()
            model = SeaPearl.CPModel(trailer)

            lh = SeaPearl.LearnedHeuristic{SeaPearl.DefaultStateRepresentation, TestReward, SeaPearl.FixedOutput}(agent)
            SeaPearl.update_with_cpmodel!(lh, model)

            lh.reward.value = 6
            SeaPearl.set_reward!(SeaPearl.EndingPhase(), lh, model, nothing)
            @test lh.reward.value == 1
        end
    end

end
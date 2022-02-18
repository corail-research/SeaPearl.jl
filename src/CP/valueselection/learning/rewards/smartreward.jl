"""
    struct SmartReward <: AbstractReward end

This is the smart reward, that will be used to teach the agent to prioritize paths that lead to improving solutions.
This reward is the exact reward implemented by Quentin Cappart in
his recent paper: Combining RL & CP for Combinatorial Optimization, https://arxiv.org/pdf/2006.01610.pdf.
"""
mutable struct SmartReward <: AbstractReward 
    value::Float32
end

ρ = 1

SmartReward(model::CPModel) = SmartReward(0)

"""
    set_reward!(::StepPhase, lh::LearnedHeuristic{SmartReward, A}, model::CPModel, symbol::Union{Nothing, Symbol})

Change the "current_reward" attribute of the LearnedHeuristic at the StepPhase.
"""
function set_reward!(::Type{StepPhase}, lh::LearnedHeuristic{SR, SmartReward, A}, model::CPModel, symbol::Union{Nothing, Symbol}) where {
    SR <: AbstractStateRepresentation,
    A <: ActionOutput
}
    if symbol == :Infeasible  
        lh.reward.value -= 0
    elseif symbol == :FoundSolution #last portion required to get the full closed path
        dist = model.adhocInfo[1]
        n =  size(dist)[1]
        max_dist = Float32(Base.maximum(dist))
            if isbound(model.variables["a_"*string(n-1)])
                last = assignedValue(model.variables["a_"*string(n-1)])
                first = assignedValue(model.variables["a_1"])
        
                dist_to_first_node = lh.current_state.dist[last, first] * max_dist
                print("final_dist : ", dist_to_first_node, " // ")
                lh.reward.value += -ρ*dist_to_first_node 
            end
    elseif symbol == :Feasible 
        lh.reward.value -= 0
    elseif symbol == :BackTracking
        lh.reward.value -= 0
    end
end

"""
    set_reward!(::DecisionPhase, lh::LearnedHeuristic{SmartReward, O}, model::CPModel)

Change the current reward at the DecisionPhase. This is called right before making the next decision, so you know you have the very last state before the new decision and every computation like fixPoints and backtracking has been done.

This computes the reward : ρ*( 1+ tour_upper_bound  - last_dist) where ρ is a constant, tour_upper_bound and upper bound of the tour and lastdist the distance between the previous node and the target node decided by the previous decision (the reward is attributed just before takng a new decision)
"""
function set_reward!(::Type{DecisionPhase}, lh::LearnedHeuristic{SR, SmartReward, A}, model::CPModel) where {
    SR <: AbstractStateRepresentation,
    A <: ActionOutput
}
    dist = model.adhocInfo[1]
    n =  size(dist)[1]

    tour_upper_bound = Base.maximum(dist) * n
    max_dist = Float32(Base.maximum(dist))

    if !isnothing(model.statistics.lastVar)
        x = model.statistics.lastVar
        s = x.id
        current = parse(Int,split(x.id,'_')[2])
        if isbound(model.variables["a_"*string(current)])
            a_i = assignedValue(model.variables["a_"*string(current)])
            v_i = assignedValue(model.variables["v_"*string(current)])
            last_dist = lh.current_state.dist[v_i, a_i] * max_dist
            #print("last_dist : ", last_dist, " // ")
            lh.reward.value += ρ*( 1+ tour_upper_bound  - last_dist)
        end

    end


end


"""
    set_reward!(::EndingPhase, lh::LearnedHeuristic{SmartReward, A}, model::CPModel, symbol::Union{Nothing, Symbol})

Increment the current reward at the EndingPhase. Called when the search is finished by an optimality proof or by a limit in term of nodes or 
in terms of number of solution. This is useful to add some general results to the reward like the number of ndoes visited during the episode for instance. 
"""
function set_reward!(::Type{EndingPhase}, lh::LearnedHeuristic{SR, SmartReward, A}, model::CPModel, symbol::Union{Nothing, Symbol}) where {
    SR <: AbstractStateRepresentation, 
    A <: ActionOutput
}
    lh.reward.value += 0

end

struct metrics{Obj::Bool, H<:valueSelection} <: AbstractMetrics
    NodeVisited::Vector{Array{Int64}}
    meanNodeVisitedUntilOptimality::Vector{Vector{Float32}}
    timeneeded::Array{Float32}
    scores::Union{Nothing,Vector{Array{Int64}}}
    total_reward::Union{Nothing,Array{Float32}}
    loss::Union{Nothing,Array{Float32}}
    
    meanOver::Int64
    nb_episodes::Int64

    basicmetrics{Obj,L}(model::CPModel, meanOver) where {Obj, L}=new{Obj, L}(Vector{Array{Int64}}(),Vector{Vector{Float32}}(), Float32[], Obj ? Nothing : Vector{Array{Int64}}(), isa(L,BasicHeuristic) ? Nothing : Float32[], isa(L,BasicHeuristic) ? Nothing : Float32[], meanOver,0)
end

basicmetrics(model::CPModel, heuristic::ValueSelection; meanOver=10)=basicmetrics{isnothing(model.objective),heuristic}(model, meanOver)

function (metrics::basicmetrics{false, BasicHeuristic})(model::CPModel,dt::Float64)
    nb_episodes+=1
    push!(NodeVisited,CPModel.statistics.nodevisitedpersolution)
    timeneeded = dt
    computemean(metrics)

end 

function (metrics::basicmetrics{true, BasicHeuristic})(model::CPModel,dt::Float64)
    nb_episodes+=1
    push!(NodeVisited,CPModel.statistics.nodevisitedpersolution)
    push!(relativescores,model.statistics.objectives ./ model.statistics.objectives[size(model.statistics.objectives,1)])
    timeneeded = dt

end 

function (metrics::basicmetrics{false, LearnedHeuristic})(model::CPModel,dt::Float64, agent::ReinforcementLearning.Agent)
    nb_episodes+=1
    push!(NodeVisited,CPModel.statistics.nodevisitedpersolution)
    push!(total_reward,last_episode_total_reward(agent.trajectory))
    push!(loss,agent.policy.learner.loss)
    timeneeded = dt

end 

function (metrics::basicmetrics{true, LearnedHeuristic})(model::CPModel,dt::Float64, agent::ReinforcementLearning.Agent)
    nb_episodes+=1
    push!(NodeVisited,CPModel.statistics.nodevisitedpersolution)
    push!(relativescores,model.statistics.objectives ./ model.statistics.objectives[size(model.statistics.objectives,1)])
    push!(total_reward,last_episode_total_reward(agent.trajectory))
    push!(loss,agent.policy.learner.loss)
    timeneeded = dt

end 


function computemean(metrics::basicmetrics{Obj, H}) where{Obj, H}
    nodeVisitedUntilOptimality = [ nodes[size(nodes-1)] for nodes in NodeVisited]
    for i in 1:metrics.nb_episodes
        currentMean = 0.
        currentMean = (i <= metrics.meanOver) ? mean(nodeVisitedLearned[1:i]) : mean(nodeVisitedLearned[(i-meanOver+1):i])
        push!(meanNodeVisitedUntilOptimality,currentMean)
    end
end 
    

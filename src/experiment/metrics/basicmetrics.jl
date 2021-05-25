


mutable struct basicmetrics{OBJ,H<:ValueSelection} <: AbstractMetrics
    NodeVisited::Vector{Array{Int64}}
    meanNodeVisitedUntilfirstSolFound::Vector{Float32}
    meanNodeVisitedUntilOptimality::Vector{Float32}
    timeneeded::Array{Float32}
    scores::Union{Nothing,Vector{Array{Float32}}}
    total_reward::Union{Nothing,Array{Float32}}
    loss::Union{Nothing,Array{Float32}}
    meanOver::Int64
    nb_episodes::Int64

    basicmetrics{OBJ,H}(model::CPModel, meanOver) where {OBJ,H}= new{OBJ, H}(Vector{Array{Int64}}(),Vector{Vector{Float32}}(),Vector{Vector{Float32}}(), Float32[], OBJ ? Vector{Array{Float32}}() : nothing, (H == BasicHeuristic) ? nothing : Float32[], (H == BasicHeuristic) ? nothing : Float32[], meanOver,0)
end

basicmetrics(model::CPModel, heuristic; meanOver=50) = basicmetrics{!isnothing(model.objective),typeof(heuristic)}(model, meanOver)

function (metrics::basicmetrics{false, BasicHeuristic})(model::CPModel,dt::Float64)
    metrics.nb_episodes+=1
    push!(metrics.NodeVisited,model.statistics.nodevisitedpersolution)
    push!(metrics.timeneeded,dt)

end 

function (metrics::basicmetrics{true, BasicHeuristic})(model::CPModel,dt::Float64)
    metrics.nb_episodes+=1
    push!(metrics.NodeVisited,model.statistics.nodevisitedpersolution)
    push!(metrics.scores,model.statistics.objectives ./ model.statistics.objectives[size(model.statistics.objectives,1)])
    push!(metrics.timeneeded,dt)

end 

function (metrics::basicmetrics{false, LearnedHeuristic{SR, R, A}})(model::CPModel, agent::ReinforcementLearning.Agent,dt::Float64) where {SR,R,A}
    metrics.nb_episodes+=1
    push!(metrics.NodeVisited,model.statistics.nodevisitedpersolution)
    push!(metrics.total_reward,last_episode_total_reward(agent.trajectory))
    push!(metrics.loss,agent.policy.learner.loss)
    push!(metrics.timeneeded,dt)

end 

function (metrics::basicmetrics{true, LearnedHeuristic{SR, R, A}})(model::CPModel,agent::ReinforcementLearning.Agent,dt::Float64) where {SR,R,A}
    metrics.nb_episodes+=1
    push!(metrics.NodeVisited,model.statistics.nodevisitedpersolution)
    push!(metrics.scores,model.statistics.objectives ./ model.statistics.objectives[size(model.statistics.objectives,1)])
    push!(metrics.total_reward,last_episode_total_reward(agent.trajectory))
    push!(metrics.loss,agent.policy.learner.loss)
    push!(metrics.timeneeded,dt)

end 


function computemean(metrics::basicmetrics{OBJ, H}) where{OBJ, H<:ValueSelection}
    nodeVisitedUntilFirstSolFound = [ nodes[1] for nodes in metrics.NodeVisited]
    nodeVisitedUntilOptimality = [ nodes[size(nodes,1)] for nodes in metrics.NodeVisited]
    for i in 1:metrics.nb_episodes
        currentSolMean = (i <= metrics.meanOver) ? mean(nodeVisitedUntilFirstSolFound[1:i]) : mean(nodeVisitedUntilFirstSolFound[(i-metrics.meanOver+1):i])
        currentOptMean = (i <= metrics.meanOver) ? mean(nodeVisitedUntilOptimality[1:i]) : mean(nodeVisitedUntilOptimality[(i-metrics.meanOver+1):i])
        push!(metrics.meanNodeVisitedUntilfirstSolFound,currentSolMean)
        push!(metrics.meanNodeVisitedUntilOptimality,currentOptMean)
    end
end 
    
function plotNodeVisited(metrics::basicmetrics{OBJ, H}) where{OBJ, H<:ValueSelection}
    max_y =1.1*maximum([maximum(metrics.nodeVisitedUntilOptimality),maximum(metrics.nodeVisitedUntilFirstSolFound)])
    p = plot(
        1:nb_episodes, 
        [metrics.nodeVisitedUntilOptimality[1:metrics.nb_episodes] metrics.nodeVisitedUntilFirstSolFound[1:metrics.nb_episodes]], 
        xlabel="Episode", 
        ylabel="Number of nodes visited", 
        label = ["Until Optimality", "Until First Solution Found"],
        ylims = (0,max_y)
    )
    display(p)
    savefig(p,"node_visited_knapsack_$(knapsack_generator.nb_items).png")
end

function store_training_data(metrics::basicmetrics{OBJ, H}, title::String) where{OBJ, H<:ValueSelection}
    df = DataFrame()
    for i in 1:nb_instances
        df[!, string(i)*"_node_visited_until_first_solution_found"] = metrics.nodeVisitedUntilFirstSolFound[i]
        df[!, string(i)*"_node_visited_until_optimality"] = metrics.meanNodeVisitedUntilOptimality[i]
        df[!, string(i)*"_time_needed"] = metrics.timeneeded[i]
    end
    CSV.write(title*".csv", df)
end

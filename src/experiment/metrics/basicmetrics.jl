
using Plots
using RollingFunctions




mutable struct basicmetrics{OBJ<:AbstractTakeObjective, H<:ValueSelection} <: AbstractMetrics
    heuristic::H
    NodeVisited::Vector{Vector{Int64}}
    meanNodeVisitedUntilfirstSolFound::Vector{Float32}
    meanNodeVisitedUntilOptimality::Vector{Float32}
    timeneeded::Vector{Float32}
    scores::Union{Nothing,Vector{Vector{Float32}}}
    total_reward::Union{Nothing,Vector{Float32}}
    loss::Union{Nothing,Vector{Float32}}
    meanOver::Int64
    nb_episodes::Int64
    basicmetrics{OBJ,H}(heuristic,meanOver) where {OBJ,H}= new{OBJ, H}(heuristic,Vector{Vector{Int64}}(),Float32[],Float32[], Float32[], OBJ==TakeObjective ? Vector{Vector{Float32}}() : nothing, (H == BasicHeuristic) ? nothing : Float32[], (H == BasicHeuristic) ? nothing : Float32[], meanOver,0)
end

basicmetrics(model::CPModel, heuristic; meanOver=20) = basicmetrics{(!isnothing(model.objective)) ? TakeObjective : DontTakeObjective ,typeof(heuristic)}(heuristic,meanOver)

function (metrics::basicmetrics{DontTakeObjective, BasicHeuristic})(model::CPModel,dt::Float64)
    metrics.nb_episodes+=1
    push!(metrics.NodeVisited,copy(model.statistics.nodevisitedpersolution))
    push!(metrics.meanNodeVisitedUntilOptimality,model.statistics.numberOfNodes)
    push!(metrics.timeneeded,dt)
end 

function (metrics::basicmetrics{TakeObjective, BasicHeuristic})(model::CPModel,dt::Float64)
    metrics.nb_episodes+=1
    push!(metrics.NodeVisited,copy(model.statistics.nodevisitedpersolution))
    push!(metrics.scores,copy(model.statistics.objectives ./ model.statistics.objectives[size(model.statistics.objectives,1)]))
    push!(metrics.meanNodeVisitedUntilOptimality,model.statistics.numberOfNodes)
    push!(metrics.timeneeded,dt)

end 

function (metrics::basicmetrics{DontTakeObjective, LearnedHeuristic{SR, R, A}})(model::CPModel,dt::Float64) where {SR,R,A}
    metrics.nb_episodes+=1
    push!(metrics.NodeVisited,copy(model.statistics.nodevisitedpersolution))
    push!(metrics.meanNodeVisitedUntilOptimality,model.statistics.numberOfNodes)
    push!(metrics.total_reward,last_episode_total_reward(metrics.heuristic.agent.trajectory))
    push!(metrics.loss,metrics.heuristic.agent.policy.learner.loss)
    push!(metrics.timeneeded,dt)

end 

function (metrics::basicmetrics{TakeObjective, LearnedHeuristic{SR, R, A}})(model::CPModel,dt::Float64) where {SR,R,A}
    metrics.nb_episodes+=1
    push!(metrics.NodeVisited,copy(model.statistics.nodevisitedpersolution))
    push!(metrics.meanNodeVisitedUntilOptimality,model.statistics.numberOfNodes)
    push!(metrics.scores,copy(model.statistics.objectives ./ model.statistics.objectives[size(model.statistics.objectives,1)]))
    push!(metrics.total_reward,last_episode_total_reward(metrics.heuristic.agent.trajectory))
    push!(metrics.loss,metrics.heuristic.agent.policy.learner.loss)
    push!(metrics.timeneeded,dt)

end 


function computemean!(metrics::basicmetrics{OBJ, H}) where{OBJ, H<:ValueSelection}
    windowspan = min(metrics.meanOver,length(metrics.NodeVisited))
    nodeVisitedUntilFirstSolFound = [ nodes[1] for nodes in metrics.NodeVisited]
    metrics.meanNodeVisitedUntilfirstSolFound = rollmean(nodeVisitedUntilFirstSolFound, windowspan)
    nodeVisitedUntilOptimality = copy(metrics.meanNodeVisitedUntilOptimality)
    metrics.meanNodeVisitedUntilOptimality = rollmean(nodeVisitedUntilOptimality,windowspan)
end 
    
function plotNodeVisited(metrics::basicmetrics{OBJ, H}; filename::String="") where{OBJ, H<:ValueSelection}
    max_Opt =1.1*Base.maximum(metrics.meanNodeVisitedUntilOptimality)
    max_Fsf =1.1*Base.maximum(metrics.meanNodeVisitedUntilfirstSolFound)
    L = length(metrics.meanNodeVisitedUntilOptimality)
    println(L)
    p = plot(
        1:L, 
        [metrics.meanNodeVisitedUntilOptimality[1:L] metrics.meanNodeVisitedUntilfirstSolFound[1:L]], 
        xlabel="Episode", 
        ylabel="Number of nodes visited",
        label = ["Until Optimality" "Until First Solution Found"],
        layout = (2, 1)
    )
    display(p)
    #savefig(p,filename*"_node_visited_"*"$(metrics.heuristic)"*".png")
end

function plotScoreVariation(metrics::basicmetrics{OBJ, H}; filename::String="") where{OBJ, H<:ValueSelection}
    Data=[]
    for i in length(metrics.NodeVisited):-1:1
        push!(Data,hcat(metrics.NodeVisited[i],metrics.scores[i]))
    end

    p = plot(
        [scatter[:,1] for scatter in Data], 
        [scatter[:,2] for scatter in Data], 
        #fillrange =[[ones(length(scatter[:,2])),scatter[:,2]] for scatter in Data],
        #fillalpha=1,
        xlabel="number of nodes visited", 
        ylabel="relative score",
        xaxis=:log, 
    )
    display(p)
    #savefig(p,filename*"_node_visited_"*"$(metrics.heuristic)"*".png")
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

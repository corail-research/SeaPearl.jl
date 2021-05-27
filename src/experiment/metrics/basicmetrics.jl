using Plots
using RollingFunctions
using BSON
"""
    BasicMetrics{O<:AbstractTakeObjective, H<:ValueSelection} <: AbstractMetrics

`BasicMetrics` is a Type that stores useful information derived from consecutive search, during either a learning process or an evaluation process. It is filled just after a search. The metrics are called in the `launch_experiment()` function and in the `evaluate()` function.

It satisfies the two AbstractMetrics requirements: 
1) the constructor `metrics(model::CPModel, heuristic::ValueSelection)`.
2) the function `(::CustomMetrics)(model::CPmodel,dt::Float64)`.

# Fields

    heuristic::H                                        ->  The related heuristic for which the metrics stores the results.
    nodeVisited::Vector{Vector{Int64}}                  ->  contains the result of each search in term of node visited : number of nodes visited to 
                                                            find every solution of an instance until optimality.
    meanNodeVisitedUntilfirstSolFound::Vector{Float32}  ->  contains the result of each search in term of node visited to find a first solution.
    meanNodeVisitedUntilOptimality::Vector{Float32}     ->  contains the result of each search in term of node visited to prove optimality.
    timeneeded::Vector{Float32}                         ->  contains the computing time required to complete each search (ie. prove optimality).
    scores::Union{Nothing,Vector{Vector{Float32}}}      ->  contains the result of each search in term of relative scores of every solution found 
                                                            compared to the optimal solution.    (only for problem that contains an objective)
    totalReward::Union{Nothing,Vector{Float32}}        ->  contains the total reward of each search (only if heuristic is a LearnedHeuristic).
    loss::Union{Nothing,Vector{Float32}}                ->  contains the total loss of each search (only if heuristic is a LearnedHeuristic).
    meanOver::Int64                                     ->  width of the windowspan for the moving average.
    nbEpisodes::Int64                                  ->  counts the number of search the metrics has been called on. 
"""
mutable struct BasicMetrics{O<:AbstractTakeObjective, H<:ValueSelection} <: AbstractMetrics
    heuristic::H
    nodeVisited::Vector{Vector{Int64}}
    meanNodeVisitedUntilfirstSolFound::Vector{Float32}
    meanNodeVisitedUntilOptimality::Vector{Float32}
    timeneeded::Vector{Float32}
    scores::Union{Nothing,Vector{Vector{Float32}}}
    totalReward::Union{Nothing,Vector{Float32}}
    loss::Union{Nothing,Vector{Float32}}
    meanOver::Int64
    nbEpisodes::Int64

    BasicMetrics{O,H}(heuristic,meanOver) where {O,H}= new{O, H}(heuristic,Vector{Vector{Int64}}(),Float32[],Float32[], Float32[], O==TakeObjective ? Vector{Vector{Float32}}() : nothing, (H == BasicHeuristic) ? nothing : Float32[], (H == BasicHeuristic) ? nothing : Float32[], meanOver,0)
end

BasicMetrics(model::CPModel, heuristic::ValueSelection; meanOver=20) = BasicMetrics{(!isnothing(model.objective)) ? TakeObjective : DontTakeObjective ,typeof(heuristic)}(heuristic,meanOver)

"""
    function (metrics::BasicMetrics{DontTakeObjective, BasicHeuristic})(model::CPModel,dt::Float64)

The function is called after a search on a Constraint Programming Model.
For a basic heuristic on a problem that doesn't consider an objective, the function stores: 
- the number of nodes visited to find each solution of an instance. 
- the number of nodes visited to complete the search (ie. prove optimality).
- the computing time required to complete each search (ie. prove optimality).
"""
function (metrics::BasicMetrics{DontTakeObjective, BasicHeuristic})(model::CPModel,dt::Float64)
    metrics.nbEpisodes+=1
    push!(metrics.nodeVisited,copy(model.statistics.nodevisitedpersolution))
    push!(metrics.meanNodeVisitedUntilOptimality,model.statistics.numberOfNodes)
    push!(metrics.timeneeded,dt)
end 

"""
    function (metrics::BasicMetrics{TakeObjective, BasicHeuristic})(model::CPModel,dt::Float64)

The function is called after a search on a Constraint Programming Model.
For a basic heuristic on a problem that considers an objective, the function stores: 
- the number of nodes visited to find each solution of an instance. 
- the number of nodes visited to complete the search (ie. prove optimality).
- the computing time required to complete each search (ie. prove optimality).
- the relative scores of every solution found compared to the optimal solution.
"""
function (metrics::BasicMetrics{TakeObjective, BasicHeuristic})(model::CPModel,dt::Float64)
    metrics.nbEpisodes+=1
    push!(metrics.nodeVisited,copy(model.statistics.nodevisitedpersolution))
    push!(metrics.meanNodeVisitedUntilOptimality,model.statistics.numberOfNodes)
    push!(metrics.timeneeded,dt)
    push!(metrics.scores,copy(model.statistics.objectives ./ model.statistics.objectives[size(model.statistics.objectives,1)]))


end 

"""
    function (metrics::BasicMetrics{DontTakeObjective, LearnedHeuristic{SR, R, A}})(model::CPModel,dt::Float64) where {SR,R,A}

The function is called after a search on a Constraint Programming Model.
For a learnedheuristic on a problem that doesn't consider an objective, the function stores: 
- the number of nodes visited to find each solution of an instance. 
- the number of nodes visited to complete the search (ie. prove optimality).
- the computing time required to complete each search (ie. prove optimality).
- the total reward of each search.
- the total loss of each search.
"""
function (metrics::BasicMetrics{DontTakeObjective, LearnedHeuristic{SR, R, A}})(model::CPModel,dt::Float64) where {SR,R,A}
    metrics.nbEpisodes+=1
    push!(metrics.nodeVisited,copy(model.statistics.nodevisitedpersolution))
    push!(metrics.meanNodeVisitedUntilOptimality,model.statistics.numberOfNodes)
    push!(metrics.timeneeded,dt)
    push!(metrics.totalReward,last_episode_total_reward(metrics.heuristic.agent.trajectory))
    push!(metrics.loss,metrics.heuristic.agent.policy.learner.loss)

end 

"""
    function (metrics::BasicMetrics{TakeObjective, LearnedHeuristic{SR, R, A}})(model::CPModel,dt::Float64) where {SR,R,A}

The function is called after a search on a Constraint Programming Model.
For a learnedheuristic on a problem that considers an objective, the function stores: 
- the number of nodes visited to find each solution of an instance. 
- the number of nodes visited to complete the search (ie. prove optimality).
- the computing time required to complete each search (ie. prove optimality).
- the relative scores of every solution found compared to the optimal solution.
- the total reward of each search.
- the total loss of each search.
"""
function (metrics::BasicMetrics{TakeObjective, LearnedHeuristic{SR, R, A}})(model::CPModel,dt::Float64) where {SR,R,A}
    metrics.nbEpisodes+=1
    push!(metrics.nodeVisited,copy(model.statistics.nodevisitedpersolution))
    push!(metrics.meanNodeVisitedUntilOptimality,model.statistics.numberOfNodes)
    push!(metrics.timeneeded,dt)
    push!(metrics.scores,copy(model.statistics.objectives ./ model.statistics.objectives[size(model.statistics.objectives,1)]))
    push!(metrics.totalReward,last_episode_total_reward(metrics.heuristic.agent.trajectory))
    push!(metrics.loss,metrics.heuristic.agent.policy.learner.loss)

end 

"""
    function computemean!(metrics::BasicMetrics{O, H}) where{O, H<:ValueSelection}

At the end of an experiment, as the instances generated by the generator could be slightly different 
(depending on the distribution of the generator), a moving average is applied on the vectors containing : 
1) number of node visited by the heuristic to find a first solution along the training. 
2) number of node visited by the heuristic to prove to optimality along the training. 

this averaging smoothes the high frequency variations due to the differences between CPModel instances. 
"""
function computemean!(metrics::BasicMetrics{O, H}) where{O, H<:ValueSelection} 
    windowspan = min(metrics.meanOver,length(metrics.nodeVisited))
    nodeVisitedUntilFirstSolFound = [ nodes[1] for nodes in metrics.nodeVisited]
    metrics.meanNodeVisitedUntilfirstSolFound = rollmean(nodeVisitedUntilFirstSolFound, windowspan)
    nodeVisitedUntilOptimality = copy(metrics.meanNodeVisitedUntilOptimality)
    metrics.meanNodeVisitedUntilOptimality = rollmean(nodeVisitedUntilOptimality,windowspan)
end 
    
"""
    function plotNodeVisited(metrics::BasicMetrics{O, H}; filename::String="") where{O<:AbstractTakeObjective, H<:ValueSelection}

plot 2 graphs : 
1) number of node visited by the heuristic to find a first solution for every learning episode. 
2) number of node visited by the heuristic to prove to optimality for every learning episode. 

The learning process should show a decrease in the number of nodes required to find a first solution along the search 
(depending on the reward engineering).
"""
function plotNodeVisited(metrics::BasicMetrics{O, H}; filename::String="") where{O<:AbstractTakeObjective, H<:ValueSelection}
    L = length(metrics.meanNodeVisitedUntilOptimality)
    p = plot(
        1:L, 
        [metrics.meanNodeVisitedUntilOptimality[1:L] metrics.meanNodeVisitedUntilfirstSolFound[1:L]], 
        xlabel="Episode", 
        ylabel="Nodes visited",
        title = ["Node visited until Optimality" "Node visited until first solution found"],
        layout = (2, 1)
    )
    display(p)
    savefig(p,filename*"_node_visited_"*"$(typeof(metrics.heuristic))"*".png")
end

"""
    function plotScoreVariation(metrics::BasicMetrics{O, H}; filename::String="") where{O<:AbstractTakeObjective, H<:ValueSelection}

plot the relative scores ( compared to the optimal ) of the heuristic during the search for fixed instances along the training. This plot is 
meaningful only if the metrics is one from the evaluator (ie. the instance remains the same one).
"""
function plotScoreVariation(metrics::BasicMetrics{TakeObjective, H}; filename::String="") where{H<:ValueSelection}
    Data=[]
    for i in length(metrics.nodeVisited):-1:1
        push!(Data,hcat(metrics.nodeVisited[i],metrics.scores[i]))
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
    savefig(p,filename*"_score_variation_"*"$(typeof(metrics.heuristic))"*".png")
end

"""
    function store_data(metrics::BasicMetrics{O, H}, title::String) where{O<:AbstractTakeObjective, H<:ValueSelection}

Store useful results from consecutive search in `.csv` file. 
"""
function store_data(metrics::BasicMetrics{O, H}, title::String) where{O<:AbstractTakeObjective, H<:ValueSelection}
    df = DataFrame()
    for i in 1:nbInstances
        df[!, string(i)*"_node_visited"] = metrics.nodeVisited[i]
        df[!, string(i)*"_node_visited_until_first_solution_found"] = metrics.nodeVisitedUntilFirstSolFound[i]
        df[!, string(i)*"_node_visited_until_optimality"] = metrics.meanNodeVisitedUntilOptimality[i]
        df[!, string(i)*"_time_needed"] = metrics.timeneeded[i]
        if !isnothing(metrics.scores)           
            df[!, string(i)*"_score"] = metrics.scores[i]
        end
        if !isnothing(metrics.totalReward)   #if the heuristic is a learned heuristic
            df[!, string(i)*"_total_reward"] = metrics.totalReward[i]
            df[!, string(i)*"_loss"] = metrics.loss[i]
        end
    end
    CSV.write(title*".csv", df)
end

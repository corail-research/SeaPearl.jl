using Plots
using RollingFunctions

"""
    basicmetrics{O<:AbstractTakeObjective, H<:ValueSelection} <: AbstractMetrics

basicmetrics is a DataStructures that stores usefull informations derived from consecutive search during eather 
a learning process or an evaluation process. it is filled just after a search. The metric is called in the 
launch_experiment() function and in the evaluate() function.

It satisfy the two AbstractMetrics requirements : 
1) the constructor metrics(model::CPModel, heuristic::ValueSelection) 
2) the function (::CustomMetrics)(model::CPmodel,dt::Float64) 

Significations:

    heuristic::H                                        ->  The related heuristic for which the metrics stores the results
    NodeVisited::Vector{Vector{Int64}}                  ->  contains the result of each search in term of node visited : number of nodes visited to 
                                                            find every solution of an instance until the optimality
    meanNodeVisitedUntilfirstSolFound::Vector{Float32}  ->  contains the result of each search in term of node visited to find a first solution
    meanNodeVisitedUntilOptimality::Vector{Float32}     ->  contains the result of each search in term of node visited to prove optimality
    timeneeded::Vector{Float32}                         ->  contains the computing time required to complete each search (ie. prove optimality)
    scores::Union{Nothing,Vector{Vector{Float32}}}      ->  contains the result of each search in term of relative scores of every solution found 
                                                            compared to the optimal solution.    (only for problem that contains an objective)
    total_reward::Union{Nothing,Vector{Float32}}        ->  contains the total reward of each search ( only if heuristic is a LearnedHeuristic)
    loss::Union{Nothing,Vector{Float32}}                ->  contains the total loss of each search ( only if heuristic is a LearnedHeuristic)
    meanOver::Int64                                     ->  width of the windowspan for the moving average
    nb_episodes::Int64                                  ->  counts the number of search the metrics has been called on. 
"""
mutable struct basicmetrics{O<:AbstractTakeObjective, H<:ValueSelection} <: AbstractMetrics
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

    basicmetrics{O,H}(heuristic,meanOver) where {O,H}= new{O, H}(heuristic,Vector{Vector{Int64}}(),Float32[],Float32[], Float32[], O==TakeObjective ? Vector{Vector{Float32}}() : nothing, (H == BasicHeuristic) ? nothing : Float32[], (H == BasicHeuristic) ? nothing : Float32[], meanOver,0)
end

basicmetrics(model::CPModel, heuristic::ValueSelection; meanOver=20) = basicmetrics{(!isnothing(model.objective)) ? TakeObjective : DontTakeObjective ,typeof(heuristic)}(heuristic,meanOver)

"""
    function (metrics::basicmetrics{DontTakeObjective, BasicHeuristic})(model::CPModel,dt::Float64)

The function is called after a search on a Constraint Programming Model.
For a basic heuristic on a problem that doesn't consider an objective, the function store : 
- the number of nodes visited to find each solution of an instance. 
- the number of nodes visited to complete the search (ie. prove the optimality)
- the computing time required to complete each search (ie. prove optimality)
"""
function (metrics::basicmetrics{DontTakeObjective, BasicHeuristic})(model::CPModel,dt::Float64)
    metrics.nb_episodes+=1
    push!(metrics.NodeVisited,copy(model.statistics.nodevisitedpersolution))
    push!(metrics.meanNodeVisitedUntilOptimality,model.statistics.numberOfNodes)
    push!(metrics.timeneeded,dt)
end 

"""
    function (metrics::basicmetrics{TakeObjective, BasicHeuristic})(model::CPModel,dt::Float64)

The function is called after a search on a Constraint Programming Model.
For a basic heuristic on a problem that considers an objective, the function store : 
- the number of nodes visited to find each solution of an instance. 
- the number of nodes visited to complete the search (ie. prove the optimality)
- the computing time required to complete each search (ie. prove optimality)
- the relative scores of every solution found compared to the optimal solution.
"""
function (metrics::basicmetrics{TakeObjective, BasicHeuristic})(model::CPModel,dt::Float64)
    metrics.nb_episodes+=1
    push!(metrics.NodeVisited,copy(model.statistics.nodevisitedpersolution))
    push!(metrics.meanNodeVisitedUntilOptimality,model.statistics.numberOfNodes)
    push!(metrics.timeneeded,dt)
    push!(metrics.scores,copy(model.statistics.objectives ./ model.statistics.objectives[size(model.statistics.objectives,1)]))


end 

"""
    function (metrics::basicmetrics{DontTakeObjective, LearnedHeuristic{SR, R, A}})(model::CPModel,dt::Float64) where {SR,R,A}

The function is called after a search on a Constraint Programming Model.
For a learnedheuristic on a problem that doesn't consider an objective, the function store : 
- the number of nodes visited to find each solution of an instance. 
- the number of nodes visited to complete the search (ie. prove the optimality)
- the computing time required to complete each search (ie. prove optimality)
- the total reward of each search
- the total loss of each search
"""
function (metrics::basicmetrics{DontTakeObjective, LearnedHeuristic{SR, R, A}})(model::CPModel,dt::Float64) where {SR,R,A}
    metrics.nb_episodes+=1
    push!(metrics.NodeVisited,copy(model.statistics.nodevisitedpersolution))
    push!(metrics.meanNodeVisitedUntilOptimality,model.statistics.numberOfNodes)
    push!(metrics.timeneeded,dt)
    push!(metrics.total_reward,last_episode_total_reward(metrics.heuristic.agent.trajectory))
    push!(metrics.loss,metrics.heuristic.agent.policy.learner.loss)

end 

"""
    function (metrics::basicmetrics{TakeObjective, LearnedHeuristic{SR, R, A}})(model::CPModel,dt::Float64) where {SR,R,A}

The function is called after a search on a Constraint Programming Model.
For a learnedheuristic on a problem that considers an objective, the function store : 
- the number of nodes visited to find each solution of an instance. 
- the number of nodes visited to complete the search (ie. prove the optimality)
- the computing time required to complete each search (ie. prove optimality)
- the relative scores of every solution found compared to the optimal solution.
- the total reward of each search
- the total loss of each search
"""
function (metrics::basicmetrics{TakeObjective, LearnedHeuristic{SR, R, A}})(model::CPModel,dt::Float64) where {SR,R,A}
    metrics.nb_episodes+=1
    push!(metrics.NodeVisited,copy(model.statistics.nodevisitedpersolution))
    push!(metrics.meanNodeVisitedUntilOptimality,model.statistics.numberOfNodes)
    push!(metrics.timeneeded,dt)
    push!(metrics.scores,copy(model.statistics.objectives ./ model.statistics.objectives[size(model.statistics.objectives,1)]))
    push!(metrics.total_reward,last_episode_total_reward(metrics.heuristic.agent.trajectory))
    push!(metrics.loss,metrics.heuristic.agent.policy.learner.loss)

end 

"""
    function computemean!(metrics::basicmetrics{O, H}) where{O, H<:ValueSelection}

At the end of an experiment, as the instances generated by the generator could be slightly different 
(depending on the distribution of the generator), a moving average is applied on the vectors containing : 
1) number of node visited by the heuristic to find a first solution along the training. 
2) number of node visited by the heuristic to prove to optimality along the training. 

this averaging smoothes the high frequency variations due to the differences between CPModel instances. 
"""
function computemean!(metrics::basicmetrics{O, H}) where{O, H<:ValueSelection} 
    windowspan = min(metrics.meanOver,length(metrics.NodeVisited))
    nodeVisitedUntilFirstSolFound = [ nodes[1] for nodes in metrics.NodeVisited]
    metrics.meanNodeVisitedUntilfirstSolFound = rollmean(nodeVisitedUntilFirstSolFound, windowspan)
    nodeVisitedUntilOptimality = copy(metrics.meanNodeVisitedUntilOptimality)
    metrics.meanNodeVisitedUntilOptimality = rollmean(nodeVisitedUntilOptimality,windowspan)
end 
    
"""
    function plotNodeVisited(metrics::basicmetrics{O, H}; filename::String="") where{O<:AbstractTakeObjective, H<:ValueSelection}

plot 2 graphs : 
1) number of node visited by the heuristic to find a first solution for every learning episode. 
2) number of node visited by the heuristic to prove to optimality for every learning episode. 

The learning process should show a decrease in the number of nodes required to find a first solution along the search 
( depending on the reward engineering ).
"""
function plotNodeVisited(metrics::basicmetrics{O, H}; filename::String="") where{O<:AbstractTakeObjective, H<:ValueSelection}
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

"""
    function plotScoreVariation(metrics::basicmetrics{O, H}; filename::String="") where{O<:AbstractTakeObjective, H<:ValueSelection}

plot the relative scores ( compared to the optimal ) of the heuristic during the search for fixed instances along the training. This plot is 
meanningfull only if the metrics is one from the evaluator (ie. the instance remains the same one ).
"""
function plotScoreVariation(metrics::basicmetrics{O, H}; filename::String="") where{O<:AbstractTakeObjective, H<:ValueSelection}
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

"""
    function store_data(metrics::basicmetrics{O, H}, title::String) where{O<:AbstractTakeObjective, H<:ValueSelection}

Store usefull results from consecutive search in .csv file. 
"""
function store_data(metrics::basicmetrics{O, H}, title::String) where{O<:AbstractTakeObjective, H<:ValueSelection}
    df = DataFrame()
    for i in 1:nb_instances
        df[!, string(i)*"_node_visited"] = metrics.NodeVisited[i]
        df[!, string(i)*"_node_visited_until_first_solution_found"] = metrics.nodeVisitedUntilFirstSolFound[i]
        df[!, string(i)*"_node_visited_until_optimality"] = metrics.meanNodeVisitedUntilOptimality[i]
        df[!, string(i)*"_time_needed"] = metrics.timeneeded[i]
        if !isnothing(metrics.scores)           
            df[!, string(i)*"_score"] = metrics.scores[i]
        end
        if !isnothing(metrics.total_reward)   #if the heuristic is a learned heuristic
            df[!, string(i)*"_total_reward"] = metrics.total_reward[i]
            df[!, string(i)*"_loss"] = metrics.loss[i]
        end
    end
    CSV.write(title*".csv", df)
end

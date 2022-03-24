using RollingFunctions

"""
    BasicMetrics{O<:AbstractTakeObjective, H<:ValueSelection} <: AbstractMetrics

`BasicMetrics` is a Type that stores useful information derived from consecutive search, during either a learning process or an evaluation process. 
It is filled just after a search. The metrics are called in the `launch_experiment()` function and in the `evaluate()` function.

It satisfies the two AbstractMetrics requirements: 
1) the constructor `metrics(model::CPModel, heuristic::ValueSelection)`.
2) the function `(::CustomMetrics)(model::CPmodel,dt::Float64)`.

# Fields

    heuristic::H                                                        ->  The related heuristic for which the metrics stores the results.
    nodeVisited::Vector{Vector{Int64}}                                  ->  contains the result of each search in term of node visited : number of nodes visited to 
                                                                            find every final state found (Solution / Infeasible case) reached during a search.
    meanNodeVisitedUntilfirstSolFound::Vector{Union{Nothing,Float32}}   ->  contains the result of each search in term of node visited to find a first solution. "nothing" means no solution has been found during the entire search. 
    meanNodeVisitedUntilEnd::Vector{Float32}                            ->  contains the result of each search in term of node visited until the end of the search.
    timeneeded::Vector{Float32}                                         ->  contains the computing time required to complete each search.
    scores::Union{Nothing,Vector{Vector{Union{Nothing,Float32}}}}       ->  In case the problem has an objective, contains the result of each search in term of scores of every final state found.   ("score" for Solution /"nothing" for Infeasible case). For each episode, the model.statistics.objectives::Vector{Union{Nothing,Float32}} can be empty (in case no final state has been reached during the search.)
    totalReward::Union{Nothing,Vector{Float32}}         ->  contains the total reward of each search (only if heuristic is a LearnedHeuristic).
    loss::Union{Nothing,Vector{Float32}}                ->  contains the total loss of each search (only if heuristic is a LearnedHeuristic).
    meanOver::Int64                                     ->  width of the windowspan for the moving average.
    nbEpisodes::Int64                                   ->  counts the number of search the metrics has been called on. 
"""
mutable struct BasicMetrics{O<:AbstractTakeObjective, H<:ValueSelection} <: AbstractMetrics
    heuristic::H
    nodeVisited::Vector{Vector{Int64}}
    meanNodeVisitedUntilfirstSolFound::Vector{Union{Nothing,Float32}}
    meanNodeVisitedUntilEnd::Vector{Float32}
    timeneeded::Vector{Float32}
    scores::Union{Nothing,Vector{Vector{Union{Nothing,Float32}}}}
    totalReward::Union{Nothing,Vector{Float32}}
    loss::Union{Nothing,Vector{Float32}}
    meanOver::Int64
    nbEpisodes::Int64

    BasicMetrics{O,H}(heuristic,meanOver) where {O,H}= new{O, H}(heuristic,Vector{Vector{Int64}}(),Vector{Union{Nothing,Float32}}(), Float32[], Float32[], O==TakeObjective ? Vector{Vector{Float32}}() : nothing, (H == BasicHeuristic) ? nothing : Float32[], (H == BasicHeuristic) ? nothing : Float32[], meanOver,0)
end

BasicMetrics(model::CPModel, heuristic::ValueSelection; meanOver=1) = BasicMetrics{(!isnothing(model.objective)) ? TakeObjective : DontTakeObjective ,typeof(heuristic)}(heuristic,meanOver)

"""
    function (metrics::BasicMetrics)(model::CPModel, dt::Float64)

The function is called after a search on a Constraint Programming Model.
It updates all the metrics during the search.
"""
function (metrics::BasicMetrics{DontTakeObjective, <:BasicHeuristic})(model::CPModel,dt::Float64)
    metrics.nbEpisodes+=1
    push!(metrics.nodeVisited,copy(model.statistics.nodevisitedpersolution))
    push!(metrics.meanNodeVisitedUntilEnd,model.statistics.numberOfNodes)
    index = findall(!isnothing, model.statistics.solutions)  #return the index of the first solution if it exist
    push!(metrics.meanNodeVisitedUntilfirstSolFound, !isempty(index) ? model.statistics.nodevisitedpersolution[index[1]] : nothing)
    push!(metrics.timeneeded,dt)
    return
end 

function (metrics::BasicMetrics{TakeObjective, <:BasicHeuristic})(model::CPModel,dt::Float64)
    metrics.nbEpisodes+=1
    push!(metrics.nodeVisited,copy(model.statistics.nodevisitedpersolution))
    push!(metrics.meanNodeVisitedUntilEnd,model.statistics.numberOfNodes)
    index = findall(!isnothing, model.statistics.solutions)  #return the index of the first solution
    push!(metrics.meanNodeVisitedUntilfirstSolFound, !isempty(index) ? model.statistics.nodevisitedpersolution[index[1]] : nothing)
    push!(metrics.timeneeded,dt)
    push!(metrics.scores,copy(model.statistics.objectives))
    

end 

function (metrics::BasicMetrics{DontTakeObjective, <:LearnedHeuristic})(model::CPModel,dt::Float64)
    metrics.nbEpisodes+=1
    push!(metrics.nodeVisited,copy(model.statistics.nodevisitedpersolution))
    push!(metrics.meanNodeVisitedUntilEnd,model.statistics.numberOfNodes)
    index = findall(!isnothing, model.statistics.solutions)  #return the index of the first solution    
    push!(metrics.meanNodeVisitedUntilfirstSolFound, !isempty(index) ? model.statistics.nodevisitedpersolution[index[1]] : nothing)
    push!(metrics.timeneeded,dt)
    push!(metrics.totalReward,last_episode_total_reward(metrics.heuristic.agent.trajectory))
    push!(metrics.loss,metrics.heuristic.agent.policy.learner.loss)
    return
end 


function (metrics::BasicMetrics{TakeObjective, <:LearnedHeuristic})(model::CPModel,dt::Float64) 
    metrics.nbEpisodes+=1
    push!(metrics.nodeVisited,copy(model.statistics.nodevisitedpersolution))
    push!(metrics.meanNodeVisitedUntilEnd,model.statistics.numberOfNodes)
    index = findall(!isnothing, model.statistics.solutions)  #return the index of the first solution    
    push!(metrics.meanNodeVisitedUntilfirstSolFound, !isempty(index) ? model.statistics.nodevisitedpersolution[index[1]] : nothing)
    push!(metrics.timeneeded,dt)
    push!(metrics.scores,copy(model.statistics.objectives))
    push!(metrics.totalReward,last_episode_total_reward(metrics.heuristic.agent.trajectory))
    push!(metrics.loss,metrics.heuristic.agent.policy.learner.loss)
    return
end 

function repeatlast!(metrics::BasicMetrics{<:AbstractTakeObjective, <:BasicHeuristic})
    metrics.nbEpisodes+=1
    push!(metrics.nodeVisited,last(metrics.nodeVisited))
    push!(metrics.meanNodeVisitedUntilEnd,last(metrics.meanNodeVisitedUntilEnd))
    push!(metrics.meanNodeVisitedUntilfirstSolFound,last(metrics.meanNodeVisitedUntilfirstSolFound))
    push!(metrics.timeneeded,last(metrics.timeneeded))
    if !isnothing(metrics.scores)  #In case neither a solution or an Infeasible case is reached
        push!(metrics.scores,last(metrics.scores))
    end
    return last(metrics.timeneeded),last(metrics.meanNodeVisitedUntilEnd), sum(map(!isnothing,last(metrics.scores)))
end
"""
    function computemean!(metrics::BasicMetrics{O, H}) where{O, H<:ValueSelection}

At the end of an experiment, as the instances generated by the generator could be slightly different 
(depending on the distribution of the generator), a moving average is applied on the vectors containing : 
1) number of node visited by the heuristic to find a first solution along the training. 
2) number of node visited by the heuristic to prove to optimality along the training. 

this averaging smoothes the high frequency variations due to the differences between CPModel instances. 
"""
function computemean!(metrics::BasicMetrics{O, H}) where {O, H<:ValueSelection} 
    windowspan = min(metrics.meanOver,length(metrics.meanNodeVisitedUntilfirstSolFound))
    nodeVisitedUntilFirstSolFound = copy(metrics.meanNodeVisitedUntilfirstSolFound)
    metrics.meanNodeVisitedUntilfirstSolFound = rollmean(nodeVisitedUntilFirstSolFound, windowspan)
    nodeVisitedUntilOptimality = copy(metrics.meanNodeVisitedUntilEnd)
    metrics.meanNodeVisitedUntilEnd = rollmean(nodeVisitedUntilOptimality, windowspan)

    if isa(metrics,BasicMetrics{O,<:LearnedHeuristic})
        metrics.totalReward = rollmean(metrics.totalReward,windowspan)
    end
    return
end


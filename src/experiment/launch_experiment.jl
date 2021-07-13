using ProgressBars

"""
    launch_experiment!(;
        ValueSelectionArray::Array{ValueSelection, 1}, 
        problem_type::Symbol=:coloring,
        problem_params::Dict=coloring_params,
        nbEpisodes::Int64=10,
        strategy::Type{DFSearch}=DFSearch,
        variableHeuristic=selectVariable
)

This functions launch an amount of nbEpisodes problems solving. The problems are created by
the given generator. The strategy used during the CP Search and the variable heuristic used can 
be precised as well. To finish with, the value selection heuristic (eather learned or basic) are 
given to function. Each problem generated will be solved once by every value selection heuristic
given, making it possible to compare them.

All the results of consecutive search during the training is stocked in metricsArray containing a metrics 
for each heuristic (eather learned or basic).  

It is also possible to give an evaluator to compare the evolution of performance of the heuristic on same instances along the search. 

This function is called by `train!` and by `benchmark_solving!`.

Every "evalFreq" episodes, all heuristic are evaluated ( weights are no longer updated during the evaluation).
"""
function launch_experiment!(
        valueSelectionArray::Array{T, 1}, 
        generator::AbstractModelGenerator,
        nbEpisodes::Int64,
        strategy::S,
        variableHeuristic::AbstractVariableSelection,
        out_solver::Bool,
        verbose::Bool;
        metrics::Union{Nothing, AbstractMetrics}=nothing,
        evaluator::Union{Nothing, AbstractEvaluator}=SameInstancesEvaluator(valueSelectionArray,generator),
        restartPerInstances = 1,
    ) where{T <: ValueSelection, S <: SearchStrategy}

    nbHeuristics = length(valueSelectionArray)

     #get the type of CPmodel ( does it contains an objective )
    trailer = Trailer()
    model = CPModel(trailer)
    fill_with_generator!(model, generator) 
    metricsArray=AbstractMetrics[]
    for j in 1:nbHeuristics
        if !isnothing(metrics)
            push!(metricsArray,metrics(model,valueSelectionArray[j]))
        else
            push!(metricsArray,BasicMetrics(model,valueSelectionArray[j]))
        end
    end 

    iter = ProgressBar(1:nbEpisodes)
    for i in iter
    #for i in 1:nbEpisodes
        verbose && print(" --- EPISODE: ", i)

        empty!(model)

        fill_with_generator!(model, generator)

        for j in 1:nbHeuristics
            reset_model!(model)
            dt = @elapsed for k in 1:restartPerInstances
                restart_search!(model)
                search!(model, strategy, variableHeuristic, valueSelectionArray[j], out_solver=out_solver)

                if isa(valueSelectionArray[j], LearnedHeuristic)
                    verbose && println(", Visited nodes with learnedHeuristic : ", model.statistics.numberOfNodesBeforeRestart)
                else
                    verbose && println(" vs Visited nodes with basic Heuristic n°$(j-1) : ", model.statistics.numberOfNodesBeforeRestart)
                end
            end
            metricsArray[j](model,dt)  #adding results in the metrics data structure

        end

        if !isnothing(evaluator) && (i % evaluator.evalFreq == 0)
            evaluate(evaluator, variableHeuristic, strategy; verbose = verbose)
        end
        verbose && println()
    end
    
    if !isnothing(evaluator)
        return metricsArray, evaluator.metrics

    end
    return metricsArray,[]
end

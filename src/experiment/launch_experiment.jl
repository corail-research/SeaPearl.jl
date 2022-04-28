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
    valueSelectionArray::Array{T,1},
    generator::AbstractModelGenerator,
    nbEpisodes::Int64,
    strategy::S1,
    eval_strategy::S2,
    variableHeuristic::AbstractVariableSelection,
    out_solver::Bool,
    verbose::Bool;
    metrics::Union{Nothing,AbstractMetrics}=nothing,
    evaluator::Union{Nothing,AbstractEvaluator}=SameInstancesEvaluator(valueSelectionArray, generator),
    restartPerInstances::Int64
) where {T<:ValueSelection,S1,S2<:SearchStrategy}

    nbHeuristics = length(valueSelectionArray)

    #get the type of CPmodel ( does it contains an objective )
    trailer = Trailer()
    model = CPModel(trailer)
    fill_with_generator!(model, generator)
    metricsArray = AbstractMetrics[]
    for j in 1:nbHeuristics
        if !isnothing(metrics)
            push!(metricsArray, metrics(model, valueSelectionArray[j]))
        else
            push!(metricsArray, BasicMetrics(model, valueSelectionArray[j]))
        end
    end

    iter = ProgressBar(1:nbEpisodes)
    for i in iter
        #for i in 1:nbEpisodes
        verbose && println(" --- EPISODE: ", i)

        empty!(model)

        fill_with_generator!(model, generator)

        for j in 1:nbHeuristics
            reset_model!(model)

            # Before the merge with master, this piece of code will have to be internalized in SupervisedSearchHeuristic.
            if isa(valueSelectionArray[j], SupervisedLearnedHeuristic)
                verbose && print("Start searching for a solution for SupervisedLearnedHeuristic... ")
                search!(model, strategy, valueSelectionArray[j].helpVariableHeuristic, valueSelectionArray[j].helpValueHeuristic)
                verbose && println("Search completed.")
                if !isnothing(model.statistics.solutions)
                    solutions = model.statistics.solutions[model.statistics.solutions.!=nothing]
                    if length(solutions) >= 1
                        valueSelectionArray[j].solution = solutions[1]
                    end
                end
                reset_model!(model)
            end
            
            if isa(valueSelectionArray[j], LearnedHeuristic)
                verbose && print("Visited nodes with learnedHeuristic : ")
            else
                verbose && print("Visited nodes with basic Heuristic n°$(j-1) : ")
            end
            dt = @elapsed for k in 1:restartPerInstances
                restart_search!(model)
                search!(model, strategy, variableHeuristic, valueSelectionArray[j], out_solver=out_solver)

                verbose && print(model.statistics.numberOfNodesBeforeRestart, ", ")
            end
            metricsArray[j](model, dt)  #adding results in the metrics data structure
            verbose && println()
        end

        if !isnothing(evaluator) && (i % evaluator.evalFreq == 0)
            evaluate(evaluator, variableHeuristic, eval_strategy; verbose=verbose)
        end
        verbose && println()
    end

    if !isnothing(evaluator)
        return metricsArray, evaluator.metrics

    end
    return metricsArray, []
end

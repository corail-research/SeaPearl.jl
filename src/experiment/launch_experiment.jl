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
        strategy::S1,
        eval_strategy::S2,
        variableHeuristic::AbstractVariableSelection,
        out_solver::Bool,
        verbose::Bool;
        metrics::Union{Nothing, AbstractMetrics}=nothing,
        evaluator::Union{Nothing, AbstractEvaluator}=SameInstancesEvaluator(valueSelectionArray,generator),
        restartPerInstances::Int64,
        rngTraining::AbstractRNG,
        training_timeout =nothing::Union{Nothing, Int},
        eval_every =nothing::Union{Nothing, Int},
    ) where{T <: ValueSelection, S1,S2 <: SearchStrategy}


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

    empty!(model)
    fill_with_generator!(model, generator)
    #false evaluation used to compile the evaluate function that was previously compiled during first "true" evaluation virtually distorting 1st eval computing time
    if !isnothing(evaluator) 
        evaluate(evaluator, variableHeuristic, eval_strategy; verbose = verbose)
        empty!(evaluator)
    end
    start_time, train_time = time_ns(), time_ns()
    eval_time, eval_start, eval_end, j = 0, 0, 0, 0
    iter = ProgressBar(1:nbEpisodes)
    for i in iter
        #for i in 1:nbEpisodes
        verbose && println(" --- EPISODE: ", i)

        empty!(model)
        fill_with_generator!(model, generator; rng = rngTraining)
        
        for j in 1:nbHeuristics
            reset_model!(model)
            if isa(valueSelectionArray[j], LearnedHeuristic)
                verbose && print("Visited nodes with learnedHeuristic ",j," : " )
                println(ReinforcementLearningCore.get_ϵ(valueSelectionArray[j].agent.policy.explorer))

                dt = @elapsed for k in 1:restartPerInstances
                    restart_search!(model)
                    search!(model, strategy, variableHeuristic, valueSelectionArray[j], out_solver=out_solver)
                    verbose && print(model.statistics.numberOfNodesBeforeRestart, ": ",model.statistics.numberOfSolutions, "(",model.statistics.AccumulatedRewardBeforeRestart,") / ")
                end 
                metricsArray[j](model,dt)  #adding results in the metrics data structure
                verbose && println()
            end
        end

        if !isnothing(evaluator)
            if isnothing(eval_every) && (i % evaluator.evalFreq == 1)
                eval_start = time_ns()
                evaluate(evaluator, variableHeuristic, eval_strategy; verbose = verbose)
                eval_end = time_ns()
                eval_time += eval_end - eval_start
            elseif !isnothing(eval_every) && (train_time - start_time)/1.0e9 > eval_every*j
                j +=1
                eval_start = time_ns()
                evaluate(evaluator, variableHeuristic, eval_strategy; verbose = verbose)
                eval_end = time_ns()
                eval_time += eval_end - eval_start
            end
        else 
            eval_time = 0
        end
        train_time = time_ns() - eval_time
        verbose && println()
        !isnothing(training_timeout) && (train_time - start_time)/1.0e9 > training_timeout && break
    end

    if !isnothing(evaluator)
        evaluate(evaluator, variableHeuristic, eval_strategy; verbose = verbose)

        return metricsArray, evaluator.metrics
    end
    
    return metricsArray, []
end

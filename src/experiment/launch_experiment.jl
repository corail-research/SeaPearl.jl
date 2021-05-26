
"""
    launch_experiment!(;
        ValueSelectionArray::Array{ValueSelection, 1}, 
        problem_type::Symbol=:coloring,
        problem_params::Dict=coloring_params,
        nb_episodes::Int64=10,
        strategy::Type{DFSearch}=DFSearch,
        variableHeuristic=selectVariable
)

This functions launch an amount of nb_episodes problems solving. The problems are created by
the given generator. The strategy used during the CP Search and the variable heuristic used can 
be precised as well. To finish with, the value selection heuristic (eather learned or basic) are 
given to function. Each problem generated will be solved once by every value selection heuristic
given, making it possible to compare them.

This function is called by `train!` and by `benchmark_solving!`.

Every "eval_freq" episodes, all heuristic are evaluated ( weights are no longer updated during the evaluation).
"""
function launch_experiment!(
        valueSelectionArray::Array{T, 1}, 
        generator::AbstractModelGenerator,
        nb_episodes::Int64,
        strategy::Type{DFSearch},
        variableHeuristic::AbstractVariableSelection,
        out_solver::Bool,
        verbose::Bool;
        evaluator::Union{Nothing, AbstractEvaluator}=SameInstancesEvaluator(valueSelectionArray,generator)
    ) where T <: ValueSelection

    nb_heuristics = length(valueSelectionArray)

    trailer = Trailer()
    model = CPModel(trailer)

    fill_with_generator!(model, generator)  #get the type of CPmodel ( does it contains an objective )
    metricsArray=[]
    for j in 1:nb_heuristics
        push!(metricsArray,basicmetrics(model,valueSelectionArray[j]))
    end 

    iter = ProgressBar(1:nb_episodes)
    for i in iter
    #for i in 1:nb_episodes
        verbose && print(" --- EPISODE: ", i)

        empty!(model)

        fill_with_generator!(model, generator)

        for j in 1:nb_heuristics
            reset_model!(model)
            
            dt = @elapsed search!(model, strategy, variableHeuristic, valueSelectionArray[j], out_solver=out_solver)
            metricsArray[j](model,dt)  #filling metrics

            if isa(valueSelectionArray[j], LearnedHeuristic)
                verbose && print(", Visited nodes with learnedHeuristic : ", model.statistics.numberOfNodes)
            else
                verbose && println(" vs Visited nodes with basic Heuristic n°$(j-1) : ", model.statistics.numberOfNodes)
            end
        end

        if !isnothing(evaluator) && (i % evaluator.eval_freq == 0)
            evaluate(evaluator, variableHeuristic, strategy)
        end
        verbose && println()
    end
    for j in 1:nb_heuristics
        #compute slidding mean for each metrics
        computemean!(metricsArray[j])  
    end
    
    if !isnothing(evaluator)
        return metricsArray, evaluator.metrics

    end
    return metricsArray,[]
end

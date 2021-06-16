
"""
    benchmark_solving!(;
        valueSelectionArray::Union{T, Array{T, 1}},
        generator::AbstractModelGenerator,
        nbEpisodes::Int64=10,
        strategy::Type{DFSearch}=DFSearch,
        variableHeuristic=selectVariable,
        metricsFun,
        verbose::Bool=true
    ) where T <: ValueSelection

Used to benchmark the performance of some heuristics. It basically put all the LearnedHeuristics in test mode, which
means that the weights of the approximators are no more updated. Consequently, it's also possible to measure a good 
aproximation of the time performances. 

This function might evolve for a more precise one which will provide better analysis of the performances.
"""
function benchmark_solving(;
        valueSelectionArray::Union{T, Array{T, 1}}, 
        generator::AbstractModelGenerator,
        strategy::S=DFSearch,
        variableHeuristic::AbstractVariableSelection=MinDomainVariableSelection(),
        out_solver::Bool=false, 
        metricsFun=((;kwargs...) -> nothing),
        verbose::Bool=true,
        evaluator::Union{Nothing, AbstractEvaluator}
    ) where{T <: ValueSelection,S <: SearchStrategy}
    println("Benchmarking...")
    if isa(valueSelectionArray, T)
        valueSelectionArray = [valueSelectionArray]
    end

    for valueSelection in valueSelectionArray
        # give information to the learned heuristic
        if isa(valueSelection, LearnedHeuristic)
            if valueSelection.fitted_problem != typeof(generator)
                @warn "This learned heuristic was trained on a different problem type."
            end

            if valueSelection.fitted_strategy != typeof(strategy)
                @warn "This learned heuristic was trained with a different search strategy."
            end

            # make sure it is in testing mode
            testmode!(valueSelection, true)
        end
    end

    nbHeuristics = length(valueSelectionArray)
    nbInstances = evaluator.nbInstances

    if isnothing(evaluator)
        evaluator=SameInstancesEvaluator(valueSelectionArray, generator)
    end
    evaluate(evaluator, variableHeuristic, strategy)


    return evaluator.metrics
end

"""
    benchmark_solving!(;
        learnedHeuristic::Union{T, Array{T, 1}}, 
        generator::AbstractModelGenerator,
        nb_episodes::Int64=10,
        strategy::Type{DFSearch}=DFSearch,
        variableHeuristic=selectVariable,
        metricsFun,
        verbose::Bool=true
    ) where T <: ValueSelection

Training a LearnedHeuristic. Could perfectly work with basic heuristic. (even if 
prevented at the moment).
We could rename it experiment and add a train::Bool argument.
"""
function benchmark_solving(;
        valueSelectionArray::Union{T, Array{T, 1}}, 
        generator::AbstractModelGenerator,
        nb_episodes::Int64=10,
        strategy::Type{DFSearch}=DFSearch,
        variableHeuristic::AbstractVariableSelection=MinDomainVariableSelection(),
        metricsFun=((;kwargs...) -> nothing),
        verbose::Bool=true
    ) where T <: ValueSelection

    if isa(valueSelectionArray, T)
        valueSelectionArray = [valueSelectionArray]
    end

    for valueSelection in valueSelectionArray
        # give information to the learned heuristic
        if isa(valueSelection, LearnedHeuristic)
            if valueSelection.fitted_problem != typeof(generator)
                @warn "This learned heuristic was trained on a different problem type."
            end

            if valueSelection.fitted_strategy != strategy
                @warn "This learned heuristic was trained with a different search strategy."
            end

            # make sure it is in testing mode
            testmode!(valueSelection, true)
        end
    end

    # launch the experiment
    bestsolutions, nodevisited, timeneeded = launch_experiment!(
        valueSelectionArray, 
        generator, 
        nb_episodes, 
        strategy, 
        variableHeuristic, 
        metricsFun, 
        verbose
    )

    bestsolutions, nodevisited, timeneeded
end
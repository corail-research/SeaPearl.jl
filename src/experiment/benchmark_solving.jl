
"""
    benchmark_solving!(;
        learnedHeuristic::LearnedHeuristic, 
        problem_type::Symbol=:coloring,
        problem_params::Dict=coloring_params,
        nb_episodes::Int64=10,
        strategy::Type{DFSearch}=DFSearch,
        variableHeuristic=selectVariable,
        metricsFun,
        verbose::Bool=true
    )

Training a LearnedHeuristic. Could perfectly work with basic heuristic. (even if 
prevented at the moment).
We could rename it experiment and add a train::Bool argument.
"""
function benchmark_solving(;
        valueSelection::ValueSelection, 
        problem_type::Symbol=:coloring,
        problem_params::Dict=coloring_params,
        nb_episodes::Int64=10,
        strategy::Type{DFSearch}=DFSearch,
        variableHeuristic=selectVariable,
        metricsFun=((;kwargs...) -> nothing),
        verbose::Bool=true
    )
    # give information to the learned heuristic
    if isa(valueSelection, LearnedHeuristic)
        if valueSelection.fitted_problem != problem_type
            @warn "This learned heuristic was trained on a different problem type."
        end

        if valueSelection.fitted_strategy != strategy
            @warn "This learned heuristic was trained with a different search strategy."
        end

        # make sure it is in testing mode
        testmode!(valueSelection, true)
    end

    # launch the experiment
    bestsolutions, nodevisited = launch_experiment!(
        valueSelection, 
        problem_type, 
        problem_params, 
        nb_episodes, 
        strategy, 
        variableHeuristic, 
        metricsFun, 
        verbose
    )

    bestsolutions, nodevisited
end
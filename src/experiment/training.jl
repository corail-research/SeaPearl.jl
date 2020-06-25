problem_generator = Dict(
    :coloring => fill_with_coloring!,
    :filecoloring => CPRL.fill_with_coloring_file!
)

coloring_params = Dict(
    "nb_nodes" => 10,
    "density" => 1.5
)

"""
    train!(;
        ValueSelectionArray::Array{ValueSelection, 1}, 
        problem_type::Symbol=:coloring,
        problem_params::Dict=coloring_params,
        nb_episodes::Int64=10,
        strategy::Type{DFSearch}=DFSearch,
        variableHeuristic=selectVariable
)

Same but with multiple ValueSelection instances (accepts BasicHeuristics)
We could rename it experiment and add a train::Bool argument.

Call it multitrain because I am having an overwritting error with the simple one 
and I would like to keep both atm.
"""
function train!(;
        valueSelectionArray::Union{T, Array{T, 1}}, 
        problem_type::Symbol=:coloring,
        problem_params::Dict=coloring_params,
        nb_episodes::Int64=10,
        strategy::Type{DFSearch}=DFSearch,
        variableHeuristic=selectVariable,
        metricsFun=((;kwargs...) -> nothing),
        verbose::Bool=true
    ) where T <: ValueSelection

    if isa(valueSelectionArray, T)
        valueSelectionArray = [valueSelectionArray]
    end

    for valueSelection in valueSelectionArray
        if isa(valueSelection, LearnedHeuristic)
            valueSelection.fitted_problem = problem_type
            valueSelection.fitted_strategy = strategy
            # we could add more information later ...

            # make sure it is in training mode
            testmode!(valueSelection, false)
        end
    end

    bestsolutions, nodevisited, timeneeded = launch_experiment!(
        valueSelectionArray,
        problem_type,
        problem_params,
        nb_episodes,
        strategy,
        variableHeuristic,
        metricsFun, 
        verbose
    )

    for valueSelection in valueSelectionArray
        if isa(valueSelection, LearnedHeuristic)
            # go to testing mode 
            testmode!(valueSelection)

            if verbose 
                print("Has been trained on : ", problem_type)
                print(" ... with strategy : ", strategy)
                println("During ", nb_episodes, " episodes.")
                println("Training mode now desactivated !")
            end
        end
    end

    bestsolutions, nodevisited, timeneeded
end

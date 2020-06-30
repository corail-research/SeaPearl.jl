problem_generator = Dict(
    :coloring => (models, params) -> fill_with_coloring!(models, params["nb_nodes"], params["density"]),
    :filecoloring => (models, params) -> fill_with_coloring_file!(models, params["nb_nodes"], params["density"]),
    :knapsack => (models, params) -> fill_with_knapsack!(models, params["nb_items"], params["noise"])
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

Launch a training on several ValueSelection instances to get the different results on the same probem instances.
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
                println(" ... during ", nb_episodes, " episodes.")
                println("Training mode now desactivated !")
            end
        end
    end

    bestsolutions, nodevisited, timeneeded
end

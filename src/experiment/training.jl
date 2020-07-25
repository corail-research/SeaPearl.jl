"""
    train!(;
        ValueSelectionArray::Array{ValueSelection, 1}, 
        generator::AbstractModelGenerator,
        nb_episodes::Int64=10,
        strategy::Type{DFSearch}=DFSearch,
        variableHeuristic=selectVariable)
)

Launch a training on several ValueSelection instances to get the different results on the same probem instances.
"""
function train!(;
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
        if isa(valueSelection, LearnedHeuristic)
            valueSelection.fitted_problem = typeof(generator)
            valueSelection.fitted_strategy = strategy
            # we could add more information later ...

            # make sure it is in training mode
            testmode!(valueSelection, false)
        end
    end

    bestsolutions, nodevisited, timeneeded, eval_nodevisited, eval_timeneeded = launch_experiment!(
        valueSelectionArray,
        generator,
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
                print("Has been trained on : ", typeof(generator))
                print(" ... with strategy : ", strategy)
                println(" ... during ", nb_episodes, " episodes.")
                println("Training mode now desactivated !")
            end
        end
    end

    bestsolutions, nodevisited, timeneeded, eval_nodevisited, eval_timeneeded
end

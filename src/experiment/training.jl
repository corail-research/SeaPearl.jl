"""
    train!(;
        ValueSelectionArray::Array{ValueSelection, 1}, 
        generator::AbstractModelGenerator,
        nb_episodes::Int64=10,
        strategy::Type{DFSearch}=DFSearch,
        variableHeuristic=selectVariable)
)

Training the given LearnedHeuristics and using the Basic One to compare performances. Might evolve soon.
This function managed the training mode of the LEarnedHeuristic before and after a call to `launch_experiment!`.
"""
function train!(;
        valueSelectionArray::Union{T, Array{T, 1}}, 
        generator::AbstractModelGenerator,
        nb_episodes::Int64=10,
        strategy::Type{DFSearch}=DFSearch,
        variableHeuristic::AbstractVariableSelection=MinDomainVariableSelection(),
        metricsFun=((;kwargs...) -> nothing),
        verbose::Bool=true,
        evaluator=SameInstancesEvaluator()
    ) where T <: AbstractValueSelection

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
        verbose;
        evaluator=SameInstancesEvaluator()
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

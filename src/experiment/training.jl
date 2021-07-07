"""
    train!(;
        valueSelectionArray::Union{T, Array{T, 1}}, 
        generator::AbstractModelGenerator,
        nbEpisodes::Int64=10,
        strategy::S=DFSearch(),
        variableHeuristic::AbstractVariableSelection=MinDomainVariableSelection(),
        out_solver::Bool=false,
        verbose::Bool=true,
        evaluator::Union{Nothing, AbstractEvaluator},
        metrics::Union{Nothing,AbstractMetrics}=nothing
    ) where{ T <: ValueSelection, S <: SearchStrategy}

Training the given LearnedHeuristics and using the Basic ones to compare performances. 
This function managed the training mode of the LearnedHeuristic before and after a call to `launch_experiment!`.

The function return arrays containing scores, time needed and numbers of nodes visited on each episode for every heuristic
(basic and learned heuristics)
"""
function train!(;
        valueSelectionArray::Union{T, Array{T, 1}}, 
        generator::AbstractModelGenerator,
        nbEpisodes::Int64=10,
        strategy::S=DFSearch(),
        variableHeuristic::AbstractVariableSelection=MinDomainVariableSelection(),
        out_solver::Bool=false,
        verbose::Bool=true,
        evaluator::Union{Nothing, AbstractEvaluator},
        metrics::Union{Nothing,AbstractMetrics}=nothing, 
        restartPerInstances = 1,
    ) where{ T <: ValueSelection, S <: SearchStrategy}

    if isa(valueSelectionArray, T)
        valueSelectionArray = [valueSelectionArray]
    end

    for valueSelection in valueSelectionArray
        if isa(valueSelection, LearnedHeuristic)
            valueSelection.fitted_problem = typeof(generator)
            valueSelection.fitted_strategy = typeof(strategy)
            # we could add more information later ...

            # make sure it is in training mode
            testmode!(valueSelection, false)
        end
    end

    metricsArray, eval_metricsArray = launch_experiment!(
        valueSelectionArray,
        generator,
        nbEpisodes,
        strategy,
        variableHeuristic,
        out_solver,
        verbose;
        metrics=metrics,
        evaluator=evaluator,
        restartPerInstances,
    )

    for valueSelection in valueSelectionArray
        if isa(valueSelection, LearnedHeuristic)
            # go to testing mode 
            testmode!(valueSelection)

            if verbose 
                print("Has been trained on : ", typeof(generator))
                print(" with strategy : ", strategy)
                print(" during ", nbEpisodes, " episodes ")
                out_solver && println("out of the solver.")
                !out_solver && println("in the solver.")
                println("Training mode now desactivated !")
            end
        end
    end

    return metricsArray, eval_metricsArray
end

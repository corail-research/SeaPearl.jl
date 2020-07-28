
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
"""
function launch_experiment!(
        valueSelectionArray::Array{T, 1}, 
        generator::AbstractModelGenerator,
        nb_episodes::Int64,
        strategy::Type{DFSearch},
        variableHeuristic::AbstractVariableSelection,
        metricsFun,
        verbose::Bool
    ) where T <: ValueSelection

    evaluator = SameInstancesEvaluator()
    eval_freq = evaluator.eval_freq

    nb_heuristics = length(valueSelectionArray)

    init_evaluator!(evaluator, generator)

    bestsolutions = zeros(Int64, (nb_episodes, nb_heuristics))
    nodevisited = zeros(Int64, (nb_episodes, nb_heuristics))
    eval_nodevisited = zeros(Float64, (floor(Int64, nb_episodes/eval_freq) + 1, nb_heuristics))
    timeneeded = zeros(Float64, (nb_episodes, nb_heuristics))
    eval_timeneeded = zeros(Float64, (floor(Int64, nb_episodes/eval_freq) + 1, nb_heuristics))

    trailer = Trailer()
    model = CPModel(trailer)

    iter = ProgressBar(1:nb_episodes)
    for i in iter
    #for i in 1:nb_episodes
        verbose && print(" --- EPISODE: ", i)

        empty!(model)

        fill_with_generator!(model, generator)


        for j in 1:nb_heuristics
            reset_model!(model)
            
            dt = @elapsed search!(model, strategy, variableHeuristic, valueSelectionArray[j])

            if isa(valueSelectionArray[j], LearnedHeuristic)
                verbose && print(", Visited nodes: ", model.statistics.numberOfNodes)
            else
                verbose && print(" vs ", model.statistics.numberOfNodes)
            end

            bestsolutions[i, j] = model.objectiveBound + 1
            nodevisited[i, j] = model.statistics.numberOfNodes

            if j == 2
                set_postfix(iter, Delta=string(nodevisited[i, 1] - nodevisited[i, 2]))
            end

            # eval_nodevisited[i, j], eval_timeneeded[i, j] = 0., 0.
            if i % eval_freq == 1
                eval_nodevisited[floor(Int64, (i-1)/eval_freq + 1), j], eval_timeneeded[floor(Int64, (i-1)/eval_freq + 1), j] = evaluate(evaluator, variableHeuristic, valueSelectionArray[j], strategy)
            end

            timeneeded[i, j] = dt
            metricsFun(;episode=i, heuristic=valueSelectionArray[j], nodeVisited=model.statistics.numberOfNodes, bestSolution=(model.objectiveBound + 1))
        end
        verbose && println()

    end

    bestsolutions, nodevisited, timeneeded, eval_nodevisited, eval_timeneeded
end

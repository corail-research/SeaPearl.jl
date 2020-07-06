
"""
    launch_experiment!(;
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
function launch_experiment!(
        valueSelectionArray::Array{T, 1}, 
        problem_type::Symbol,
        problem_params::Dict,
        nb_episodes::Int64,
        strategy::Type{DFSearch},
        variableHeuristic,
        metricsFun,
        verbose::Bool
    ) where T <: ValueSelection

    nb_heuristics = length(valueSelectionArray)

    fill_with_generator! = problem_generator[problem_type]

    bestsolutions = zeros(Int64, (nb_episodes, nb_heuristics))
    nodevisited = zeros(Int64, (nb_episodes, nb_heuristics))
    timeneeded = zeros(Float64, (nb_episodes, nb_heuristics))

    trailer = Trailer()
    model = CPModel(trailer)

    iter = ProgressBar(1:nb_episodes)
    for i in iter
    # for i in 1:nb_episodes
        verbose && print(" --- EPISODE: ", i)

        empty!(model)

        fill_with_generator!(model, problem_params["nb_nodes"], problem_params["density"])

        models = [deepcopy(model) for _ in 1:nb_heuristics]

        for j in 1:nb_heuristics
            dt = @elapsed search!(models[j], strategy, variableHeuristic, valueSelectionArray[j])
            if isa(valueSelectionArray[j], LearnedHeuristic)
                verbose && print(", Visited nodes: ", models[j].statistics.numberOfNodes)
            else
                verbose && print(" vs ", models[j].statistics.numberOfNodes)
            end

            if j == 2
                set_postfix(iter, Delta=string(models[1].statistics.numberOfNodes - models[2].statistics.numberOfNodes))
            end
            bestsolutions[i, j] = models[j].objectiveBound + 1
            nodevisited[i, j] = models[j].statistics.numberOfNodes
            timeneeded[i, j] = dt
            metricsFun(;episode=i, heuristic=valueSelectionArray[j], nodeVisited=models[j].statistics.numberOfNodes, bestSolution=(models[j].objectiveBound + 1))
        end
        verbose && println()

    end

    bestsolutions, nodevisited, timeneeded
end

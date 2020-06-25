

"""
    launch_experiment!()

Launch nb_episodes experiments.
"""
function launch_experiment!(
        valueSelection::ValueSelection, 
        problem_type::Symbol,
        problem_params::Dict,
        nb_episodes::Int64,
        strategy::Type{DFSearch},
        variableHeuristic,
        metricsFun,
        verbose::Bool
    )

    trailer = Trailer()
    model = CPModel(trailer)

    fill_with_generator! = problem_generator[problem_type]

    bestsolutions = []
    nodevisited = []

    verbose && println(" -------------- START EXPERIMENTING : -------------- ")

    for i in ProgressBar(1:nb_episodes)
        #verbose && print(" --- EPISODE : ", i)

        trailer = Trailer()
        model = CPModel(trailer)

        fill_with_generator!(model, problem_params["nb_nodes"], problem_params["density"])

        search!(model, strategy, variableHeuristic, valueSelection)

        push!(bestsolutions, model.objectiveBound + 1)
        push!(nodevisited, model.statistics.numberOfNodes)
        metricsFun(;nodeVisited=model.statistics.numberOfNodes, bestSolution=(model.objectiveBound + 1))
        #verbose && println(", Visited nodes: ", model.statistics.numberOfNodes)
    end

    bestsolutions, nodevisited
end
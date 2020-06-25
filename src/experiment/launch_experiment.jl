

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




"""
    multi_train!(;
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
function multi_experiment!(
        ValueSelectionArray::Union{T, Array{T, 1}}, 
        problem_type::Symbol,
        problem_params::Dict,
        nb_episodes::Int64,
        strategy::Type{DFSearch},
        variableHeuristic,
        metricsFun,
        verbose::Bool
    ) where T <: ValueSelection

    if isa(ValueSelectionArray, T)
        ValueSelectionArray = [ValueSelectionArray]
    end

    nb_heuristics = length(ValueSelectionArray)

    fill_with_generator! = problem_generator[problem_type]

    bestsolutions = zeros(Int64, (nb_episodes, nb_heuristics))
    nodevisited = zeros(Int64, (nb_episodes, nb_heuristics))

    verbose && println(" -------------- START TRAINING : -------------- ")

    for i in 1:nb_episodes
        verbose && print(" --- EPISODE: ", i)

        trailer = Trailer()
        model = CPModel(trailer)

        fill_with_generator!(model, problem_params["nb_nodes"], problem_params["density"])

        models = [deepcopy(model) for _ in 1:nb_heuristics]

        for j in 1:nb_heuristics
            search!(models[j], strategy, variableHeuristic, ValueSelectionArray[j])
            if isa(ValueSelectionArray[j], LearnedHeuristic)
                print(", Visited nodes: ", models[j].statistics.numberOfNodes)
            else
                print(" vs ", models[j].statistics.numberOfNodes)
            end


            bestsolutions[i, j] = models[j].objectiveBound + 1
            nodevisited[i, j] = models[j].statistics.numberOfNodes
            metricsFun(;episode=i, heuristic=ValueSelectionArray[j], nodeVisited=models[j].statistics.numberOfNodes, bestSolution=(models[j].objectiveBound + 1))
        end
        println()

    end

    bestsolutions, nodevisited
end

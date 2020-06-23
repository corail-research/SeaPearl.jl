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
        learnedHeuristic::LearnedHeuristic, 
        problem_type::Symbol=:coloring,
        problem_params::Dict=coloring_params,
        nb_episodes::Int64=10,
        strategy::Type{DFSearch}=DFSearch,
        variableHeuristic=selectVariable
)

Training a LearnedHeuristic. Could perfectly work with basic heuristic. (even if 
prevented at the moment).
We could rename it experiment and add a train::Bool argument.
"""
function train!(;
        learnedHeuristic::LearnedHeuristic, 
        problem_type::Symbol=:coloring,
        problem_params::Dict=coloring_params,
        nb_episodes::Int64=10,
        strategy::Type{DFSearch}=DFSearch,
        variableHeuristic=selectVariable
    )
    learnedHeuristic.fitted_problem = :coloring
    learnedHeuristic.fitted_strategy = strategy
    # we could add more information later ...

    trailer = Trailer()
    model = CPModel(trailer)

    fill_with_generator! = problem_generator[problem_type]

    bestsolutions = []
    nodevisited = []

    println(" -------------- START TRAINING : -------------- ")

    for i in 1:nb_episodes
        println(" --- EPISODE : ", i)

        empty!(model)

        fill_with_generator!(model, problem_params["nb_nodes"], problem_params["density"])

        search!(model, strategy, variableHeuristic, learnedHeuristic)

        push!(bestsolutions, model.objectiveBound + 1)
        push!(nodevisited, model.statistics.numberOfNodes)
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
function multi_train!(;
        ValueSelectionArray::Array{T, 1}, 
        problem_type::Symbol=:coloring,
        problem_params::Dict=coloring_params,
        nb_episodes::Int64=10,
        strategy::Type{DFSearch}=DFSearch,
        variableHeuristic=selectVariable
    ) where T <: ValueSelection
    for valueSelection in ValueSelectionArray
        if isa(valueSelection, LearnedHeuristic)
            valueSelection.fitted_problem = problem_type
            valueSelection.fitted_strategy = strategy
            # we could add more information later ...
        end
    end

    nb_heuristics = length(ValueSelectionArray)

    trailer = Trailer()
    model = CPModel(trailer)

    fill_with_generator! = problem_generator[problem_type]

    bestsolutions = zeros(Int64, (nb_episodes, nb_heuristics))
    nodevisited = zeros(Int64, (nb_episodes, nb_heuristics))

    println(" -------------- START TRAINING : -------------- ")

    for i in 1:nb_episodes
        println(" --- EPISODE : ", i)

        empty!(model)

        fill_with_generator!(model, problem_params["nb_nodes"], problem_params["density"])

        models = [deepcopy(model) for _ in 1:nb_heuristics]

        for j in 1:nb_heuristics
            search!(models[j], strategy, variableHeuristic, ValueSelectionArray[j])

            bestsolutions[i, j] = models[j].objectiveBound + 1
            nodevisited[i, j] = models[j].statistics.numberOfNodes
        end

    end

    bestsolutions, nodevisited
end

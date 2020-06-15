problem_generator = Dict(
    :coloring => fill_with_coloring!
)

coloring_params = Dict(
    "nb_nodes" => 10,
    "density" => 1.5
)

"""
    train!()

Training a LearnedHeuristic.
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

    for i in 1:nb_episodes
        isempty(model) || empty!(model)
        fill_with_generator!(model, problem_params["nb_nodes"], problem_params["density"])

        search!(model, strategy, variableHeuristic, learnedHeuristic)

        push!(bestsolutions, model.objectiveBound + 1)
        push!(nodevisited, model.statistics.numberOfNodes)
    end

    bestsolutions, nodevisited
end
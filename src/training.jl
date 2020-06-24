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
        valueSelection::ValueSelection, 
        problem_type::Symbol=:coloring,
        problem_params::Dict=coloring_params,
        nb_episodes::Int64=10,
        strategy::Type{DFSearch}=DFSearch,
        variableHeuristic=selectVariable,
        metricsFun=((;kwargs...) -> nothing)
    )
    if isa(valueSelection, LearnedHeuristic)
        valueSelection.fitted_problem = :coloring
        valueSelection.fitted_strategy = strategy
        # we could add more information later ...
        testmode!(valueSelection, false)
    end
    
    trailer = Trailer()
    model = CPModel(trailer)

    fill_with_generator! = problem_generator[problem_type]

    bestsolutions = []
    nodevisited = []

    println(" -------------- START TRAINING : -------------- ")

    for i in 1:nb_episodes
        print(" --- EPISODE : ", i)

        trailer = Trailer()
        model = CPModel(trailer)

        fill_with_generator!(model, problem_params["nb_nodes"], problem_params["density"])

        search!(model, strategy, variableHeuristic, valueSelection)

        push!(bestsolutions, model.objectiveBound + 1)
        push!(nodevisited, model.statistics.numberOfNodes)
        metricsFun(;nodeVisited=model.statistics.numberOfNodes, bestSolution=(model.objectiveBound + 1))
        println(", Visited nodes: ", model.statistics.numberOfNodes)
    end

    if isa(valueSelection, LearnedHeuristic)
        print("Has been trained on : ", problem_type)
        print(" ... with strategy : ", strategy)
        println("During ", nb_episodes, " episodes.")

        testmode!(valueSelection)
        println("Training mode now desactivated !")
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
        variableHeuristic=selectVariable,
        metricsFun=((;kwargs...) -> nothing)
    ) where T <: ValueSelection

    for valueSelection in ValueSelectionArray
        if isa(valueSelection, LearnedHeuristic)
            valueSelection.fitted_problem = problem_type
            valueSelection.fitted_strategy = strategy
            # we could add more information later ...

            testmode!(valueSelection, false)
        end
    end

    nb_heuristics = length(ValueSelectionArray)

    fill_with_generator! = problem_generator[problem_type]

    bestsolutions = zeros(Int64, (nb_episodes, nb_heuristics))
    nodevisited = zeros(Int64, (nb_episodes, nb_heuristics))

    println(" -------------- START TRAINING : -------------- ")

    for i in 1:nb_episodes
        print(" --- EPISODE: ", i)

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
            metricsFun(;heuristic=ValueSelectionArray[j], nodeVisited=models[j].statistics.numberOfNodes, bestSolution=(models[j].objectiveBound + 1))
        end
        println()

    end

    for valueSelection in ValueSelectionArray
        if isa(valueSelection, LearnedHeuristic)
            testmode!(valueSelection)
        end
    end

    bestsolutions, nodevisited
end

@testset "training.jl" begin
    """
    problem_generator = Dict(
        :coloring => CPRL.fill_with_coloring!
    )

    coloring_params = Dict(
        "nb_nodes" => 10,
        "density" => 1.5
    )


    agent = CPRL.DQNAgent()
    
    learnedHeuristic = CPRL.LearnedHeuristic(agent)

    bestsolutions, nodevisited = CPRL.train!(
        learnedHeuristic, 
        problem_type=:coloring,
        problem_params=coloring_params,
        nb_episodes=10,
        strategy=CPRL.DFSearch,
        variableHeuristic=CPRL.selectVariable
    )
    """

end
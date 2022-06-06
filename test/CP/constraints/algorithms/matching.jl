@testset "matching.jl" begin
    @testset "randomMatching(::Graph{Int}, ::Int)::Matching{Int}" begin
        bipartite = LightGraphs.Graph(10)
        for i = 1:5
            LightGraphs.add_edge!(bipartite, i, i+5)
        end
        matching = SeaPearl.randomMatching(bipartite, 5)
        edgeset = [LightGraphs.Edge(m[1], m[2]) for m in matching.matches]

        @test matching.size == 5
        @test length(intersect(edgeset, LightGraphs.edges(bipartite))) == 5
    end
    @testset "matchingFromDigraph(::LightGraphs.DiGraph{Int}, ::Int)::Matching{Int}" begin
        bipartite = LightGraphs.DiGraph(6)
        LightGraphs.add_edge!(bipartite, 1, 4)
        LightGraphs.add_edge!(bipartite, 5, 1)
        LightGraphs.add_edge!(bipartite, 2, 5)
        LightGraphs.add_edge!(bipartite, 6, 3)
        LightGraphs.add_edge!(bipartite, 6, 2)
        matching = SeaPearl.matchingFromDigraph(bipartite, 3)

        @test matching.size == 2
        @test Pair(1, 4) in matching.matches
        @test Pair(2, 5) in matching.matches
    end
    @testset "augmentMatching!(::LightGraphs.DiGraph, ::Int, ::Vector{Int})" begin
        bipartite = LightGraphs.DiGraph(6)
        LightGraphs.add_edge!(bipartite, 1, 4)
        LightGraphs.add_edge!(bipartite, 5, 1)
        LightGraphs.add_edge!(bipartite, 2, 5)
        LightGraphs.add_edge!(bipartite, 5, 3)
        LightGraphs.add_edge!(bipartite, 6, 2)
        free = Set([3])
        res = SeaPearl.augmentMatching!(bipartite, 6, free)

        @test !isnothing(res)
        @test res == Pair(3, 6)
    end
    @testset "buildDigraph!(::LightGraphs.DiGraph{Int}, ::Graph{Int}, ::Matching{Int})" begin
        graph = LightGraphs.Graph(7)
        digraph = LightGraphs.DiGraph(7)
        LightGraphs.add_edge!(graph, 1, 4)
        LightGraphs.add_edge!(graph, 1, 5)
        LightGraphs.add_edge!(graph, 2, 4)
        LightGraphs.add_edge!(graph, 2, 7)
        LightGraphs.add_edge!(graph, 3, 4)
        LightGraphs.add_edge!(graph, 3, 6)
        LightGraphs.add_edge!(graph, 3, 7)
        matching = SeaPearl.Matching(2, [Pair(1, 4), Pair(2, 7)])
        SeaPearl.buildDigraph!(digraph, graph, matching)

        @test LightGraphs.Edge(1, 4) in LightGraphs.edges(digraph)
        @test LightGraphs.Edge(5, 1) in LightGraphs.edges(digraph)
        @test LightGraphs.Edge(4, 2) in LightGraphs.edges(digraph)
        @test LightGraphs.Edge(2, 7) in LightGraphs.edges(digraph)
        @test LightGraphs.Edge(4, 3) in LightGraphs.edges(digraph)
        @test LightGraphs.Edge(6, 3) in LightGraphs.edges(digraph)
        @test LightGraphs.Edge(7, 3) in LightGraphs.edges(digraph)
    end
    @testset "maximizeMatching!(::LightGraphs.Graph, ::LightGraphs.DiGraph, ::Int)::Matching" begin
    #Replays the example from the paper
        graph = LightGraphs.Graph(12)
        digraph = LightGraphs.DiGraph(12)
        LightGraphs.add_edge!(graph, 1, 7)
        LightGraphs.add_edge!(graph, 1, 8)
        LightGraphs.add_edge!(graph, 2, 8)
        LightGraphs.add_edge!(graph, 2, 9)
        LightGraphs.add_edge!(graph, 3, 9)
        LightGraphs.add_edge!(graph, 4, 8)
        LightGraphs.add_edge!(graph, 4, 10)
        LightGraphs.add_edge!(graph, 5, 9)
        LightGraphs.add_edge!(graph, 5, 10)
        LightGraphs.add_edge!(graph, 5, 11)
        LightGraphs.add_edge!(graph, 5, 12)
        LightGraphs.add_edge!(graph, 6, 12)
        matching = SeaPearl.Matching(3, [Pair(1, 7), Pair(4, 8), Pair(5, 10)])
        SeaPearl.buildDigraph!(digraph, graph, matching)

        SeaPearl.maximizeMatching!(digraph, 6)
        target = [LightGraphs.Edge(1, 7), LightGraphs.Edge(2, 8), LightGraphs.Edge(3, 9), LightGraphs.Edge(4, 10), LightGraphs.Edge(5, 11), LightGraphs.Edge(6, 12)]
        @test all([e in LightGraphs.edges(digraph) for e in target])
        @test all([LightGraphs.outdegree(digraph, v) == 1 for v in 1:6])
    end
    @testset "maximumMatching!(::LightGraphs.Graph{Int}, ::LightGraphs.DiGraph{Int}, ::Int)::Matching{Int}" begin
    # This function and all its dependencies have been tested with an external library
    # Thus the code written at that time is certified to work based on 3000 randomly generated
    # matching cases with optimal matching detection.

    # Warning the testsets aren't as powerful as this external control and in case of a code
    # modification I recommend to run external tests again.

        graph = LightGraphs.Graph(13)
        digraph = LightGraphs.DiGraph(13)
        LightGraphs.add_edge!(graph, 1, 7)
        LightGraphs.add_edge!(graph, 1, 8)
        LightGraphs.add_edge!(graph, 2, 8)
        LightGraphs.add_edge!(graph, 2, 9)
        LightGraphs.add_edge!(graph, 3, 7)
        LightGraphs.add_edge!(graph, 3, 9)
        LightGraphs.add_edge!(graph, 4, 8)
        LightGraphs.add_edge!(graph, 4, 10)
        LightGraphs.add_edge!(graph, 5, 9)
        LightGraphs.add_edge!(graph, 5, 10)
        LightGraphs.add_edge!(graph, 5, 11)
        LightGraphs.add_edge!(graph, 6, 11)
        LightGraphs.add_edge!(graph, 6, 12)
        matching = SeaPearl.maximumMatching!(graph, digraph, 6)

        @test matching.size == 6
        @test all(map(pair -> LightGraphs.Edge(pair[1], pair[2]) in LightGraphs.edges(graph), matching.matches))
        @test all(map(pair -> LightGraphs.Edge(pair[1], pair[2]) in LightGraphs.edges(digraph), matching.matches))
        @test all(map(e -> e in LightGraphs.edges(graph), LightGraphs.edges(digraph)))
        @test LightGraphs.ne(graph) == LightGraphs.ne(digraph)
    end
end
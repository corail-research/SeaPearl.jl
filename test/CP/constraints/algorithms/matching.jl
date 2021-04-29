using LightGraphs

@testset "matching.jl" begin
    @testset "randommatching(::Graph{Int}, ::Int)::Matching{Int}" begin
        bipartite = Graph(10)
        for i = 1:5
            add_edge!(bipartite, i, i+5)
        end
        matching = SeaPearl.randommatching(bipartite, 5)
        edgeset = [Edge(m[1], m[2]) for m in matching.matches]

        @test matching.size == 5
        @test length(intersect(edgeset, edges(bipartite))) == 5
    end
    @testset "matchingfromdigraph(::DiGraph{Int}, ::Int)::Matching{Int}" begin
        bipartite = DiGraph(6)
        add_edge!(bipartite, 1, 4)
        add_edge!(bipartite, 5, 1)
        add_edge!(bipartite, 2, 5)
        add_edge!(bipartite, 6, 3)
        add_edge!(bipartite, 6, 2)
        matching = SeaPearl.matchingfromdigraph(bipartite, 3)

        @test matching.size == 2
        @test Pair(1, 4) in matching.matches
        @test Pair(2, 5) in matching.matches
    end
    @testset "augmentmatching!(::DiGraph, ::Int, ::Int, ::Vector{Int})" begin
        bipartite = DiGraph(6)
        add_edge!(bipartite, 1, 4)
        add_edge!(bipartite, 5, 1)
        add_edge!(bipartite, 2, 5)
        add_edge!(bipartite, 5, 3)
        add_edge!(bipartite, 6, 2)
        free = Set([3])
        res = SeaPearl.augmentmatching!(bipartite, 3, 6, free)

        @test !isnothing(res)
        @test res == Pair(3, 6)
    end
    @testset "builddigraph!(::DiGraph{Int}, ::Graph{Int}, ::Matching{Int})" begin
        graph = Graph(7)
        digraph = DiGraph(7)
        add_edge!(graph, 1, 4)
        add_edge!(graph, 1, 5)
        add_edge!(graph, 2, 4)
        add_edge!(graph, 2, 7)
        add_edge!(graph, 3, 4)
        add_edge!(graph, 3, 6)
        add_edge!(graph, 3, 7)
        matching = SeaPearl.Matching(2, [Pair(1, 4), Pair(2, 7)])
        SeaPearl.builddigraph!(digraph, graph, matching)

        @test Edge(1, 4) in edges(digraph)
        @test Edge(5, 1) in edges(digraph)
        @test Edge(4, 2) in edges(digraph)
        @test Edge(2, 7) in edges(digraph)
        @test Edge(4, 3) in edges(digraph)
        @test Edge(6, 3) in edges(digraph)
        @test Edge(7, 3) in edges(digraph)
    end
    @testset "maximizematching!(::Graph, ::DiGraph, ::Int)::Matching" begin
    #Replays the example from the paper
        graph = Graph(12)
        digraph = DiGraph(12)
        add_edge!(graph, 1, 7)
        add_edge!(graph, 1, 8)
        add_edge!(graph, 2, 8)
        add_edge!(graph, 2, 9)
        add_edge!(graph, 3, 9)
        add_edge!(graph, 4, 8)
        add_edge!(graph, 4, 10)
        add_edge!(graph, 5, 9)
        add_edge!(graph, 5, 10)
        add_edge!(graph, 5, 11)
        add_edge!(graph, 5, 12)
        add_edge!(graph, 6, 12)
        matching = SeaPearl.Matching(3, [Pair(1, 7), Pair(4, 8), Pair(5, 10)])
        SeaPearl.builddigraph!(digraph, graph, matching)

        SeaPearl.maximizematching!(graph, digraph, 6)
        target = [Edge(1, 7), Edge(2, 8), Edge(3, 9), Edge(4, 10), Edge(5, 11), Edge(6, 12)]
        @test all([e in edges(digraph) for e in target])
        @test all([outdegree(digraph, v) == 1 for v in 1:6])
    end
    @testset "maximummatching(::Graph{Int}, ::DiGraph{Int}, ::Int)::Matching{Int}" begin
    # This function and all its dependencies have been tested with an external library
    # Thus the code written at that time is certified to work based on 3000 randomly generated
    # matching cases with optimal matching detection.

    # Warning the testsets aren't as powerful as this external control and in case of a code
    # modification I recommend to run external tests again.

        graph = Graph(13)
        digraph = DiGraph(13)
        add_edge!(graph, 1, 7)
        add_edge!(graph, 1, 8)
        add_edge!(graph, 2, 8)
        add_edge!(graph, 2, 9)
        add_edge!(graph, 3, 7)
        add_edge!(graph, 3, 9)
        add_edge!(graph, 4, 8)
        add_edge!(graph, 4, 10)
        add_edge!(graph, 5, 9)
        add_edge!(graph, 5, 10)
        add_edge!(graph, 5, 11)
        add_edge!(graph, 6, 11)
        add_edge!(graph, 6, 12)
        matching = SeaPearl.maximummatching!(graph, digraph, 6)

        @test matching.size == 6
        @test all(map(pair -> Edge(pair[1], pair[2]) in edges(graph), matching.matches))
        @test all(map(pair -> Edge(pair[1], pair[2]) in edges(digraph), matching.matches))
        @test all(map(e -> e in edges(graph), edges(digraph)))
        @test ne(graph) == ne(digraph)
    end
    @testset "AllDifferent(::Vector{AbstractIntVar}, ::Trailer)" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(1, 3, "x", trailer)
        y = SeaPearl.IntVar(2, 3, "y", trailer)
        z = SeaPearl.IntVar(2, 3, "Z", trailer)
        vec = Vector{SeaPearl.AbstractIntVar}([x, y, z])

        constraint = SeaPearl.AllDifferent(vec, trailer)

        @test constraint.minimum.value == 1
        @test constraint.maximum.value == 3
        @test constraint.active.value
        @test !constraint.initialized.value
        @test constraint.nodesMin == 1
        @test constraint.numberOfVals == 3
        @test constraint in x.onDomainChange
        @test constraint in y.onDomainChange
        @test constraint in z.onDomainChange
    end
end
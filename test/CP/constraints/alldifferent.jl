@testset "alldifferent.jl" begin
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
        free = [3]
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
    @testset "maximummatching(::Graph{Int}, ::DiGraph{Int}, ::Int)::Matching{Int}" begin
        graph = Graph(7)
        digraph = DiGraph(7)
        add_edge!(graph, 1, 5)
        add_edge!(graph, 2, 5)
        add_edge!(graph, 2, 7)
        add_edge!(graph, 3, 5)
        add_edge!(graph, 3, 6)
        add_edge!(graph, 3, 7)
        matching = SeaPearl.maximummatching!(graph, digraph, 3)

        @test matching.size == 3
        @test Pair(1, 5) in matching.matches
        @test Pair(2, 7) in matching.matches
        @test Pair(3, 6) in matching.matches
        @test Edge(1, 5) in edges(digraph)
        @test Edge(5, 2) in edges(digraph)
        @test Edge(2, 7) in edges(digraph)
        @test Edge(5, 3) in edges(digraph)
        @test Edge(3, 6) in edges(digraph)
        @test Edge(7, 3) in edges(digraph)
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
    @testset "orderEdge(::Edge)::Edge" begin
        @test SeaPearl.orderEdge(Edge(1, 2)) == Edge(1, 2)
        @test SeaPearl.orderEdge(Edge(2, 1)) == Edge(1, 2)
    end
    @testset "initializeGraphs!(::AllDifferent)::Pair{Graph{Int}, DiGraph{Int}}" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(1, 3, "x", trailer)
        y = SeaPearl.IntVar(2, 3, "y", trailer)
        z = SeaPearl.IntVar(2, 3, "Z", trailer)
        vec = Vector{SeaPearl.AbstractIntVar}([x, y, z])

        constraint = SeaPearl.AllDifferent(vec, trailer)
        SeaPearl.setValue!(constraint.edgesState[Edge(1, 6)], SeaPearl.removed)
        graph, digraph = SeaPearl.initializeGraphs!(constraint)

        @test Edge(1, 4) in edges(graph)
        @test Edge(1, 5) in edges(graph)
        @test Edge(2, 5) in edges(graph)
        @test Edge(2, 6) in edges(graph)
        @test Edge(3, 5) in edges(graph)
        @test Edge(3, 6) in edges(graph)
        @test ne(graph) == 6
    end
    @testset "getalledges(::DiGraph, ::Vector{Int})" begin
        bipartite = DiGraph(7)
        add_edge!(bipartite, 4, 1)
        add_edge!(bipartite, 5, 1)
        add_edge!(bipartite, 1, 6)
        add_edge!(bipartite, 2, 5)
        add_edge!(bipartite, 6, 2)
        add_edge!(bipartite, 3, 7)
        parents = bfs_parents(bipartite, 4; dir=:out)
        edgeset = SeaPearl.getalledges(bipartite, parents)

        @test length(edgeset) == 4
        @test Edge(1, 4) in edgeset
        @test Edge(1, 6) in edgeset
        @test Edge(2, 5) in edgeset
        @test Edge(2, 6) in edgeset
    end
    @testset "getalledges(::DiGraph, ::Vector{Int}, ::Vector{Int})" begin
        bipartite = DiGraph(7)
        add_edge!(bipartite, 4, 1)
        add_edge!(bipartite, 5, 1)
        add_edge!(bipartite, 1, 6)
        add_edge!(bipartite, 2, 5)
        add_edge!(bipartite, 6, 2)
        add_edge!(bipartite, 3, 7)
        edgeset = SeaPearl.getalledges(bipartite, [1, 2], [5, 6])

        @test length(edgeset) == 4
        @test Edge(1, 5) in edgeset
        @test Edge(1, 6) in edgeset
        @test Edge(2, 5) in edgeset
        @test Edge(2, 6) in edgeset
    end
    @testset "removeEdges!(::AllDifferent, ::Vector{Vector{Int}}, ::Graph, ::DiGraph)" begin

        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(1, 2, "x", trailer)
        y = SeaPearl.IntVar(2, 3, "y", trailer)
        z = SeaPearl.IntVar(1, 3, "z", trailer)
        SeaPearl.remove!(z.domain, 2)
        a = SeaPearl.IntVar(2, 4, "a", trailer)
        SeaPearl.remove!(a.domain, 3)
        b = SeaPearl.IntVar(3, 6, "b", trailer)
        c = SeaPearl.IntVar(6, 7, "c", trailer)
        vars = Vector{SeaPearl.AbstractIntVar}([x, y, z, a, b, c])
        constraint = SeaPearl.AllDifferent(vars, trailer)

        graph, digraph = SeaPearl.initializeGraphs!(constraint)
        matching = SeaPearl.Matching(6, [Pair(1, 7), Pair(2, 8), Pair(3, 9), Pair(4, 10), Pair(5, 11), Pair(6, 12)])
        SeaPearl.setValue!(constraint.matched, matching.size)
        for (idx, match) in enumerate(matching.matches)
            constraint.matching[idx] = SeaPearl.StateObject{Pair{Int, Int}}(match, trailer)
        end
        SeaPearl.setValue!(constraint.initialized, true)
        SeaPearl.builddigraph!(digraph, graph, matching)
        prunedValues = Vector{Vector{Int}}(undef, constraint.numberOfVars)
        for i = 1:constraint.numberOfVars
            prunedValues[i] = Int[]
        end
        SeaPearl.removeEdges!(constraint, prunedValues, graph, digraph)

        @test isempty(prunedValues[1])
        @test isempty(prunedValues[2])
        @test isempty(prunedValues[3])
        @test prunedValues[4] == [2]
        @test Set(prunedValues[5]) == Set([3, 4])
        @test isempty(prunedValues[6])

        @test !(Edge(8, 4) in edges(digraph))
        @test !(Edge(9, 5) in edges(digraph))
        @test !(Edge(10, 5) in edges(digraph))

        @test !(Edge(8, 4) in edges(graph))
        @test !(Edge(9, 5) in edges(graph))
        @test !(Edge(10, 5) in edges(graph))
    end
    @testset "propagate!(::AllDifferent, ::Set{Constraint}, ::CPModification)" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(1, 2, "x", trailer)
        y = SeaPearl.IntVar(2, 3, "y", trailer)
        z = SeaPearl.IntVar(1, 3, "z", trailer)
        SeaPearl.remove!(z.domain, 2)
        a = SeaPearl.IntVar(2, 4, "a", trailer)
        SeaPearl.remove!(a.domain, 3)
        b = SeaPearl.IntVar(3, 6, "b", trailer)
        c = SeaPearl.IntVar(6, 7, "c", trailer)
        vars = Vector{SeaPearl.AbstractIntVar}([x, y, z, a, b, c])
        constraint = SeaPearl.AllDifferent(vars, trailer)

        toPropagate = Set{SeaPearl.Constraint}([constraint])
        modif = SeaPearl.CPModification(Dict("z" => [1]))
        SeaPearl.remove!(z.domain, 1)

        res = SeaPearl.propagate!(constraint, toPropagate, modif)

        @test res
        @test !(constraint in toPropagate)
        @test modif["x"] == [2]
        @test modif["y"] == [3]
        @test modif["z"] == [1]
        @test modif["a"] == [2]
        @test 3 in modif["b"] && 4 in modif["b"]
        @test !("c" in keys(modif))

        @test length(x.domain) == 1
        @test length(y.domain) == 1
        @test length(z.domain) == 1
        @test length(a.domain) == 1
        @test length(b.domain) == 2
        @test length(c.domain) == 2

    end
    @testset "4 queens" begin
        trailer = SeaPearl.Trailer()
        n = 3
        rows = Vector{SeaPearl.AbstractIntVar}(undef, n)
        for i = 1:n
            rows[i] = SeaPearl.IntVar(1, n, "row_"*string(i), trailer)
        end

        rows_plus = Vector{SeaPearl.AbstractIntVar}(undef, n)
        for i = 1:n
            rows_plus[i] = SeaPearl.IntVarViewOffset(rows[i], i, rows[i].id*"+"*string(i))
        end

        rows_minus = Vector{SeaPearl.AbstractIntVar}(undef, n)
        for i = 1:n
            rows_minus[i] = SeaPearl.IntVarViewOffset(rows[i], -i, rows[i].id*"-"*string(i))
        end

        con1 = SeaPearl.AllDifferent(rows, trailer)
        con2 = SeaPearl.AllDifferent(rows_plus, trailer)
        con3 = SeaPearl.AllDifferent(rows_minus, trailer)

        modif = SeaPearl.CPModification()

        @test SeaPearl.propagate!(con1, toPropagate, modif)
        @test SeaPearl.propagate!(con3, toPropagate, modif)
        @test SeaPearl.propagate!(con2, toPropagate, modif)

        SeaPearl.withNewState!(trailer) do
            SeaPearl.assign!(rows[1].domain, 1)
            toPropagate = Set{SeaPearl.Constraint}([con1, con2, con3])

            @test SeaPearl.propagate!(con1, toPropagate, modif)
            @test SeaPearl.propagate!(con3, toPropagate, modif)
            @test !SeaPearl.propagate!(con2, toPropagate, modif)
        end
        modif = SeaPearl.CPModification()
        SeaPearl.withNewState!(trailer) do
            SeaPearl.assign!(rows[1].domain, 2)
            toPropagate = Set{SeaPearl.Constraint}([con1, con2, con3])

            @test SeaPearl.propagate!(con1, toPropagate, modif)
            @test SeaPearl.propagate!(con3, toPropagate, modif)
            @test !SeaPearl.propagate!(con2, toPropagate, modif)
        end
    end
end

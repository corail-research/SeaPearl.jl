@testset "alldifferent.jl" begin
    @testset "AllDifferent(::Vector{AbstractIntVar}, ::Trailer)" begin
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(1, 3, "x", trailer)
        y = SeaPearl.IntVar(2, 3, "y", trailer)
        z = SeaPearl.IntVar(2, 3, "Z", trailer)
        vec = Vector{SeaPearl.IntVar}([x, y, z])

        constraint = SeaPearl.AllDifferent(vec, trailer)

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
        vec = Vector{SeaPearl.IntVar}([x, y, z])

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
    @testset "getAllEdges(::DiGraph, ::Vector{Int})" begin
        bipartite = DiGraph(7)
        add_edge!(bipartite, 4, 1)
        add_edge!(bipartite, 5, 1)
        add_edge!(bipartite, 1, 6)
        add_edge!(bipartite, 2, 5)
        add_edge!(bipartite, 6, 2)
        add_edge!(bipartite, 3, 7)
        parents = bfs_parents(bipartite, 4; dir=:out)
        edgeset = SeaPearl.getAllEdges(bipartite, parents)

        @test length(edgeset) == 5
        @test Edge(1, 4) in edgeset
        @test Edge(1, 6) in edgeset
        @test Edge(2, 5) in edgeset
        @test Edge(2, 6) in edgeset
        @test Edge(1, 5) in edgeset
    end
    @testset "getAllEdges(::DiGraph, ::Vector{Int}, ::Vector{Int})" begin
        bipartite = DiGraph(7)
        add_edge!(bipartite, 4, 1)
        add_edge!(bipartite, 5, 1)
        add_edge!(bipartite, 1, 6)
        add_edge!(bipartite, 2, 5)
        add_edge!(bipartite, 6, 2)
        add_edge!(bipartite, 3, 7)
        edgeset = SeaPearl.getAllEdges(bipartite, [1, 2], [5, 6])

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
        vars = [x, y, z, a, b, c]
        constraint = SeaPearl.AllDifferent(vars, trailer)

        graph, digraph = SeaPearl.initializeGraphs!(constraint)
        matching = SeaPearl.Matching(6, [Pair(1, 7), Pair(2, 8), Pair(3, 9), Pair(4, 10), Pair(5, 11), Pair(6, 12)])
        for (idx, match) in enumerate(matching.matches)
            constraint.matching[idx] = SeaPearl.StateObject{Pair{Int, Int}}(match, trailer)
        end
        SeaPearl.setValue!(constraint.initialized, true)
        SeaPearl.buildDigraph!(digraph, graph, matching)
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
        vars = Matrix{SeaPearl.AbstractIntVar}([x y z; a b c])
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
    @testset "3 queens dummy" begin
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
        toPropagate = Set{SeaPearl.Constraint}([con1, con2, con3])

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
    @testset "5 queens full" begin
        n=5
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        rows = Vector{SeaPearl.IntVar}(undef, n)
        for i = 1:n
            rows[i] = SeaPearl.IntVar(1, n, "row_"*string(i), trailer)
            SeaPearl.addVariable!(model, rows[i]; branchable=true)
        end

        rows_plus = Vector{SeaPearl.IntVarView}(undef, n)
        for i = 1:n
            rows_plus[i] = SeaPearl.IntVarViewOffset(rows[i], i, rows[i].id*"+"*string(i))
            #SeaPearl.addVariable!(model, rows_plus[i]; branchable=false)
        end

        rows_minus = Vector{SeaPearl.IntVarView}(undef, n)
        for i = 1:n
            rows_minus[i] = SeaPearl.IntVarViewOffset(rows[i], -i, rows[i].id*"-"*string(i))
            #SeaPearl.addVariable!(model, rows_minus[i]; branchable=false)
        end

        SeaPearl.addConstraint!(model, SeaPearl.AllDifferent(rows, trailer))
        SeaPearl.addConstraint!(model, SeaPearl.AllDifferent(rows_plus, trailer))
        SeaPearl.addConstraint!(model, SeaPearl.AllDifferent(rows_minus, trailer))

        variableSelection = SeaPearl.MinDomainVariableSelection{false}()
        status = SeaPearl.solve!(model; variableHeuristic=variableSelection)

        @test status == :Optimal
        @test model.statistics.numberOfSolutions == 10
    end
    @testset "7 queens full" begin
        n=7
        trailer = SeaPearl.Trailer()
        model = SeaPearl.CPModel(trailer)

        rows = Vector{SeaPearl.AbstractIntVar}(undef, n)
        for i = 1:n
            rows[i] = SeaPearl.IntVar(1, n, "row_"*string(i), trailer)
            SeaPearl.addVariable!(model, rows[i]; branchable=true)
        end

        rows_plus = Vector{SeaPearl.AbstractIntVar}(undef, n)
        for i = 1:n
            rows_plus[i] = SeaPearl.IntVarViewOffset(rows[i], i, rows[i].id*"+"*string(i))
            #SeaPearl.addVariable!(model, rows_plus[i]; branchable=false)
        end

        rows_minus = Vector{SeaPearl.AbstractIntVar}(undef, n)
        for i = 1:n
            rows_minus[i] = SeaPearl.IntVarViewOffset(rows[i], -i, rows[i].id*"-"*string(i))
            #SeaPearl.addVariable!(model, rows_minus[i]; branchable=false)
        end

        SeaPearl.addConstraint!(model, SeaPearl.AllDifferent(rows, trailer))
        SeaPearl.addConstraint!(model, SeaPearl.AllDifferent(rows_plus, trailer))
        SeaPearl.addConstraint!(model, SeaPearl.AllDifferent(rows_minus, trailer))

        variableSelection = SeaPearl.MinDomainVariableSelection{false}()
        status = SeaPearl.solve!(model; variableHeuristic=variableSelection)

        @test status == :Optimal
        @test model.statistics.numberOfSolutions == 40
    end

    @testset "variablesArray()" begin 
        trailer = SeaPearl.Trailer()
        x = SeaPearl.IntVar(1, 3, "x", trailer)
        y = SeaPearl.IntVar(2, 3, "y", trailer)
        z = SeaPearl.IntVar(2, 3, "Z", trailer)
        vec = Vector{SeaPearl.IntVar}([x, y, z])

        constraint = SeaPearl.AllDifferent(vec, trailer)
        @test length(SeaPearl.variablesArray(constraint)) == 3
    end
end

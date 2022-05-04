@testset "arrayOfEveryValue()" begin
    trailer = SeaPearl.Trailer()

    x = SeaPearl.IntVar(2, 3, "x", trailer)
    y = SeaPearl.IntVar(3, 4, "y", trailer)

    @test SeaPearl.arrayOfEveryValue(SeaPearl.AbstractIntVar[x, y]) == [4, 2, 3]
end

@testset "cpVertexFromIndex()" begin
    trailer = SeaPearl.Trailer()
    model = SeaPearl.CPModel(trailer)

    x = SeaPearl.IntVar(2, 3, "x", trailer)
    y = SeaPearl.IntVar(2, 3, "y", trailer)
    SeaPearl.addVariable!(model, x)
    SeaPearl.addVariable!(model, y)
    SeaPearl.addConstraint!(model, SeaPearl.Equal(x, y, trailer))
    SeaPearl.addConstraint!(model, SeaPearl.NotEqual(x, y, trailer))

    g = SeaPearl.CPLayerGraph(model)

    true_idToNode = [
        SeaPearl.ConstraintVertex(model.constraints[1]), 
        SeaPearl.ConstraintVertex(model.constraints[2]),
        SeaPearl.VariableVertex(x),
        SeaPearl.VariableVertex(y),
        SeaPearl.ValueVertex(2),
        SeaPearl.ValueVertex(3)
    ]

    for i in 1:6
        @test SeaPearl.cpVertexFromIndex(g, i) == true_idToNode[i]
    end
end

@testset "indexFromCpVertex()" begin
    trailer = SeaPearl.Trailer()
    model = SeaPearl.CPModel(trailer)

    x = SeaPearl.IntVar(2, 3, "x", trailer)
    y = SeaPearl.IntVar(2, 3, "y", trailer)
    SeaPearl.addVariable!(model, x)
    SeaPearl.addVariable!(model, y)
    SeaPearl.addConstraint!(model, SeaPearl.Equal(x, y, trailer))
    SeaPearl.addConstraint!(model, SeaPearl.NotEqual(x, y, trailer))

    g = SeaPearl.CPLayerGraph(model)

    true_idToNode = [
        SeaPearl.ConstraintVertex(model.constraints[1]), 
        SeaPearl.ConstraintVertex(model.constraints[2]),
        SeaPearl.VariableVertex(x),
        SeaPearl.VariableVertex(y),
        SeaPearl.ValueVertex(2),
        SeaPearl.ValueVertex(3)
    ]

    for i in 1:6
        @test SeaPearl.indexFromCpVertex(g, true_idToNode[i]) == i
    end
end

@testset "caracteristics" begin
    trailer = SeaPearl.Trailer()
    model = SeaPearl.CPModel(trailer)

    g = SeaPearl.CPLayerGraph(model)

    @test eltype(g) == Int64
    @test LightGraphs.edgetype(g) == LightGraphs.SimpleEdge{Int64}
    @test !LightGraphs.is_directed(SeaPearl.CPLayerGraph)
end

@testset "has_vertex()" begin
    trailer = SeaPearl.Trailer()
    model = SeaPearl.CPModel(trailer)

    x = SeaPearl.IntVar(2, 3, "x", trailer)
    y = SeaPearl.IntVar(2, 3, "y", trailer)
    SeaPearl.addVariable!(model, x)
    SeaPearl.addVariable!(model, y)
    SeaPearl.addConstraint!(model, SeaPearl.Equal(x, y, trailer))
    SeaPearl.addConstraint!(model, SeaPearl.NotEqual(x, y, trailer))

    g = SeaPearl.CPLayerGraph(model)

    for i in 1:6
        @test LightGraphs.has_vertex(g, i)
    end
    @test !LightGraphs.has_vertex(g, 0)
    @test !LightGraphs.has_vertex(g, 7)
end

@testset "has_edge()" begin
    trailer = SeaPearl.Trailer()
    model = SeaPearl.CPModel(trailer)

    x = SeaPearl.IntVar(2, 3, "x", trailer)
    y = SeaPearl.IntVar(2, 3, "y", trailer)
    SeaPearl.addVariable!(model, x)
    SeaPearl.addVariable!(model, y)
    SeaPearl.addConstraint!(model, SeaPearl.Equal(x, y, trailer))
    SeaPearl.addConstraint!(model, SeaPearl.NotEqual(x, y, trailer))

    g = SeaPearl.CPLayerGraph(model)

    SeaPearl.assign!(x, 2)

    @test !has_edge(g, 1, 2)
    @test !has_edge(g, 2, 1)
    @test !has_edge(g, 3, 4)

    @test has_edge(g, 1, 3)

    @test has_edge(g, 3, 5)
    @test !has_edge(g, 3, 6)
    @test has_edge(g, 4, 6)
    @test has_edge(g, 4, 5)
end

@testset "edges() & ne() & nv()" begin
    trailer = SeaPearl.Trailer()
    model = SeaPearl.CPModel(trailer)

    x = SeaPearl.IntVar(2, 3, "x", trailer)
    y = SeaPearl.IntVar(2, 3, "y", trailer)
    SeaPearl.addVariable!(model, x)
    SeaPearl.addVariable!(model, y)
    SeaPearl.addConstraint!(model, SeaPearl.Equal(x, y, trailer))
    SeaPearl.addConstraint!(model, SeaPearl.NotEqual(x, y, trailer))

    g = SeaPearl.CPLayerGraph(model)

    SeaPearl.assign!(x, 2)

    @test sort(LightGraphs.edges(g); by=(e -> (e.src, e.dst))) == sort([
        LightGraphs.SimpleEdge{Int64}(1, 4),
        LightGraphs.SimpleEdge{Int64}(2, 4),
        LightGraphs.SimpleEdge{Int64}(4, 5),
        LightGraphs.SimpleEdge{Int64}(3, 5),
        LightGraphs.SimpleEdge{Int64}(4, 6),
        LightGraphs.SimpleEdge{Int64}(1, 3),
        LightGraphs.SimpleEdge{Int64}(2, 3)
    ]; by=(e -> (e.src, e.dst))) 

    @test LightGraphs.ne(g) == 7
end

@testset "inneighbors()/outneightbors()" begin
    trailer = SeaPearl.Trailer()
    model = SeaPearl.CPModel(trailer)

    x = SeaPearl.IntVar(2, 3, "x", trailer)
    y = SeaPearl.IntVar(2, 3, "y", trailer)
    SeaPearl.addVariable!(model, x)
    SeaPearl.addVariable!(model, y)
    SeaPearl.addConstraint!(model, SeaPearl.Equal(x, y, trailer))
    SeaPearl.addConstraint!(model, SeaPearl.NotEqual(x, y, trailer))

    g = SeaPearl.CPLayerGraph(model)

    SeaPearl.assign!(x, 2)

    @test LightGraphs.inneighbors(g, 3) == [1, 2, 5]
    @test LightGraphs.inneighbors(g, 4) == [1, 2, 5, 6]
    @test LightGraphs.inneighbors(g, 6) == [4]
    @test LightGraphs.inneighbors(g, 5) == [3, 4]

    @test LightGraphs.outneighbors(g, 3) == [1, 2, 5]
    @test LightGraphs.outneighbors(g, 4) == [1, 2, 5, 6]
    @test LightGraphs.outneighbors(g, 6) == [4]
    @test LightGraphs.outneighbors(g, 5) == [3, 4]
end

@testset "CPLayerGraph => Simplegraph features" begin
    trailer = SeaPearl.Trailer()
    model = SeaPearl.CPModel(trailer)

    x = SeaPearl.IntVar(2, 3, "x", trailer)
    y = SeaPearl.IntVar(2, 3, "y", trailer)
    SeaPearl.addVariable!(model, x)
    SeaPearl.addVariable!(model, y)
    SeaPearl.addConstraint!(model, SeaPearl.Equal(x, y, trailer))
    SeaPearl.addConstraint!(model, SeaPearl.NotEqual(x, y, trailer))

    g = SeaPearl.CPLayerGraph(model)
    sg = SimpleGraph(g)

    @test nv(sg) == 6
    @test ne(sg) == 8

    z = SeaPearl.IntVar(2, 3, "Z", trailer)
    SeaPearl.addVariable!(model, z)   #add an isolated variable

    g = SeaPearl.CPLayerGraph(model)
    sg = SimpleGraph(g)

    @test nv(sg) == 7  
    @test ne(sg) == 10

    @test adjacency_matrix(g)==adjacency_matrix(sg)
end

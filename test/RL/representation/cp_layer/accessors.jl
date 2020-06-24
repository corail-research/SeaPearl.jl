using CPRL
using LightGraphs

@testset "arrayOfEveryValue()" begin
    trailer = CPRL.Trailer()

    x = CPRL.IntVar(2, 3, "x", trailer)
    y = CPRL.IntVar(3, 4, "y", trailer)

    @test CPRL.arrayOfEveryValue(CPRL.AbstractIntVar[x, y]) == [4, 2, 3]
end

@testset "cpVertexFromIndex()" begin
    trailer = CPRL.Trailer()
    model = CPRL.CPModel(trailer)

    x = CPRL.IntVar(2, 3, "x", trailer)
    y = CPRL.IntVar(2, 3, "y", trailer)
    CPRL.addVariable!(model, x)
    CPRL.addVariable!(model, y)
    push!(model.constraints, CPRL.Equal(x, y, trailer))
    push!(model.constraints, CPRL.NotEqual(x, y, trailer))

    g = CPRL.CPLayerGraph(model)

    true_idToNode = [
        CPRL.ConstraintVertex(model.constraints[1]), 
        CPRL.ConstraintVertex(model.constraints[2]),
        CPRL.VariableVertex(x),
        CPRL.VariableVertex(y),
        CPRL.ValueVertex(2),
        CPRL.ValueVertex(3)
    ]

    for i in 1:6
        @test CPRL.cpVertexFromIndex(g, i) == true_idToNode[i]
    end
end

@testset "indexFromCpVertex()" begin
    trailer = CPRL.Trailer()
    model = CPRL.CPModel(trailer)

    x = CPRL.IntVar(2, 3, "x", trailer)
    y = CPRL.IntVar(2, 3, "y", trailer)
    CPRL.addVariable!(model, x)
    CPRL.addVariable!(model, y)
    push!(model.constraints, CPRL.Equal(x, y, trailer))
    push!(model.constraints, CPRL.NotEqual(x, y, trailer))

    g = CPRL.CPLayerGraph(model)

    true_idToNode = [
        CPRL.ConstraintVertex(model.constraints[1]), 
        CPRL.ConstraintVertex(model.constraints[2]),
        CPRL.VariableVertex(x),
        CPRL.VariableVertex(y),
        CPRL.ValueVertex(2),
        CPRL.ValueVertex(3)
    ]

    for i in 1:6
        @test CPRL.indexFromCpVertex(g, true_idToNode[i]) == i
    end
end

@testset "caracteristics" begin
    trailer = CPRL.Trailer()
    model = CPRL.CPModel(trailer)

    g = CPRL.CPLayerGraph(model)

    @test eltype(g) == Int64
    @test LightGraphs.edgetype(g) == LightGraphs.SimpleEdge{Int64}
    @test !LightGraphs.is_directed(CPRL.CPLayerGraph)
end

@testset "has_vertex()" begin
    trailer = CPRL.Trailer()
    model = CPRL.CPModel(trailer)

    x = CPRL.IntVar(2, 3, "x", trailer)
    y = CPRL.IntVar(2, 3, "y", trailer)
    CPRL.addVariable!(model, x)
    CPRL.addVariable!(model, y)
    push!(model.constraints, CPRL.Equal(x, y, trailer))
    push!(model.constraints, CPRL.NotEqual(x, y, trailer))

    g = CPRL.CPLayerGraph(model)

    for i in 1:6
        @test LightGraphs.has_vertex(g, i)
    end
    @test !LightGraphs.has_vertex(g, 0)
    @test !LightGraphs.has_vertex(g, 7)
end

@testset "has_edge()" begin
    trailer = CPRL.Trailer()
    model = CPRL.CPModel(trailer)

    x = CPRL.IntVar(2, 3, "x", trailer)
    y = CPRL.IntVar(2, 3, "y", trailer)
    CPRL.addVariable!(model, x)
    CPRL.addVariable!(model, y)
    push!(model.constraints, CPRL.Equal(x, y, trailer))
    push!(model.constraints, CPRL.NotEqual(x, y, trailer))

    g = CPRL.CPLayerGraph(model)

    CPRL.assign!(x, 2)

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
    trailer = CPRL.Trailer()
    model = CPRL.CPModel(trailer)

    x = CPRL.IntVar(2, 3, "x", trailer)
    y = CPRL.IntVar(2, 3, "y", trailer)
    CPRL.addVariable!(model, x)
    CPRL.addVariable!(model, y)
    push!(model.constraints, CPRL.Equal(x, y, trailer))
    push!(model.constraints, CPRL.NotEqual(x, y, trailer))

    g = CPRL.CPLayerGraph(model)

    CPRL.assign!(x, 2)

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
    trailer = CPRL.Trailer()
    model = CPRL.CPModel(trailer)

    x = CPRL.IntVar(2, 3, "x", trailer)
    y = CPRL.IntVar(2, 3, "y", trailer)
    CPRL.addVariable!(model, x)
    CPRL.addVariable!(model, y)
    push!(model.constraints, CPRL.Equal(x, y, trailer))
    push!(model.constraints, CPRL.NotEqual(x, y, trailer))

    g = CPRL.CPLayerGraph(model)

    CPRL.assign!(x, 2)

    @test LightGraphs.inneighbors(g, 3) == [1, 2, 5]
    @test LightGraphs.inneighbors(g, 4) == [1, 2, 5, 6]
    @test LightGraphs.inneighbors(g, 6) == [4]
    @test LightGraphs.inneighbors(g, 5) == [3, 4]

    @test LightGraphs.outneighbors(g, 3) == [1, 2, 5]
    @test LightGraphs.outneighbors(g, 4) == [1, 2, 5, 6]
    @test LightGraphs.outneighbors(g, 6) == [4]
    @test LightGraphs.outneighbors(g, 5) == [3, 4]
end

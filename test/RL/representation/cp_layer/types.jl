using CPRL

@testset "CPLayerGraph()" begin
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

    @test g.cpmodel == model
    @test g.idToNode == true_idToNode
    @test length(keys(g.nodeToId)) == 6

    for i in 1:6
        @test g.nodeToId[true_idToNode[i]] == i
    end

    @test Matrix(LightGraphs.LinAlg.adjacency_matrix(g.fixedEdgesGraph)) == [
        0 0 1 1
        0 0 1 1
        1 1 0 0
        1 1 0 0
    ]

    @test g.numberOfConstraints == 2
    @test g.numberOfVariables == 2
    @test g.numberOfValues == 2
    @test g.totalLength == 6

    empty_g = CPRL.CPLayerGraph()
    @test isnothing(empty_g.cpmodel)
end
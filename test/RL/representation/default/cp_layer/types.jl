using CPRL

@testset "CPLayerGraph()" begin
    trailer = CPRL.Trailer()
    model = CPRL.CPModel(trailer)

    x = CPRL.IntVar(2, 3, "x", trailer)
    y = CPRL.IntVar(2, 3, "y", trailer)
    z = CPRL.IntVarViewOpposite(y, "-y")
    CPRL.addVariable!(model, x)
    CPRL.addVariable!(model, y)
    push!(model.constraints, CPRL.Equal(x, y, trailer))
    push!(model.constraints, CPRL.NotEqual(x, y, trailer))
    push!(model.constraints, CPRL.NotEqual(z, y, trailer))

    g = CPRL.CPLayerGraph(model)

    true_idToNode = [
        CPRL.ConstraintVertex(model.constraints[1]), 
        CPRL.ConstraintVertex(model.constraints[2]),
        CPRL.ConstraintVertex(model.constraints[3]),
        CPRL.VariableVertex(z),
        CPRL.VariableVertex(x),
        CPRL.VariableVertex(y),
        CPRL.ValueVertex(2),
        CPRL.ValueVertex(3)
    ]

    @test g.cpmodel == model
    @test g.idToNode == true_idToNode
    @test length(keys(g.nodeToId)) == 8

    for i in 1:7
        @test g.nodeToId[true_idToNode[i]] == i
    end

    @test Matrix(LightGraphs.LinAlg.adjacency_matrix(g.fixedEdgesGraph)) == [
        0 0 0 0 1 1
        0 0 0 0 1 1
        0 0 0 1 0 1
        0 0 1 0 0 1
        1 1 0 0 0 0
        1 1 1 1 0 0
    ]

    @test g.numberOfConstraints == 3
    @test g.numberOfVariables == 3
    @test g.numberOfValues == 2
    @test g.totalLength == 8

    empty_g = CPRL.CPLayerGraph()
    @test isnothing(empty_g.cpmodel)
end
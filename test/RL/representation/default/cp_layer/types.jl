@testset "CPLayerGraph()" begin
    trailer = SeaPearl.Trailer()
    model = SeaPearl.CPModel(trailer)

    x = SeaPearl.IntVar(2, 3, "x", trailer)
    y = SeaPearl.IntVar(2, 3, "y", trailer)
    z = SeaPearl.IntVarViewOpposite(y, "-y")
    SeaPearl.addVariable!(model, x)
    SeaPearl.addVariable!(model, y)
    SeaPearl.addConstraint!(model, SeaPearl.Equal(x, y, trailer))
    SeaPearl.addConstraint!(model, SeaPearl.NotEqual(x, y, trailer))
    SeaPearl.addConstraint!(model, SeaPearl.NotEqual(z, y, trailer))

    g = SeaPearl.CPLayerGraph(model)

    true_idToNode = [
        SeaPearl.ConstraintVertex(model.constraints[1]), 
        SeaPearl.ConstraintVertex(model.constraints[2]),
        SeaPearl.ConstraintVertex(model.constraints[3]),
        SeaPearl.ConstraintVertex(ViewConstraint(y,z)),
        SeaPearl.VariableVertex(z),
        SeaPearl.VariableVertex(x),
        SeaPearl.VariableVertex(y),
        SeaPearl.ValueVertex(2),
        SeaPearl.ValueVertex(3)
    ]

    @test g.cpmodel == model
    @test g.idToNode == true_idToNode
    @test length(keys(g.nodeToId)) == 9

    for i in 1:9
        @test g.nodeToId[true_idToNode[i]] == i
    end

    @test Matrix(LightGraphs.LinAlg.adjacency_matrix(g.fixedEdgesGraph)) == [
        0 0 0 0 1 1 0
        0 0 0 0 1 1 0
        0 0 0 0 0 1 1
        0 0 0 0 0 1 1
        1 1 0 0 0 0 0
        1 1 1 1 0 0 0
        0 0 1 1 0 0 0
    ]

    @test g.numberOfConstraints == 4
    @test g.numberOfVariables == 3
    @test g.numberOfValues == 2
    @test g.totalLength == 9

    empty_g = SeaPearl.CPLayerGraph()
    @test isnothing(empty_g.cpmodel)
end
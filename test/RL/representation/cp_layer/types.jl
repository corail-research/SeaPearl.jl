using LightGraphs
using CPRL

function testCPLayerGraph()
    trailer = CPRL.Trailer()
    model = CPRL.CPModel(trailer)
    
    x = CPRL.IntVar(2, 3, "x", trailer)
    y = CPRL.IntVar(2, 3, "y", trailer)
    CPRL.addVariable!(model, x)
    CPRL.addVariable!(model, y)
    push!(model.constraints, CPRL.Equal(x, y, trailer))

    layerGraph = CPRL.CPLayerGraph(model)
    return layerGraph
end
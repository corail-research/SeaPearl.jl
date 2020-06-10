using CPRL
using GraphPlot
using Gadfly

function testCPLayerGraph()
    trailer = CPRL.Trailer()
    model = CPRL.CPModel(trailer)
    
    x = CPRL.IntVar(2, 3, "x", trailer)
    y = CPRL.IntVar(2, 3, "y", trailer)
    CPRL.addVariable!(model, x)
    CPRL.addVariable!(model, y)
    push!(model.constraints, CPRL.Equal(x, y, trailer))
    push!(model.constraints, CPRL.NotEqual(x, y, trailer))

    layerGraph = CPRL.CPLayerGraph(model)
    gplot(layerGraph)
    return layerGraph
end
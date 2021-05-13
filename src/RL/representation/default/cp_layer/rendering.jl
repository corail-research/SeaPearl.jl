#function used for graph coloring in SeaPearl Zoo
function labelOfVertex(g::CPLayerGraph, d::Int64)
    cpVertex = cpVertexFromIndex(g, d)
    labelOfVertex(g, cpVertex)
end

labelOfVertex(g::CPLayerGraph, d::ConstraintVertex) = string(typeof(d.constraint)), 1
labelOfVertex(g::CPLayerGraph, d::VariableVertex) = "x"*d.variable.id, 2
labelOfVertex(g::CPLayerGraph, d::ValueVertex) = string(d.value), 3

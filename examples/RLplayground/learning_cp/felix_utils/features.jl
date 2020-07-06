"""
function CPRL.featurize(g::CPRL.CPLayerGraph)
    features = zeros(Float32, nv(g), nv(g))
    for i in 1:size(features)[1]
        features[i, i] = 1.0f0
    end
    features
end
"""

function CPRL.featurize(g::CPRL.CPLayerGraph)
    features = zeros(Float32, nv(g), 21)
    for i in 1:nv(g)
        cp_vertex = CPRL.cpVertexFromIndex(g, i)
        if isa(cp_vertex, CPRL.VariableVertex)
            features[i, 1] = 1.
            if g.cpmodel.objective == cp_vertex.variable
                features[i, 6] = 1.
            end
        end
        if isa(cp_vertex, CPRL.ConstraintVertex)
            features[i, 2] = 1.
            constraint = cp_vertex.constraint
            if isa(constraint, CPRL.NotEqual)
                features[i, 4] = 1.
            end
            if isa(constraint, CPRL.LessOrEqual)
                features[i, 5] = 1.
            end
        end
        if isa(cp_vertex, CPRL.ValueVertex)
            features[i, 3] = 1.
            value = cp_vertex.value
            features[i, 6+value] = 1.
        end
    end
    features
end
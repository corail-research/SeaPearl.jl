function CPRL.featurize(cpmodel::CPRL.CPModel)
    g = CPRL.CPLayerGraph(cpmodel)
    features = zeros(Float32, nv(g), nv(g))
    for i in 1:size(features)[1]
        features[i, i] = 1.0f0
    end
    features
end
function solve!(model::CPModel, strategy::Type{T}=DFSearch; variableHeuristic=selectVariable) where T <: SearchStrategy
    return search!(model, strategy, variableHeuristic)
end

function selectVariable(model::CPModel)
    selectedVar = nothing
    minSize = typemax(Int)
    for (k, x) in model.variables
        if length(x.domain) > 1 && length(x.domain) < minSize
            selectedVar = x
            minSize = length(x.domain)
        end
    end
    # @assert !isnothing(selectedVar)
    return selectedVar
end
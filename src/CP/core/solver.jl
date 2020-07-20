function solve!(model::CPModel, strategy::Type{T}=DFSearch; variableHeuristic=MinDomainVariableSelection) where T <: SearchStrategy
    return search!(model, strategy, variableHeuristic)
end


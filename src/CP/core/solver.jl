"""
    solve!()


"""
function solve!(model::CPModel, strategy::Type{T}=DFSearch; variableHeuristic=MinDomainVariableSelection, valueSelection=LexicographicOrder()) where T <: SearchStrategy
    return search!(model, strategy, variableHeuristic, valueSelection)
end

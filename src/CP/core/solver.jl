"""
    solve!()


"""
function solve!(model::CPModel, strategy::Type{T}=DFSearch; variableHeuristic=MinDomainVariableSelection, valueSelection=BasicHeuristic()) where T <: SearchStrategy
    return search!(model, strategy, variableHeuristic, valueSelection)
end

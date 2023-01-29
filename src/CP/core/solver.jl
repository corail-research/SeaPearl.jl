"""
    solve!(model::CPModel, strategy::T=DFSearch(); variableHeuristic=MinDomainVariableSelection(), valueSelection=BasicHeuristic(), out_solver::Bool=false)
High level function triggering the solving process

"""
function solve!(model::CPModel, strategy::T=DFSearch(); variableHeuristic=MinDomainVariableSelection(), valueSelection=BasicHeuristic(), out_solver::Bool=false) where T <: SearchStrategy
    return search!(model, strategy, variableHeuristic, valueSelection, out_solver=out_solver)
end

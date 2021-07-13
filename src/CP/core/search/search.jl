
include("dfs.jl")
include("ilds.jl")
include("rbs.jl")


"""
    initroot!(toCall::Stack{Function}, ::F, model::CPModel, variableHeuristic::AbstractVariableSelection, valueSelection::ValueSelection) where F <: SearchStrategy
Initialisation function that fill the toCall Stack according to a certain strategy. 
    """
function initroot!(toCall::Stack{Function}, ::F, model::CPModel, variableHeuristic::AbstractVariableSelection, valueSelection::ValueSelection) where F <: SearchStrategy
    throw(ErrorException("Search Strategy $(F) (initroot! function  ) not implemented."))
end 

"""
search!(model::CPModel, strategy::S, variableHeuristic::AbstractVariableSelection, valueSelection::ValueSelection=BasicHeuristic(); out_solver::Bool=false) where S <: SearchStrategy
Perform a search following a specific strategy in the `model` using `variableHeuristic` to choose which domain will be changed
at each branching and using `valueSelection` to choose how the branching will be done. 

"""
function search!(model::CPModel, strategy::S, variableHeuristic::AbstractVariableSelection, valueSelection::ValueSelection=BasicHeuristic(); out_solver::Bool=false) where S <: SearchStrategy

    # create env and get first observation
    valueSelection(InitializingPhase, model)

    toCall = Stack{Function}()
    # Starting at the root node with an empty stack
    currentStatus = initroot!(toCall, strategy,  model, variableHeuristic, valueSelection)
    
    while !isempty(toCall)
        # Stop right away if reached a limit
        if currentStatus == :NodeLimitStop || currentStatus == :SolutionLimitStop || (out_solver && (currentStatus in [:Infeasible, :FoundSolution]))
            break
        end

        if currentStatus != :SavingState
            # set reward and metrics
            valueSelection(StepPhase, model, currentStatus)
        end

        currentProcedure = pop!(toCall)
        currentStatus = currentProcedure(model)
    end
    # set final reward and last observation
    model.statistics.numberOfSolutions=sum(map(x->!isnothing(x),model.statistics.solutions))
    valueSelection(EndingPhase, model, currentStatus)

    if currentStatus == :NodeLimitStop || currentStatus == :SolutionLimitStop || (out_solver & (currentStatus in [:Infeasible, :FoundSolution]))
        return currentStatus
    end
    
    if isa(strategy, DFSearch) && !all(map(x->isnothing(x),model.statistics.solutions)) == 1       #Only the DFS search can give the optimality certificate
        return :Optimal
    elseif !all(map(x->isnothing(x),model.statistics.solutions)) == 1 
        return :NonOptimal
    end
    
    return :Infeasible
end


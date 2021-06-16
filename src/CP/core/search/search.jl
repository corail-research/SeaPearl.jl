
include("dfs.jl")
include("ilds.jl")
include("rbs.jl")
include("strategies.jl")

"""
    search!(model::CPModel, ::Type{Strategy}, variableHeuristic, valueSelection::ValueSelection=BasicHeuristic())

Perform a search following a specific strategy in the `model` using `variableHeuristic` to choose which domain will be changed
at each branching and using `valueSelection` to choose how the branching will be done. 

"""
function initroot!(toCall::Stack{Function}, ::Type{F}, model::CPModel, variableHeuristic::AbstractVariableSelection, valueSelection::ValueSelection) where F <: SearchStrategy
    throw(ErrorException("Search Strategy $(F) not implemented."))
end 


function search!(model::CPModel, ::Type{Strategy}, variableHeuristic::AbstractVariableSelection, valueSelection::ValueSelection=BasicHeuristic(); out_solver::Bool=false) where Strategy <: SearchStrategy

    # create env and get first observation
    valueSelection(InitializingPhase, model)

    toCall = Stack{Function}()
    # Starting at the root node with an empty stack
    currentStatus = initroot!(toCall, Strategy,  model, variableHeuristic, valueSelection)
    
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
    valueSelection(EndingPhase, model, currentStatus)

    if currentStatus == :NodeLimitStop || currentStatus == :SolutionLimitStop || (out_solver & (currentStatus in [:Infeasible, :FoundSolution]))
        return currentStatus
    end
    

    if length(model.statistics.solutions) > 0
        return :Optimal
    end

    return :Infeasible
end
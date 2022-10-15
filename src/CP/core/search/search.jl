
include("dfs.jl")
include("dfwbs.jl")
include("ilds.jl")
include("rbs.jl")
include("lns.jl")


"""
    initroot!(toCall::Stack{Function}, ::F, model::CPModel, variableHeuristic::AbstractVariableSelection, valueSelection::ValueSelection) where F <: SearchStrategy
Initialisation function that fills the toCall Stack according to a certain strategy. 
"""
function initroot!(toCall::Stack{Function}, ::F, model::CPModel, variableHeuristic::AbstractVariableSelection, valueSelection::ValueSelection) where F <: SearchStrategy
    throw(ErrorException("Search Strategy $(F) (initroot! function  ) not implemented.")) # question: Pourquoi cette fonction est nécessaire ici
end 

"""
search!(model::CPModel, strategy::S, variableHeuristic::AbstractVariableSelection, valueSelection::ValueSelection=BasicHeuristic(); out_solver::Bool=false) where S <: SearchStrategy
Perform a search following a specific strategy in the `model` using `variableHeuristic` to choose which domain will be changed
at each branching and using `valueSelection` to choose how the branching will be done.

# Arguments
- `model::CPModel` model for which the search is initiated
- `strategy::S` Search strategy employed
- `variableHeuristic::AbstractVariableSelection` Variable selection heuristic used
- `valueSelection::ValueSelection=BasicHeuristic()` Value selection heuristic Used
- `out_solver::Bool` Whether or not to output the solution status at the end of the resolution process

# TODO: add the return type
"""
function search!(model::CPModel, strategy::S, variableHeuristic::AbstractVariableSelection, valueSelection::ValueSelection=BasicHeuristic(); out_solver::Bool=false) where S <: SearchStrategy # question: pourquoi ce where?
    tic()

    valueSelection(InitializingPhase, model) # create env and get first observation # question: cette fonction va modifier le modèle in-place?
    toCall = Stack{Function}()
    currentStatus = initroot!(toCall, strategy,  model, variableHeuristic, valueSelection) # Starting at the root node with an empty stack
    stopping_conditions = (
        currentStatus == :NodeLimitStop || 
        currentStatus == :SolutionLimitStop || 
        currentStatus == :TimeLimitStop || 
        (out_solver && (currentStatus in [:Infeasible, :FoundSolution]))
    )
    while !isempty(toCall) && !stopping_conditions
        if currentStatus != :SavingState
            valueSelection(StepPhase, model, currentStatus) # set reward and metrics
        end
        currentProcedure = pop!(toCall)
        currentStatus::Union{Nothing, Symbol} = currentProcedure(model, currentStatus)
        stopping_conditions = (
            currentStatus == :NodeLimitStop || 
            currentStatus == :SolutionLimitStop || 
            currentStatus == :TimeLimitStop || 
            (out_solver && (currentStatus in [:Infeasible, :FoundSolution]))
        )
    end
    # set final reward and last observation
    model.statistics.numberOfSolutions = sum(map(x -> !isnothing(x), model.statistics.solutions))
    valueSelection(EndingPhase, model, currentStatus)
    
    toc()
    if stopping_conditions
        return currentStatus
    end
    
    if isa(strategy, DFSearch) && !all(map(x->isnothing(x), model.statistics.solutions)) == 1  # Only the DFS search can give the optimality certificate
        return :Optimal # question: ce return type?
    elseif !all(map(x -> isnothing(x), model.statistics.solutions)) == 1 
        return :NonOptimal
    end
    return :Infeasible
end

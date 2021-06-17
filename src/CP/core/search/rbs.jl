"""
    initroot!(toCall::Stack{Function}, ::Type{DFSearch},model::CPModel, variableHeuristic::AbstractVariableSelection, valueSelection::ValueSelection, newConstraints=nothing)

Used as a generic function to instantiate the research. It fills the toCall Stack in a certains order based on a specific Strategy <: SearchStrategy with 
function that expand the search tree. In restart based strategy, we fill the Stack with calls to expandRbs with different nodeLimit. The nodeLimit corresponds 
to the number of infeasiblesolution that can be reached before restarting the search a the top of the tree with a possibly different nodeLimit. This search 
strategy requires the use of a stochastic variable/value heuristic, otherwise, at each restart the search will end-up on the exact previous solutions. 

staticRBSearch : At each restart, the number of infeasible solution before restart is fixed and equal to strategy.L.   
"""
function initroot!(toCall::Stack{Function}, strategy::staticRBSearch, model::CPModel, variableHeuristic::AbstractVariableSelection, valueSelection::ValueSelection)
    nodeLimit = strategy.L
    for i in strategy.n:-1:2 
        push!(toCall, (model) -> (model.statistics.numberOfInfeasibleSolutions = 0 ;expandRbs!(toCall, model, nodeLimit, variableHeuristic, valueSelection)))
    end
    return expandRbs!(toCall, model, nodeLimit, variableHeuristic, valueSelection)
end

"""
    initroot!(toCall::Stack{Function}, ::Type{DFSearch},model::CPModel, variableHeuristic::AbstractVariableSelection, valueSelection::ValueSelection, newConstraints=nothing)

Used as a generic function to instantiate the research. It fills the toCall Stack in a certains order based on a specific Strategy <: SearchStrategy with 
function that expand the search tree. In restart based strategy, we fill the Stack with calls to expandRbs with different nodeLimit. The nodeLimit corresponds 
to the number of infeasiblesolution that can be reached before restarting the search a the top of the tree with a possibly different nodeLimit. This search 
strategy requires the use of a stochastic variable/value heuristic, otherwise, at each restart the search will end-up on the exact previous solutions. 

geometricRBSearch : At each restart, the number of infeasible solution before restart is increased by the geometric factor strategy.α. strategy.L states the 
initial number of infeasible solution for the first search.  
"""
function initroot!(toCall::Stack{Function}, strategy::geometricRBSearch, model::CPModel, variableHeuristic::AbstractVariableSelection, valueSelection::ValueSelection)
    nodeLimit = strategy.L
    for i in strategy.n:-1:2 
        nodeLimit = Int.(ceil(strategy.L*strategy.α^i))
        push!(toCall, (model) -> (model.statistics.numberOfInfeasibleSolutions = 0 ;expandRbs!(toCall, model, nodeLimit, variableHeuristic, valueSelection)))
    end
    return expandRbs!(toCall, model, strategy.L, variableHeuristic, valueSelection)
end

"""
    initroot!(toCall::Stack{Function}, ::Type{DFSearch},model::CPModel, variableHeuristic::AbstractVariableSelection, valueSelection::ValueSelection, newConstraints=nothing)

Used as a generic function to instantiate the research. It fills the toCall Stack in a certains order based on a specific Strategy <: SearchStrategy with 
function that expand the search tree. In restart based strategy, we fill the Stack with calls to expandRbs with different nodeLimit. The nodeLimit corresponds 
to the number of infeasiblesolution that can be reached before restarting the search a the top of the tree with a possibly different nodeLimit. This search 
strategy requires the use of a stochastic variable/value heuristic, otherwise, at each restart the search will end-up on the exact previous solutions. 

lubyRBSearch : At each restart, the number of infeasible solution before restart is increased by a factor Luby[i]. strategy.L states the 
initial number of infeasible solution for the first search. The Luby sequence is a sequence of the following form: 1,1,2,1,1,2,4,1,1,2,1,1,2,4,8, . .
and gives theoretical improvement on the search in the general case.
"""
function initroot!(toCall::Stack{Function}, strategy::lubyRBSearch, model::CPModel, variableHeuristic::AbstractVariableSelection, valueSelection::ValueSelection)
    searchFactor = Luby(strategy.n)
    for i in strategy.n:-1:2 
        nodeLimit = L
        push!(toCall, (model) -> (model.statistics.numberOfInfeasibleSolutions = 0 ;expandRbs!(toCall, model, nodeLimit*searchFactor[i], variableHeuristic, valueSelection)))
    end
    return expandRbs!(toCall, model, strategy.L*searchFactor[1], variableHeuristic, valueSelection)
end

function Luby(n::Int64)
    output=zeros(n)
    K=map(x -> 2^x-1,1:n)   
    lowerbound= K[(map(x->findfirst(K->K>x,K),1:n).-1)]
    for x in 1:n 
    output[x]= (x in K) ? (x+1)/2 : output[x-lowerbound[x]]
    end
    return Int.(output)
end

"""
    expandRbs!(toCall::Stack{Function}, model::CPModel, variableHeuristic::Function, valueSelection::ValueSelection, newConstraints=nothing)

Add procedures to `toCall`, that, called in the stack order (LIFO) with the `model` parameter, will perform a RBS in the graph.
Some procedures will contain a call to `expandRbs!` itself. Each `expandRbs!` call is wrapped around a `saveState!` and a `restoreState!` to be
able to backtrack thanks to the trailer. 

The Search stops as long as the search reached the limit of infeasible solution allowed before restart.
"""
function expandRbs!(toCall::Stack{Function}, model::CPModel, nodeLimit::Int64, variableHeuristic::AbstractVariableSelection, valueSelection::ValueSelection, newConstraints=nothing; prunedDomains::Union{CPModification,Nothing}=nothing)

    # Dealing with limits
    model.statistics.numberOfNodes += 1

    if !belowNodeLimit(model)
        return :NodeLimitStop
    end
    if !belowSolutionLimit(model)
        return :SolutionLimitStop
    end

    # Fix-point algorithm
    feasible, pruned = fixPoint!(model, newConstraints, prunedDomains)
    if !feasible
        model.statistics.numberOfInfeasibleSolutions += 1
        return :Infeasible
    end
    if solutionFound(model)
        triggerFoundSolution!(model)
        return :FoundSolution
    end

    # Variable selection
    x = variableHeuristic(model)
    # Value selection
    v = valueSelection(DecisionPhase, model, x)

    #println("Value : ", v, " assigned to : ", x.id)
    if  model.statistics.numberOfInfeasibleSolutions < nodeLimit 
        push!(toCall, (model) -> (restoreState!(model.trailer); :BackTracking))
        push!(toCall, (model) -> (
            prunedDomains = CPModification();
            addToPrunedDomains!(prunedDomains, x, remove!(x.domain, v));
            expandRbs!(toCall, model, nodeLimit, variableHeuristic, valueSelection, getOnDomainChange(x); prunedDomains=prunedDomains)
        ))
        push!(toCall, (model) -> (saveState!(model.trailer); :SavingState))
        push!(toCall, (model) -> (restoreState!(model.trailer); :BackTracking))
        push!(toCall, (model) -> (
            prunedDomains = CPModification();
            addToPrunedDomains!(prunedDomains, x, assign!(x, v));
            expandRbs!(toCall, model, nodeLimit, variableHeuristic, valueSelection, getOnDomainChange(x); prunedDomains=prunedDomains)
        ))
        push!(toCall, (model) -> (saveState!(model.trailer); :SavingState))
    end 
    return :Feasible
end

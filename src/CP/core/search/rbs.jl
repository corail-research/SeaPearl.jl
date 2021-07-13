"""
    function generateLimitList(strategy::staticRBSearch)

Used as a generic function to generate limits for each search. 
staticRBSearch : At each restart, the number of infeasible solution before restart is fixed and equal to strategy.L.   
"""
function generateLimitList(strategy::staticRBSearch{C})    where C <: ExpandCriteria
    return fill(strategy.L,strategy.n)
end

"""
    function generateLimitList(strategy::geometricRBSearch)

Used as a generic function to generate limits for each search.  
geometricRBSearch : At each restart, the number of infeasible solution before restart is increased by the geometric factor strategy.α. strategy.L states the 
initial number of infeasible solution for the first search.  
"""
function generateLimitList(strategy::geometricRBSearch{C})   where C <: ExpandCriteria
    output=fill(strategy.L,strategy.n)
    return Int.(map(x -> ceil((x[2]*strategy.α^(x[1]-1))),enumerate(output)))
end

"""
    function generateLimitList(strategy::lubyRBSearch)

Used as a generic function to generate limits for each search.
lubyRBSearch : At each restart, the number of infeasible solution before restart is increased by the factor Luby[i]. strategy.L states the 
initial number of infeasible solution limit for the first search. The Luby sequence is a sequence of the following form: 1,1,2,1,1,2,4,1,1,2,1,1,2,4,8, . .
and gives theoretical improvement on the search in the general case.
"""
function generateLimitList(strategy::lubyRBSearch{C})  where C <: ExpandCriteria
    output=zeros(strategy.n)
    K=map(x -> 2^x-1,1:strategy.n)   
    lowerbound= K[(map(x->findfirst(K->K>x,K),1:strategy.n).-1)]
    for x in 1:strategy.n 
    output[x]= (x in K) ? (x+1)/2 : output[x-lowerbound[x]]
    end
    return Int.(output.*strategy.L)
end

"""
        function initroot!(toCall::Stack{Function}, strategy::S, model::CPModel, variableHeuristic::AbstractVariableSelection, valueSelection::ValueSelection) where {S <: RBSearch}

It fills the toCall Stack in a certains order based on a specific Strategy <: RBSearch with 
function that expand the search tree. In restart based strategy, we fill the Stack with calls to expandRbs with different nodeLimit. The nodeLimit corresponds 
to the number of infeasiblesolution that can be reached before restarting the search a the top of the tree with a possibly different nodeLimit. This search 
strategy requires the use of a stochastic variable/value heuristic, otherwise, at each restart the search will end-up on the exact previous solutions.
"""
function initroot!(toCall::Stack{Function}, strategy::RBSearch{C}, model::CPModel, variableHeuristic::AbstractVariableSelection, valueSelection::ValueSelection) where C <: ExpandCriteria
    nodeLimitList = generateLimitList(strategy)
    for i in strategy.n:-1:2 
        push!(toCall, (model) -> (restart_search!(model) ; expandRbs!(toCall, model, nodeLimitList[i], strategy, variableHeuristic, valueSelection)))
    end
    return expandRbs!(toCall, model, nodeLimitList[1], strategy, variableHeuristic, valueSelection)
end

"""
    expandRbs!(toCall::Stack{Function}, model::CPModel, variableHeuristic::Function, valueSelection::ValueSelection, newConstraints=nothing)

Add procedures to `toCall`, that, called in the stack order (LIFO) with the `model` parameter, will perform a RBS in the graph.
Some procedures will contain a call to `expandRbs!` itself. Each `expandRbs!` call is wrapped around a `saveState!` and a `restoreState!` to be
able to backtrack thanks to the trailer. 

The Search stops as long as the search reached the limit on a given criteria.
.
"""
function expandRbs!(toCall::Stack{Function}, model::CPModel, nodeLimit::Int64, criteria::RBSearch{C}  ,variableHeuristic::AbstractVariableSelection, valueSelection::ValueSelection, newConstraints=nothing; prunedDomains::Union{CPModification,Nothing}=nothing) where C <: ExpandCriteria
    
    # Dealing with limits
    model.statistics.numberOfNodes += 1
    model.statistics.numberOfNodesBeforeRestart += 1

    if !belowNodeLimit(model)
        return :NodeLimitStop
    end
    if !belowSolutionLimit(model)
        return :SolutionLimitStop
    end

    # Fix-point algorithm
    feasible, pruned = fixPoint!(model, newConstraints, prunedDomains)
    model.statistics.lastPruning=sum(map(x-> length(x[2]),collect(pruned)))
    
    if !feasible
        model.statistics.numberOfInfeasibleSolutions += 1
        model.statistics.numberOfInfeasibleSolutionsBeforeRestart += 1
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
    if  criteria(model, nodeLimit)  
        push!(toCall, (model) -> (restoreState!(model.trailer); :BackTracking))
        push!(toCall, (model) -> (
            prunedDomains = CPModification();
            addToPrunedDomains!(prunedDomains, x, remove!(x.domain, v));
            expandRbs!(toCall, model, nodeLimit, criteria, variableHeuristic, valueSelection, getOnDomainChange(x); prunedDomains=prunedDomains)
        ))
        push!(toCall, (model) -> (saveState!(model.trailer); :SavingState))
        push!(toCall, (model) -> (restoreState!(model.trailer); :BackTracking))
        push!(toCall, (model) -> (
            prunedDomains = CPModification();
            addToPrunedDomains!(prunedDomains, x, assign!(x, v));
            expandRbs!(toCall, model, nodeLimit, criteria, variableHeuristic, valueSelection, getOnDomainChange(x); prunedDomains=prunedDomains)
        ))
        push!(toCall, (model) -> (saveState!(model.trailer); :SavingState))
    end 
    return :Feasible
end

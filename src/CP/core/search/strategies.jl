"""SeaPearl Provides several pre-implemented search strategy to explore the search tree in a certain way. The specific strategy has to 
be specified in the search! function. The search strategy choose how the _toCall_ Stack will be filled and empty ( ie. which branch will 
be explored at a certain node ).
"""    
abstract type SearchStrategy end

struct DFSearch <: SearchStrategy end

struct ILDSearch <: SearchStrategy end
abstract type ExpandCriteria end 

abstract type RBSearch{C} <: SearchStrategy where C <: ExpandCriteria end

"""
    struct staticRBSearch <: RBSearch
implements the static Restart-Based strategy where the stopping criteria `L` remains the same at each restart. 
"""
struct staticRBSearch{C} <: RBSearch{C} 
    L::Int64
    n::Int64
end

"""
    struct geometricRBSearch <: RBSearch
implements the geometric Restart-Based strategy where the stopping criteria `L` is increased by the geometric factor `α` at each restart. 
"""
struct geometricRBSearch{C}<: RBSearch{C} 
    L::Int64
    n::Int64
    α::Float32
end
"""
    struct lubyRBSearch <: RBSearch
implements the Luby Restart-Based strategy where the stopping criteria `L` is multiplied by the factor `Luby[i]` for the i-th restart. 
The Luby sequence is a sequence of the following form: 1,1,2,1,1,2,4,1,1,2,1,1,2,4,8, . .and gives theoretical improvement on the search
in the general case.
"""
struct lubyRBSearch{C} <: RBSearch{C}
    L::Int64
    n::Int64
end

abstract type VisitedNodeCriteria <: ExpandCriteria end
"""
    function (criteria::VisitedNodeCriteria)(model::CPModel, limit::Int64)::Bool

The stopping criteria is the number of Visited nodes in the search tree. Here the inequality is large because 
we don't consider the root node of the tree as a visited node. 
"""
function (criteria::RBSearch{VisitedNodeCriteria})(model::CPModel, limit::Int64)::Bool
    return model.statistics.numberOfNodesBeforeRestart <= limit   #CAUTION : Here the inequality is large
end

abstract type InfeasibleNodeCriteria <: ExpandCriteria end 
"""
    function (criteria::InfeasibleNodeCriteria)(model::CPModel, limit::Int64)::Bool

The stopping criteria is the number of visited nodes where the partial solution led to a case where all constraints were not respected. 
(ie. leading to the :Infeasible case in the expandRbs! function)
"""
function (criteria::RBSearch{InfeasibleNodeCriteria})(model::CPModel, limit::Int64)::Bool
    return model.statistics.numberOfInfeasibleSolutionsBeforeRestart < limit
end

abstract type SolutionFoundCriteria <: ExpandCriteria end 
"""
    function (criteria::SolutionFoundCriteria)(model::CPModel, limit::Int64)::Bool

The stopping criteria is the number of Solution Found during the search. As long as L solutions have been found, the search restart at the 
top of the tree.
"""
function (criteria::RBSearch{SolutionFoundCriteria})(model::CPModel, limit::Int64)::Bool
    return model.statistics.numberOfSolutionsBeforeRestart < limit
end
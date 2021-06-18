#TODO add Documentation 
abstract type SearchStrategy end

struct DFSearch <: SearchStrategy end
struct ILDSearch <: SearchStrategy end

abstract type RBSearch <: SearchStrategy end

abstract type expandCriteria end 

struct staticRBSearch <: RBSearch 
    L::Int64
    n::Int64
    criteria::C where C <: expandCriteria
end
struct geometricRBSearch<: RBSearch 
    L::Int64
    n::Int64
    α::Float32
    criteria::C where C <: expandCriteria

end
struct lubyRBSearch <: RBSearch 
    L::Int64
    n::Int64
    criteria::C where C <: expandCriteria
end

struct VisitedNodeCriteria <: expandCriteria end

function (criteria::VisitedNodeCriteria)(model::CPModel, limit::Int64)::Bool
    return model.statistics.numberOfNodesBeforeRestart <= limit
end

struct InfeasibleNodeCriteria <: expandCriteria end 

function (criteria::InfeasibleNodeCriteria)(model::CPModel, limit::Int64)::Bool
    return model.statistics.numberOfInfeasibleSolutionsBeforeRestart <= limit
end

struct SolutionFoundCriteria <: expandCriteria end 

function (criteria::SolutionFoundCriteria)(model::CPModel, limit::Int64)::Bool
    return model.statistics.numberOfSolutionsBeforeRestart <= limit
end
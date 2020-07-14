using LightGraphs

const Solution = Dict{String, Int}

mutable struct Statistics
    numberOfNodes       ::Int
    numberOfSolutions   ::Int
end

mutable struct Limit
    numberOfNodes       ::Union{Int, Nothing}
    numberOfSolutions   ::Union{Int, Nothing}
end

mutable struct CPModel
    variables               ::Dict{String, AbstractIntVar}
    constraints             ::Array{Constraint}
    trailer                 ::Trailer
    objective               ::Union{Nothing, AbstractIntVar}
    objectiveBound          ::Union{Nothing, Int}
    solutions               ::Array{Solution}
    statistics              ::Statistics
    limit                   ::Limit
    RLRep                   ::Union{Nothing, LightGraphs.AbstractGraph{Int}}
    CPModel(trailer) = new(Dict{String, AbstractIntVar}(), Constraint[], trailer, nothing, nothing, Solution[], Statistics(0, 0), Limit(nothing, nothing), nothing)
end

CPModel() = CPModel(Trailer())

const CPModification = Dict{String, Array{Int}}

"""
    addVariable!(model::CPModel, x::AbstractIntVar)

Add a variable to the model, throwing an error if `x`'s id is already in the model.
"""
function addVariable!(model::CPModel, x::AbstractIntVar)
    # Ensure the id is unique
    @assert !haskey(model.variables, x.id)

    model.variables[x.id] = x
end

"""
    merge!(prunedDomains::CPModification, newPrunedDomains::CPModification)

Merge `newPrunedDomains` into `prunedDomains`, concatenating the arrays if concerning the same variable.
"""
function merge!(prunedDomains::CPModification, newPrunedDomains::CPModification)
    for k in keys(newPrunedDomains)
        if haskey(prunedDomains, k)
            prunedDomains[k] = vcat(prunedDomains[k], newPrunedDomains[k])
        else
            prunedDomains[k] = newPrunedDomains[k]
        end
    end
end

"""
    addToPrunedDomains!(prunedDomains::CPModification, x::IntVar, pruned::Array{Int})

Update the `CPModification` by adding the pruned integers.

# Arguments
- `prunedDomains::CPModification`: the `CPModification` you want to update.
- `x::IntVar`: the variable that had its domain pruned.
- `pruned::Array{Int}`: the pruned integers.
"""
function addToPrunedDomains!(prunedDomains::CPModification, x::AbstractIntVar, pruned::Array{Int})
    if isempty(pruned)
        return
    end
    if haskey(prunedDomains, x.id)
        prunedDomains[x.id] = vcat(prunedDomains[x.id], pruned)
    else
        prunedDomains[x.id] = pruned
    end
end

"""
    solutionFound(model::CPModel)

Return a boolean, checking whether a solution was found, i.e. every variable is bound.
"""
function solutionFound(model::CPModel)
    for (k, x) in model.variables
        if !isbound(x)
            return false
        end
    end
    return true
end

"""
    triggerFoundSolution!(model::CPModel)

Add the current solution to `model`, and set new constraints for the objective if needed.
"""
function triggerFoundSolution!(model::CPModel)
    @assert solutionFound(model)

    model.statistics.numberOfSolutions += 1

    # Adding the solution
    solution = Solution()
    for (k, x) in model.variables
        solution[k] = assignedValue(x)
    end
    push!(model.solutions, solution)

    if !isnothing(model.objective)
        # println("Solution found! Current objective: ", assignedValue(model.objective))
        tightenObjective!(model)
    end
end

"""
    tightenObjective!(model::CPModel)

Set a new constraint to minimize the objective variable
"""
function tightenObjective!(model::CPModel)
    model.objectiveBound = assignedValue(model.objective)-1
end

"""
    belowLimits(model::CPModel)

Check if `model`' statistics are still under the limits.
"""
belowLimits(model::CPModel) = belowNodeLimit(model) && belowSolutionLimit(model)
belowNodeLimit(model::CPModel) = isnothing(model.limit.numberOfNodes) || model.statistics.numberOfNodes < model.limit.numberOfNodes
belowSolutionLimit(model::CPModel) = isnothing(model.limit.numberOfSolutions) || model.statistics.numberOfSolutions < model.limit.numberOfSolutions

"""
    Base.isempty(model::CPModel)::Bool

Return a boolean describing if the model is empty or not.
"""
function Base.isempty(model::CPModel)::Bool
    (
        isempty(model.variables) 
        && isempty(model.constraints) 
        && isempty(model.trailer.prior) 
        && isempty(model.trailer.current) 
        && isnothing(model.objective)
        && isnothing(model.objectiveBound)
        && isempty(model.solutions)
        && model.statistics.numberOfNodes == 0
        && model.statistics.numberOfSolutions == 0
        && isnothing(model.limit.numberOfNodes)
        && isnothing(model.limit.numberOfSolutions)
        && isnothing(model.RLRep)
    )
end

"""
    Base.empty!(model::CPModel)

Empty the CPModel.
"""
function Base.empty!(model::CPModel)
    empty!(model.variables) 
    empty!(model.constraints) 
    empty!(model.trailer.prior) 
    empty!(model.trailer.current) 
    model.objective = nothing
    model.objectiveBound = nothing
    empty!(model.solutions)
    model.statistics.numberOfNodes = 0
    model.statistics.numberOfSolutions = 0
    model.limit.numberOfNodes = nothing
    model.limit.numberOfSolutions = nothing
    model.RLRep = nothing
    model
end

function reset_model!(model::CPModel)
    restoreInitialState!(model.trailer)
    for (id, x) in model.variables
        reset_domain!(x.domain)
    end
    model.objectiveBound = nothing
    empty!(model.solutions)
    model.statistics.numberOfNodes = 0
    model.statistics.numberOfSolutions = 0
    model.RLRep = nothing
    model
end

"""
    domains_cartesian_product(model::CPModel)

Return the cartesian product of the model variables: |D1|x|D2|x ... x|Dn|
Helps providing insights about what is happening during a search.
"""
function domains_cartesian_product(model::CPModel)
    cart_pdt = 1
    for (id, x) in model.variables
        cart_pdt *= length(x.domain)
    end
    return cart_pdt
end

"""
    nb_boundvariables(model::CPModel)

Return the number of variables that have already been assigned to a value.
Helps providing insights about what is happening during a search.
"""
function nb_boundvariables(model::CPModel)
    nb = 0
    for (id, x) in model.variables
        nb += isbound(x) * 1
    end
    return nb
end
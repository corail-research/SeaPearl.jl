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
    variables       ::Dict{String, AbstractIntVar}
    constraints     ::Array{Constraint}
    trailer         ::Trailer
    objective       ::Union{Nothing, AbstractIntVar}
    solutions       ::Array{Solution}
    statistics      ::Statistics
    limit           ::Limit
    CPModel(trailer) = new(Dict{String, AbstractIntVar}(), Constraint[], trailer, nothing, Solution[], Statistics(0, 0), Limit(nothing, nothing))
end

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
        println("Solution found! Current objective: ", assignedValue(model.objective))
        tightenObjective!(model)
    end
end

"""
    tightenObjective!(model::CPModel)

Set a new constraint to minimize the objective variable
"""
function tightenObjective!(model::CPModel)
    @assert !isnothing(model.objective)

    tighten = LessOrEqualConstant(model.objective, assignedValue(model.objective)-1, model.trailer)
    push!(model.constraints, tighten)
end

"""
    belowLimits(model::CPModel)

Check if `model`' statistics are still under the limits.
"""
function belowLimits(model::CPModel)
    if !isnothing(model.limit.numberOfNodes) && model.statistics.numberOfNodes >= model.limit.numberOfNodes
        return false
    end
    if !isnothing(model.limit.numberOfSolutions) && model.statistics.numberOfSolutions >= model.limit.numberOfSolutions
        return false
    end
    return true
end
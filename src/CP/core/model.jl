struct CPModel
    variables       ::Dict{String, IntVar}
    constraints     ::Array{Constraint}
    trailer         ::Trailer
    CPModel(trailer) = new(Dict{String, IntVar}(), Constraint[], trailer)
end

const CPModification = Dict{String, Array{Int}}

"""
    addVariable!(model::CPModel, x::IntVar)

Add a variable to the model, throwing an error if `x`'s id is already in the model.
"""
function addVariable!(model::CPModel, x::IntVar)
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
function addToPrunedDomains!(prunedDomains::CPModification, x::IntVar, pruned::Array{Int})
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
struct CPModel
    variables       ::Dict{String, IntVar}
    constraints     ::Array{Constraint}
    CPModel() = new(Dict{String, IntVar}(), Constraint[])
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

function merge!(prunedDomains::CPModification, newPrunedDomains::CPModification)
    for k in keys(newPrunedDomains)
        if haskey(prunedDomains, k)
            prunedDomains[k] = vcat(prunedDomains[k], newPrunedDomains[k])
        else
            prunedDomains[k] = newPrunedDomains[k]
        end
    end
end
const CPModification = Dict{String, Union{Array{Int}, Array{Bool}, SetModification}}

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

function updateChildren!(prunedDomains::CPModification, x::Union{IntVar, BoolVar}, pruned::Union{Array{Int}, Array{Bool}, BitArray})
    for y in x.children
        childrenPruned = childrenValue.([y], pruned)
        if haskey(prunedDomains, y.id)
            append!(prunedDomains[y.id], Array(childrenPruned))
        else
            prunedDomains[y.id] = Array(childrenPruned)
        end
    end
    return
end


"""
    addToPrunedDomains!(prunedDomains::CPModification, x::IntVar, pruned::Array{Int})

Update the `CPModification` by adding the pruned integers.

# Arguments
- `prunedDomains::CPModification`: the `CPModification` you want to update.
- `x::IntVar`: the variable that had its domain pruned.
- `pruned::Array{Int}`: the pruned integers.
"""
function addToPrunedDomains!(prunedDomains::CPModification, x::Union{IntVar, BoolVar}, pruned::Union{Array{Int}, Array{Bool}, BitArray})
    if isempty(pruned)
        return
    end
    if haskey(prunedDomains, x.id)
        prunedDomains[x.id] = append!(prunedDomains[x.id], Array(pruned)) 
    else
        prunedDomains[x.id] = Array(pruned)
    end
    updateChildren!(prunedDomains, x, pruned)
end

"""
    addToPrunedDomains!(prunedDomains::CPModification, x::IntVar, pruned::Array{Int})

Update the `CPModification` by adding the pruned integers.

# Arguments
- `prunedDomains::CPModification`: the `CPModification` you want to update.
- `x::IntVar`: the variable that had its domain pruned.
- `pruned::Array{Int}`: the pruned integers.
"""
function addToPrunedDomains!(prunedDomains::CPModification, x::Union{IntVarView, BoolVarView}, pruned::Union{Array{Int}, Array{Bool}, BitArray})
    if isempty(pruned)
        return
    end
    # Update the ParentVariable only (it will then update all the children variables)
    parentPruned = parentValue.([x], pruned)
    addToPrunedDomains!(prunedDomains, x.x, parentPruned)
end

"""
    addToPrunedDomains!(prunedDomains::CPModification, x::IntVar, pruned::Array{Int})

Update the `CPModification` by adding modified set values.

# Arguments
- `prunedDomains::CPModification`: the `CPModification` you want to update.
- `x::IntSetVar`: the variable that had its values changed.
- `modification::SetModification`: the modified values.
"""
function addToPrunedDomains!(prunedDomains::CPModification, x::IntSetVar, modification::SetModification)
    if isempty(modification.required) && isempty(modification.excluded)
        return
    end

    if haskey(prunedDomains, x.id)
        mergeSetModifications!(prunedDomains[x.id], modification)
    else
        prunedDomains[x.id] = modification
    end
    return
end

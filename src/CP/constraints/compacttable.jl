include("algorithms/rsparsebitset.jl")

"""
    TableConstraint

Constraint enforcing that: ∃ j ∈ ⟦1,m⟧, such that ∀ i ∈ ⟦1,n⟧ xᵢ=table[i,j].

The datastructure and the functions using it are inspired by: 
Demeulenaere J. et al. (2016) Compact-Table: Efficiently Filtering Table Constraints with Reversible Sparse Bit-Sets. 
In: Rueher M. (eds) Principles and Practice of Constraint Programming. CP 2016. Lecture Notes in Computer Science, vol 9892. Springer, Cham. 
https://doi.org/10.1007/978-3-319-44953-1_14

# Arguments
- `scope::Vector{<:AbstractIntVar}`: the ordered variables present in the table.
- `table::Matrix{Int}`: the original table describing the constraint (impossible assignment are filtered). 
- `currentTable::RSparseBitSet{UInt64}`: the reversible representation of the table.
- `modifiedVariables::Vector{Int}`: vector with the indexes of the variables modified since the last propagation.
- `lastSizes::Vector{Int}`: vector with the size of the domains during the last propagation.
- `unfixedVariables::Vector{Int}`: vector with the indexes of the variables binding.
- `supports::Dict{Pair{Int,Int},BitVector}`: dictionnary which, for each pair (variable => value), gives the support of this pair.
- `residues::Dict{Pair{Int,Int},Int}`: dictionnary which, for each pair (variable => value), gives the residue of this pair.
"""
struct TableConstraint <: Constraint
    scope::Vector{<:AbstractIntVar}
    table::Matrix{Int}
    currentTable::RSparseBitSet{UInt64}
    modifiedVariables::Vector{Int}
    lastSizes::Vector{Int}
    unfixedVariables::Vector{Int}
    supports::Dict{Pair{Int,Int},BitVector}
    residues::Dict{Pair{Int,Int},Int}
end

"""
    TableConstraint(variables, table, trailer)

Create a CompactTable constraint from the `variables`, with values given in `table`.

Efficient implentation of the constraint enforcing: ∃ j ∈ ⟦1,m⟧, such that ∀ i ∈ ⟦1,n⟧ xᵢ=table[i,j].

# Arguments
- `variables::Vector{<:AbstractIntVar}`: vector of variables of size (n, ).
- `table::Matrix{Int}`: matrix of the constraint of size (n, m).
- `trailer::Trailer`: the trailer of the model.
"""
function TableConstraint(variables::Vector{<:AbstractIntVar}, table::Matrix{Int}, trailer)
    @assert length(variables) == size(table, 1)
    cleanedTable = cleanTable(variables, table)

    nVariables, nTuples = size(cleanedTable)
    currentTable = RSparseBitSet{UInt64}(nTuples, trailer)
    modifiedVariables = Int[]
    lastSizes = [length(variable.domain) for variable in variables]
    unfixedVariables = collect(1:nVariables)

    supports = buildSupport(variables, cleanedTable)
    cleanSupports!(supports, variables)

    residues = buildResidues(variables, supports)
    return TableConstraint(
        variables,
        cleanedTable, 
        currentTable,
        modifiedVariables,
        lastSizes,
        unfixedVariables,
        supports,
        residues
    )
end

"""
    bitVectorToUInt64Vector(bitset)::Vector{UInt64}

Convert a Julia BitVector to a vector preformatted for the RSparseBitSet{UInt64}.

# Arguments
- `bitset::BitVector`: the BitVector to convert.
"""
function bitVectorToUInt64Vector(bitset::BitVector)::Vector{UInt64} 
    return [bitreverse(chunk) for chunk in bitset.chunks]
end

"""
    cleanTable(variables, table)::Matrix{Int}

Return a table without the columns corresponding to impossible assignments.

# Arguments
- `variables::Vector{<:AbstractIntVar}`: the variables of the constraint.
- `table::Matrix{Int}`: the table of the constraint.
"""
function cleanTable(variables::Vector{<:AbstractIntVar}, table::Matrix{Int})::Matrix{Int}
    tuplesToDrop = Set{Int}()
    for (idx, col) in enumerate(eachcol(table))
        isValid = all([value in variable.domain for (variable, value) in zip(variables, col)])
        if !isValid
            push!(tuplesToDrop, idx)
        end
    end
    return table[:, setdiff(1:size(table, 2), tuplesToDrop)]
end

"""
    buildSupport(variables, table)::Dict{Pair{Int,Int},BitVector}

Return the support dictionnary, giving for each pair wich columns of the table uses it.

# Arguments
- `variables::Vector{<:AbstractIntVar}`: the variables of the constraint.
- `table::Matrix{Int}`: the table of the constraint.
"""
function buildSupport(variables::Vector{<:AbstractIntVar}, table::Matrix{Int})::Dict{Pair{Int,Int},BitVector}
    nVariables, nTuples = size(table)

    support = Dict{Pair{Int,Int},BitVector}()
    for (idx, var) in enumerate(variables), a in var.domain
        support[idx => a] = BitVector(fill(false, nTuples))
    end

    for (idx, col) in enumerate(eachcol(table)), (variable, value) in enumerate(col)
        support[variable => value][idx] = true
    end

    return support
end

"""
    cleanSupports!(supports, variables)

Remove the pair (variable => value) from `supports` and from the variables domain, when they aren't present in the table.

# Arguments
- `supports::Dict{Pair{Int,Int},BitVector}`: the previously generated supports of the constraint.
- `variables::Vector{<:AbstractIntVar}`: the variables of the constraint.
"""
function cleanSupports!(supports::Dict{Pair{Int,Int},BitVector}, variables::Vector{<:AbstractIntVar})::Nothing
    for ((variable, value), support) in supports
        if !any(support)
            delete!(supports, variable => value)
            remove!(variables[variable].domain, value)
        end
    end
    return
end

"""
    buildResidues(variables, supports)::Dict{Pair{Int,Int},Int}

Return the residues from the variables and the cleaned supports.

# Arguments
- `variables::Vector{<:AbstractIntVar}`: the variables of the constraint.
- `supports::Dict{Pair{Int,Int},BitVector}`: the previously generated supports of the constraint.
"""
function buildResidues(variables::Vector{<:AbstractIntVar}, supports::Dict{Pair{Int,Int},BitVector})::Dict{Pair{Int,Int},Int}
    residues = Dict{Pair{Int,Int},Int}()
    n = 64
    for (key, support) in supports
        residues[key] = Int(ceil(findfirst(support)/n))
    end
    return residues
end

"""
    updateTable!(constraint)

Remove the outdated columns from the reversible table of the constraint.

This function is directly inspired by Demeulenaere J. et al. paper.
"""
function updateTable!(constraint::TableConstraint)::Bool
    for variable in constraint.modifiedVariables
        clearMask!(constraint.currentTable)
        for value in variable.domain
            support = bitVectorToUInt64Vector(constraint.supports[variable => value])
            addToMask!(constraint.currentTable, support)
        end
        intersectWithMask!(constraint.currentTable)
        if isempty(constraint.currentTable)
            return false
        end
    end
    return true
end

"""
    pruneDomains!(constraint)::Vector{Vector{Int}}

Remove the impossible values from the variables domain and return all the updates.

This function is directly inspired by Demeulenaere J. et al. paper.
"""
function pruneDomains!(constraint::TableConstraint)::Vector{Vector{Int}}
    prunedValues = Vector{Vector{Int}}(undef, length(constraint.scope))
    for i = 1:constraint.numberOfVars
        prunedValues[i] = Int[]
    end

    for variable in constraint.unfixedVariables, value in variable.domain
        index = constraint.residues[variable => value]
        support = bitVectorToUInt64Vector(constraint.supports[variable => value])
        if constraint.currentTable.words[index].value & support[index] == UInt64(0)
            index = intersectIndex(constraint.currentTable, support)
            if index != -1
                constraint.residues[variable => value] = index
            else
                remove!(constraint.scope[variable].domain, value)
                push!(prunedValues[variable], value)
            end
        end
        constraint.lastSizes[variable] = length(constraint.scope[variable].domain)
    end
    return prunedValues
end

"""
    propagate!(constraint, toPropagate::Set{Constraint}, prunedDomains::CPModification)

`TableConstraint` propagation function. Implement the full procedure of the paper.
"""
function propagate!(constraint::TableConstraint, toPropagate::Set{Constraint}, prunedDomains::CPModification)
    if !constraint.active.value
        return true
    end

    constraint.modifiedVariables = findall((var, len) -> length(var.domain) != len, zip(constraint.scope, constraint.lastSizes))
    for (idx, variable) in enumerate(constraint.scope)
        constraint.lastSizes[idx] = length(variable.domain)
    end

    constraint.unfixedVariables = findall(var -> length(var.domain) > 1, constraint.scope)

    if !updateTable!(constraint)
        return false
    end

    prunedValues = pruneDomains!(constraint)
    for (prunedVar, var) in zip(prunedValues, constraint.scope)
        if !isempty(prunedVar)
            for val in prunedVar
                remove!(var.domain, val)
            end
            triggerDomainChange!(toPropagate, var)
            addToPrunedDomains!(prunedDomains, var, prunedVar)
        end
    end

    if constraint in toPropagate
        pop!(toPropagate, constraint)
    end

    return true
end
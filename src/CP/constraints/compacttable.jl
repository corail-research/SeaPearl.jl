include("algorithms/rsparsebitset.jl")

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

function bitVectorToUInt64Vector(bitset::BitVector)::Vector{UInt64} 
    return [bitreverse(chunk) for chunk in bitset.chunks]
end

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

function cleanSupports!(supports::Dict{Pair{Int,Int},BitVector}, variables::Vector{<:AbstractIntVar})::Nothing
    for ((variable, value), support) in supports
        if !any(support)
            delete!(supports, variable => value)
            remove!(variables[variable].domain, value)
        end
    end
    return
end

function buildResidues(variables::Vector{<:AbstractIntVar}, supports::Dict{Pair{Int,Int},BitVector})::Dict{Pair{Int,Int},Int}
    residues = Dict{Pair{Int,Int},Int}()
    for (key, support) in supports
        residues[key] = findfirst(support)
    end
    return residues
end

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

function pruneDomains!(constraint::TableConstraint)::Vector{Vector{Int}}
    prunedValues = Vector{Vector{Int}}(undef, length(constraint.scope))
    for i = 1:constraint.numberOfVars
        prunedValues[i] = Int[]
    end

    for variable in constraint.unfixedVariables, value in variable.domain
        index = constraint.residues[variable => value]
        support = bitVectorToUInt64Vector(constraint.supports[variable => value])
        if constraint.currentTable.words[index] & support[index] == UInt64(0)
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
    for (prunedVar, var) in zip(prunedValues, constraint.x)
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
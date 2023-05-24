using SeaPearl

"""
    NegativeTableConstraint

Efficient implentation of the constraint enforcing: ∀ j ∈ ⟦1,m⟧, such that ∀ i ∈ ⟦1,n⟧ xᵢ!=table[i,j].

The datastructure and the functions using it are inspired by:
- Demeulenaere J. et al. (2016) Compact-Table: Efficiently Filtering Table Constraints with Reversible Sparse Bit-Sets.
In: Rueher M. (eds) Principles and Practice of Constraint Programming. CP 2016. Lecture Notes in Computer Science, vol 9892. Springer, Cham.
https://doi.org/10.1007/978-3-319-44953-1_14

- Hélène Verhaeghe and Christophe Lecoutre and Pierre Schaus : Extending Compact-Table to Negative and Short Tables


    NegativeTableConstraint(scope, active, table, currentTable, modifiedVariables, unfixedVariables, supports, residues)

NegativeTableConstraint default constructor.

# Arguments
- `scope::Vector{<:AbstractIntVar}`: the ordered variables present in the table.
- `table::Matrix{Int}`: the original table describing the constraint (impossible assignment are filtered).
- `currentTable::RSparseBitSet{UInt64}`: the reversible representation of the table.
- `modifiedVariables::Vector{Int}`: vector with the indexes of the variables modified since the last propagation.
- `unfixedVariables::Vector{Int}`: vector with the indexes of the variables which are not binding.
- `conflicts::Dict{Pair{Int,Int},BitVector}`: dictionnary which, for each pair (variable => value), gives the support of this pair.
- `residues::Dict{Pair{Int,Int},Int}`: dictionnary which, for each pair (variable => value), gives the residue of this pair.


    NegativeTableConstraint(variables, table, conflicts, trailer)

Create a CompactNegativeTable constraint from the `variables`, with impossible values given in `table` and conflicts given in `conflicts`.

This constructor gives full control on both `table` and `conflicts`. The attributes are not duplicated and remains
linked to the variables given to the constructor. It should be used only to avoid duplication of `table` when using
the same table constraint many times with different variables. *WARNING*: all variables must have the same domain;
`table` and `conflicts` must be cleaned.

# Arguments
- `variables::Vector{<:AbstractIntVar}`: vector of variables of size (n, ).
- `table::Matrix{Int}`: matrix of the constraint of size (n, m).
- `conflicts::Dict{Pair{Int,Int},BitVector}`: for each assignment, a list of the tuples supporting this assignment.
- `trailer::Trailer`: the trailer of the model.
"""
struct NegativeTableConstraint <: SeaPearl.Constraint
    scope::Vector{<:AbstractIntVar}
    active::StateObject{Bool}
    initialized::StateObject{Bool}
    table::Matrix{Int}
    currentTable::RSparseBitSet{UInt64}
    modifiedVariables::Set{Int}
    unfixedVariables::Set{Int}
    conflicts::Dict{Pair{Int,Int},BitVector}
    residues::Dict{Pair{Int,Int},Int}

    NegativeTableConstraint(scope, active, initialized, table, currentTable, modifiedVariables, unfixedVariables, conflicts, residues) = new(scope, active, initialized, table, currentTable, modifiedVariables, unfixedVariables, conflicts, residues)

    function NegativeTableConstraint(variables::Vector{<:AbstractIntVar}, table::Matrix{Int}, conflicts::Dict{Pair{Int,Int},BitVector}, trailer)
        @assert length(variables) == size(table, 1)

        nVariables, nTuples = size(table)

        constraint = new(
            variables,
            StateObject{Bool}(true, trailer),
            StateObject{Bool}(false, trailer),
            table,
            RSparseBitSet{UInt64}(nTuples, trailer),
            Set{Int}(),
            Set(collect(1:nVariables)),
            conflicts,
            buildResidues(conflicts)
        )

        for variable in variables
            addOnDomainChange!(variable, constraint)
        end

        return constraint
    end

end

"""
    NegativeTableConstraint(variables::Vector{<:AbstractIntVar}, table::Matrix{Int}, trailer::SeaPearl.Trailer)

Create a CompactNegativeTable constraint from the `variables`, with values given in `table`.

This is the recommended constructor, as it safely builds the constraint and isolates it. If you choose any of the 2 other constructor,
beware how you create your attributes, and be sure not to modify them at any time.

# Arguments
- `variables::Vector{<:AbstractIntVar}`: vector of variables of size (n, ).
- `table::Matrix{Int}`: matrix of the constraint of size (n, m).
- `trailer::Trailer`: the trailer of the model.
"""
function NegativeTableConstraint(variables::Vector{<:AbstractIntVar}, table::Matrix{Int}, trailer)
    @assert length(variables) == size(table, 1)
    cleanedTable = cleanTable(variables, table)

    active = StateObject{Bool}(true, trailer)
    initialized = StateObject{Bool}(false, trailer)
    nVariables, nTuples = size(cleanedTable)
    currentTable = RSparseBitSet{UInt64}(nTuples, trailer)
    modifiedVariables = Set{Int}()
    unfixedVariables = Set(collect(1:nVariables))

    conflicts = buildConflict(variables, cleanedTable)
    cleanConflicts!(conflicts, variables)

    residues = buildResidues(conflicts)
    constraint = NegativeTableConstraint(
        variables,
        active,
        initialized,
        cleanedTable,
        currentTable,
        modifiedVariables,
        unfixedVariables,
        conflicts,
        residues
    )

    for variable in variables
        addOnDomainChange!(variable, constraint)
    end

    return constraint
end

"""
    cleanNegativeTable(variables, table)::Matrix{Int}

Return a table without the columns corresponding to impossible assignments.

# Arguments
- `variables::Vector{<:AbstractIntVar}`: the variables of the constraint.
- `table::Matrix{Int}`: the table of the constraint.
"""
function cleanNegativeTable(variables::Vector{<:AbstractIntVar}, table::Matrix{Int})::Matrix{Int}
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
    buildConflict(variables, table)::Dict{Pair{Int,Int},BitVector}

Return the conflict dictionnary, giving for each pair wich columns of the table uses it.

# Arguments
- `variables::Vector{<:AbstractIntVar}`: the variables of the constraint.
- `table::Matrix{Int}`: the table of the constraint.
"""
function buildConflict(variables::Vector{<:AbstractIntVar}, table::Matrix{Int})::Dict{Pair{Int,Int},BitVector}
    nVariables, nTuples = size(table)

    conflict = Dict{Pair{Int,Int},BitVector}()
    for (idx, var) in enumerate(variables), a in var.domain
        conflict[idx => a] = BitVector(fill(false, nTuples))
    end

    for (idx, col) in enumerate(eachcol(table)), (variable, value) in enumerate(col)
        conflict[variable => value][idx] = true
    end
    return conflict
end

"""
    cleanConflicts!(conflicts, variables)

Remove the pair (variable => value) from `conflicts` and from the variables domain, when they aren't present in the table.

# Arguments
- `conflicts::Dict{Pair{Int,Int},BitVector}`: the previously generated conflicts of the constraint.
- `variables::Vector{<:AbstractIntVar}`: the variables of the constraint.
"""
function cleanConflicts!(conflicts::Dict{Pair{Int,Int},BitVector}, variables::Vector{<:AbstractIntVar})::Nothing
    for ((variable, value), conflict) in conflicts
        if !any(conflict)
            delete!(conflicts, variable => value)
        end
    end
    return
end

"""
    buildResidues(variables, conflicts)::Dict{Pair{Int,Int},Int}

Return the residues from the variables and the cleaned conflicts.

# Arguments
- `variables::Vector{<:AbstractIntVar}`: the variables of the constraint.
- `conflicts::Dict{Pair{Int,Int},BitVector}`: the previously generated conflicts of the constraint.
"""
function buildResidues(conflicts::Dict{Pair{Int,Int},BitVector})::Dict{Pair{Int,Int},Int}
    residues = Dict{Pair{Int,Int},Int}()
    n = 64
    for (key, conflict) in conflicts
        residues[key] = Int(ceil(findfirst(conflict)/n))
    end
    return residues
end

"""
    updateNegativeTable!(constraint, prunedValues)

Remove the outdated columns from the reversible table of the constraint.

This function is directly inspired by Hélène Verhaeghe and Christophe Lecoutre and Pierre Schaus paper.
"""
function updateNegativeTable!(constraint::NegativeTableConstraint, prunedValues::Vector{Vector{Int}})::Bool
    for variable in constraint.modifiedVariables
        clearMask!(constraint.currentTable)
        if length(prunedValues[variable]) < length(constraint.scope[variable].domain)
            for value in prunedValues[variable]
                conflict = bitVectorToUInt64Vector(constraint.conflicts[variable => value])
                addToMask!(constraint.currentTable, conflict)
            end
            reverseMask!(constraint.currentTable)
        else
            for value in constraint.scope[variable].domain
                if haskey(constraint.conflicts, variable => value)
                    conflict = bitVectorToUInt64Vector(constraint.conflicts[variable => value])
                    addToMask!(constraint.currentTable, conflict)
                end
            end
        end
        intersectWithMask!(constraint.currentTable)
        if isempty(constraint.currentTable)
            return false
        end
    end
    return true
end

"""
    pruneDomains!(constraint, prunedValues)

Remove the impossible values from the variables domain update prunedValues.

This function is directly inspired by Hélène Verhaeghe and Christophe Lecoutre and Pierre Schaus paper
"""
function pruneDomains!(constraint::NegativeTableConstraint)::Vector{Vector{Int}}
    prunedValues = Vector{Vector{Int}}(undef, length(constraint.scope))
    for i = 1:length(constraint.scope)
        prunedValues[i] = Int[]
    end

    cardinalProduct = getCardinalProduct(constraint)
    
    for variable in constraint.unfixedVariables

        tempDomainSize = constraint.scope[variable].domain.size.value

        for value in constraint.scope[variable].domain
            
            if haskey(constraint.conflicts, variable => value)
                
                conflict = bitVectorToUInt64Vector(constraint.conflicts[variable => value])
                
                cnt = 0
                for (i, word) in enumerate(constraint.currentTable.words)
                    cnt += count_ones(word.value & conflict[i])
                end
                
                if cnt == cardinalProduct / tempDomainSize
                    push!(prunedValues[variable], value)
                    clearMask!(constraint.currentTable)
                    addToMask!(constraint.currentTable, conflict)
                    reverseMask!(constraint.currentTable)
                    intersectWithMask!(constraint.currentTable)

                    cardinalProduct /= tempDomainSize
                    tempDomainSize -= 1
                    cardinalProduct *= tempDomainSize
                end
            end
        end
    end
    return prunedValues
end

function getCardinalProduct(constraint::NegativeTableConstraint)
    cardinalProduct = 1
    for variable in constraint.scope
        cardinalProduct *= variable.domain.size.value
    end
    return cardinalProduct
end

"""
    propagate!(constraint::NegativeTableConstraint, toPropagate::Set{Constraint}, prunedDomains::CPModification)

`NegativeTableConstraint` propagation function. Implement the full procedure of the paper.
"""
function propagate!(constraint::NegativeTableConstraint, toPropagate::Set{Constraint}, prunedDomains::CPModification)
    if !constraint.active.value
        return true
    end

    # Store all the changes concerning the variables in `constraint.scope`
    prunedValues = Vector{Vector{Int}}(undef, length(constraint.scope))
    empty!(constraint.modifiedVariables)
    for (idx, variable) in enumerate(constraint.scope)
        if haskey(prunedDomains, variable.id)
            push!(constraint.modifiedVariables, idx)
            prunedValues[idx] = copy(prunedDomains[variable.id])
        end
    end
            
    # Sometime an assignment has already been pruned before the initialization eventhough  
    # it doesn't have a conflict .In that case it shouldn't be used to update the table.
    for variable in constraint.modifiedVariables
        filter!(prunedValues[variable]) do value
            haskey(constraint.conflicts, variable => value)
        end
    end

    # Update unfixed variables
    empty!(constraint.unfixedVariables)
    union!(constraint.unfixedVariables, findall(var -> length(var.domain) > 1, constraint.scope))

    # Remove impossible conflicts from the table
    if !updateNegativeTable!(constraint, prunedValues)
        return false
    end

    # Restrict domains to the new supports
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

function Base.show(io::IO, ::MIME"text/plain", con::NegativeTableConstraint)
    table = split(repr("text/plain", con.table), '\n')[2:end]
    maxlen = Base.maximum(x -> length(x.id), con.scope)

    println(io, string(typeof(con)), ": active = ", con.active)
    for i = 1:length(con.scope)
        println(io, "   ", rpad(con.scope[i].id, maxlen),"  not in  ", table[i])
    end
    print(io, "\n   With domains:")
    for var in con.scope
        print(io, "\n      ", var)
    end
end

function Base.show(io::IO, con::NegativeTableConstraint)
    print(io, string(typeof(con)), ": (", join([x.id for x in con.scope], ", "), ") not in ", con.table, ", active = ", con.active)
end

variablesArray(constraint::NegativeTableConstraint) = constraint.scope
